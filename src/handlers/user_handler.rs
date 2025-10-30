use crate::models::{Role, User};
use crate::repositories::UserRepository;
use crate::utils::auth::create_jwt;
use actix_web::{HttpResponse, web};
use bcrypt::{DEFAULT_COST, hash, verify};
use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use sqlx::MySqlPool;

// =====================================================
// REQUEST/RESPONSE MODELS
// =====================================================

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub first_name: String,
    pub last_name: String,
    pub gender: String,             // "Male", "Female", "Other"
    pub birth_date: Option<String>, // Format: "YYYY-MM-DD"
    pub country: Option<String>,
    pub city: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub token: String,
    pub user_id: u32,
    pub email: String,
    pub role: Role,
}

#[derive(Debug, Serialize)]
pub struct ProfileResponse {
    pub user_id: u32,
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub role: Role,
    pub gender: String,
    pub birth_date: Option<NaiveDate>,
    pub country: Option<String>,
    pub city: Option<String>,
    pub created_at: String,
}

// =====================================================
// HANDLERS
// =====================================================

pub async fn login(pool: web::Data<MySqlPool>, req: web::Json<LoginRequest>) -> HttpResponse {
    let user_repo = UserRepository::new(pool.get_ref().clone());

    match user_repo.find_by_email(&req.email).await {
        Ok(Some(user)) => {
            return handle_login(&user, &req.password).await;
        }
        Err(e) => {
            log::error!("Database error querying users: {:?}", e);
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Internal server error"
            }));
        }
        Ok(None) => {}
    }

    HttpResponse::Unauthorized().json(serde_json::json!({
        "error": "Invalid credentials"
    }))
}

async fn handle_login(user: &User, password: &str) -> HttpResponse {
    // Vérifier si l'utilisateur est actif
    if !user.is_active {
        return HttpResponse::Forbidden().json(serde_json::json!({
            "error": "Account is inactive"
        }));
    }

    // Cas spécial : mot de passe vide (pour développement uniquement)
    if user.password_hash.is_empty() {
        log::warn!(
            "User {} logged in without password verification (empty hash)",
            user.email
        );
        return generate_token_response(user);
    }

    // Vérification normale du mot de passe
    match verify(password, &user.password_hash) {
        Ok(valid) => {
            if valid {
                generate_token_response(user)
            } else {
                HttpResponse::Unauthorized().json(serde_json::json!({
                    "error": "Invalid credentials"
                }))
            }
        }
        Err(e) => {
            log::error!("Failed to verify password: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to verify password"
            }))
        }
    }
}

fn generate_token_response(user: &User) -> HttpResponse {
    let secret = std::env::var("JWT_SECRET").expect("JWT_SECRET must be set");
    let expiration = std::env::var("JWT_EXPIRATION")
        .unwrap_or_else(|_| "3600".to_string())
        .parse::<i64>()
        .expect("JWT_EXPIRATION must be a valid number");

    match create_jwt(user, &secret, expiration) {
        Ok(token) => HttpResponse::Ok().json(AuthResponse {
            token,
            user_id: user.user_id,
            email: user.email.clone(),
            role: user.role.clone(),
        }),
        Err(e) => {
            log::error!("Failed to create token: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to create token"
            }))
        }
    }
}

pub async fn register(pool: web::Data<MySqlPool>, req: web::Json<RegisterRequest>) -> HttpResponse {
    let user_repo = UserRepository::new(pool.get_ref().clone());

    // Hasher le mot de passe
    let password_hash = match hash(&req.password, DEFAULT_COST) {
        Ok(h) => h,
        Err(e) => {
            log::error!("Failed to hash password: {:?}", e);
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to hash password"
            }));
        }
    };

    // Parser le genre
    let gender = match req.gender.as_str() {
        "Male" | "male" => "Male",
        "Female" | "female" => "Female",
        "Other" | "other" => "Other",
        _ => "Other",
    };

    // Parser la date de naissance
    let birth_date = req
        .birth_date
        .as_ref()
        .and_then(|date_str| NaiveDate::parse_from_str(date_str, "%Y-%m-%d").ok());

    // Créer l'utilisateur via la procédure stockée
    match user_repo
        .create(
            &req.first_name,
            &req.last_name,
            gender,
            &password_hash,
            &req.email,
            "Regular", // Role par défaut
            req.country.as_deref(),
            req.city.as_deref(),
            birth_date,
        )
        .await
    {
        Ok(user_id) => {
            // Récupérer l'utilisateur créé pour générer le token
            match user_repo.find_by_id(user_id).await {
                Ok(Some(user)) => generate_token_response(&user),
                Ok(None) => HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "User created but could not be retrieved"
                })),
                Err(e) => {
                    log::error!("Failed to retrieve created user: {:?}", e);
                    HttpResponse::InternalServerError().json(serde_json::json!({
                        "error": "User created but failed to generate token"
                    }))
                }
            }
        }
        Err(e) => {
            log::error!("Failed to create user: {:?}", e);

            // Vérifier si c'est une erreur de duplication d'email
            let error_msg = format!("{:?}", e);
            if error_msg.contains("Email already exists") || error_msg.contains("Duplicate") {
                HttpResponse::Conflict().json(serde_json::json!({
                    "error": "Email already exists"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to create user"
                }))
            }
        }
    }
}

/*pub async fn get_profile(
    pool: web::Data<MySqlPool>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let user_repo = UserRepository::new(pool.get_ref().clone());

    // Extraire l'user_id depuis les claims
    let user_id = match claims.user_id() {
        Ok(id) => id,
        Err(e) => {
            log::error!("Invalid user_id in token: {:?}", e);
            return HttpResponse::Unauthorized().json(serde_json::json!({
                "error": "Invalid token"
            }));
        }
    };

    match user_repo.find_by_id(user_id).await {
        Ok(Some(user)) => HttpResponse::Ok().json(ProfileResponse {
            user_id: user.user_id,
            first_name: user.first_name,
            last_name: user.last_name,
            email: user.email,
            role: user.role,
            gender: format!("{:?}", user.gender),
            birth_date: user.birth_date,
            country: user.country,
            city: user.city,
            created_at: user.created_at.format("%Y-%m-%d %H:%M:%S").to_string(),
        }),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "error": "User not found"
        })),
        Err(e) => {
            log::error!("Database error: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Internal server error"
            }))
        }
    }
}*/
