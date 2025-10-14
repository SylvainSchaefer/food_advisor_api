use actix_web::{web, HttpResponse};
use sqlx::MySqlPool;
use bcrypt::{hash, DEFAULT_COST};
use uuid::Uuid;
use crate::models::{Claims, RegisterRequest, Role};
use crate::repositories::{UserRepository, AdminRepository};

pub async fn get_all_users(
    pool: web::Data<MySqlPool>,
    claims: web::ReqData<Claims>,
) -> HttpResponse {
    if claims.role != Role::Administrator {
        return HttpResponse::Forbidden().json(serde_json::json!({
            "error": "Admin access required"
        }));
    }

    let user_repo = UserRepository::new(pool.get_ref().clone());

    match user_repo.get_all().await {
        Ok(users) => {
            let user_list: Vec<_> = users.iter().map(|u| serde_json::json!({
                "id": u.id,
                "email": u.email,
                "first_name": u.first_name,
                "last_name": u.last_name,
                "active": u.active
            })).collect();

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
    req: web::Json<RegisterRequest>,
    claims: web::ReqData<Claims>,
) -> HttpResponse {
    if claims.role != Role::Administrator {
        return HttpResponse::Forbidden().json(serde_json::json!({
            "error": "Admin access required"
        }));
    }

    let admin_repo = AdminRepository::new(pool.get_ref().clone());

    let password_hash = match hash(&req.password, DEFAULT_COST) {
        Ok(h) => h,
        Err(_) => return HttpResponse::InternalServerError().json(serde_json::json!({
            "error": "Failed to hash password"
        }))
    };

    let admin_id = Uuid::new_v4().to_string();

    match admin_repo.create(&admin_id, &req.first_name, &req.last_name, &req.email, &password_hash).await {
        Ok(_) => HttpResponse::Created().json(serde_json::json!({
            "message": "Admin created successfully",
            "admin_id": admin_id
        })),
        Err(e) => {
            log::error!("Failed to create admin: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to create admin"
            }))
        }
    }
}