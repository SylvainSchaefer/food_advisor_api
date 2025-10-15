use actix_web::{web, HttpResponse};
use sqlx::MySqlPool;
use bcrypt::{hash, verify, DEFAULT_COST};
use crate::models::{Claims, LoginRequest, RegisterRequest, Role};
use crate::utils::create_jwt;
use crate::repositories::{UserRepository, AdminRepository};

pub async fn login(
    pool: web::Data<MySqlPool>,
    req: web::Json<LoginRequest>,
) -> HttpResponse {
    let user_repo = UserRepository::new(pool.get_ref().clone());

    match user_repo.find_by_email(&req.email).await {
        Ok(Some(user)) => {
            return handle_login(user.id, user.email, user.password_hash, &user.role, &req.password).await;
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

async fn handle_login(
    id: i32,
    email: String,
    password_hash: String,
    role: &Role,
    password: &str,
) -> HttpResponse {
    if password_hash.is_empty() {
        // Autoriser la connexion sans vérification de mot de passe
        log::warn!("User {} logged in without password verification (empty hash)", email);
        
        let secret = std::env::var("JWT_SECRET").unwrap();
        let expiration = std::env::var("JWT_EXPIRATION")
                                            .expect("JWT_EXPIRATION must be set")
                                            .parse::<i64>()
                                            .expect("JWT_EXPIRATION must be a valid number");
        
        match create_jwt(id, &email, role.clone(), &secret, expiration) {
            Ok(token) => {
                return HttpResponse::Ok().json(serde_json::json!({
                    "token": token,
                    "user_id": id,
                    "email": email,
                    "role": role
                }));
            }
            Err(_) => {
                return HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to create token"
                }));
            }
        }
    }
    
    match verify(password, &password_hash) {
        Ok(valid) => {
            if valid {
                let secret = std::env::var("JWT_SECRET").unwrap();
                let expiration = std::env::var("JWT_EXPIRATION")
                                            .expect("JWT_EXPIRATION must be set")
                                            .parse::<i64>()
                                            .expect("JWT_EXPIRATION must be a valid number");

                match create_jwt(id, &email, role.clone(), &secret, expiration) {
                    Ok(token) => HttpResponse::Ok().json(serde_json::json!({
                        "token": token,
                        "user_id": id,
                        "email": email,
                        "role": role
                    })),
                    Err(_) => HttpResponse::InternalServerError().json(serde_json::json!({
                        "error": "Failed to create token"
                    }))
                }
            }
            else {
                HttpResponse::Unauthorized().json(serde_json::json!({
                    "error": "Invalid credentials"
                }))
            }
        }
        Err(_) => HttpResponse::InternalServerError().json(serde_json::json!({
            "error": "Failed to verify password"
        }))
    }
}

pub async fn register(
    pool: web::Data<MySqlPool>,
    req: web::Json<RegisterRequest>,
) -> HttpResponse {
    let user_repo = UserRepository::new(pool.get_ref().clone());

    let password_hash = match hash(&req.password, DEFAULT_COST) {
        Ok(h) => h,
        Err(_) => return HttpResponse::InternalServerError().json(serde_json::json!({
            "error": "Failed to hash password"
        }))
    };

    match user_repo.create( &req.email, &password_hash, &req.first_name, &req.last_name).await {
        Ok(user_id) => {
            let secret = std::env::var("JWT_SECRET").unwrap();
            let expiration = std::env::var("JWT_EXPIRATION")
                                            .expect("JWT_EXPIRATION must be set")
                                            .parse::<i64>()
                                            .expect("JWT_EXPIRATION must be a valid number");
            match create_jwt(user_id, &req.email, Role::User, &secret, expiration) {
                Ok(token) => HttpResponse::Created().json(serde_json::json!({
                    "token": token,
                    "user_id": user_id,
                    "email": req.email
                })),
                Err(_) => HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "User created but failed to generate token"
                }))
            }
        }
        Err(e) => {
            log::error!("Failed to create user: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to create user"
            }))
        }
    }
}

pub async fn get_profile(
    pool: web::Data<MySqlPool>,
    claims: web::ReqData<Claims>,
) -> HttpResponse {
    let user_repo = UserRepository::new(pool.get_ref().clone());

    match user_repo.find_by_id(&claims.sub).await {
        Ok(Some(user)) => HttpResponse::Ok().json(serde_json::json!({
            "id": user.id,
            "username": user.first_name,
            "email": user.email,
            "is_admin": false
        })),
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
}