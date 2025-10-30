use actix_web::{HttpResponse, web};
use bcrypt::{DEFAULT_COST, hash};
use chrono::NaiveDate;
use serde::Deserialize;
use sqlx::MySqlPool;

use crate::repositories::UserRepository;

#[derive(Debug, Deserialize)]
pub struct CreateAdminRequest {
    pub email: String,
    pub password: String,
    pub first_name: String,
    pub last_name: String,
    pub gender: String,
    pub birth_date: Option<String>,
    pub country: Option<String>,
    pub city: Option<String>,
}

pub async fn get_all_users(pool: web::Data<MySqlPool>) -> HttpResponse {
    let user_repo = UserRepository::new(pool.get_ref().clone());

    match user_repo.get_all().await {
        Ok(users) => {
            let user_list: Vec<_> = users
                .iter()
                .map(|u| {
                    serde_json::json!({
                        "user_id": u.user_id,
                        "email": u.email,
                        "first_name": u.first_name,
                        "last_name": u.last_name,
                        "role": u.role,
                        "is_active": u.is_active,
                        "created_at": u.created_at.format("%Y-%m-%d %H:%M:%S").to_string()
                    })
                })
                .collect();

            HttpResponse::Ok().json(user_list)
        }
        Err(e) => {
            log::error!("Database error: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Internal server error"
            }))
        }
    }
}

pub async fn create_admin(
    pool: web::Data<MySqlPool>,
    req: web::Json<CreateAdminRequest>,
) -> HttpResponse {
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

    // Créer l'administrateur via la procédure stockée
    match user_repo
        .create(
            &req.first_name,
            &req.last_name,
            gender,
            &password_hash,
            &req.email,
            "Administrator", // Role = Administrator
            req.country.as_deref(),
            req.city.as_deref(),
            birth_date,
        )
        .await
    {
        Ok(admin_id) => HttpResponse::Created().json(serde_json::json!({
            "message": "Admin created successfully",
            "user_id": admin_id
        })),
        Err(e) => {
            log::error!("Failed to create admin: {:?}", e);

            // Vérifier si c'est une erreur de duplication d'email
            let error_msg = format!("{:?}", e);
            if error_msg.contains("Email already exists") || error_msg.contains("Duplicate") {
                HttpResponse::Conflict().json(serde_json::json!({
                    "error": "Email already exists"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to create admin"
                }))
            }
        }
    }
}
