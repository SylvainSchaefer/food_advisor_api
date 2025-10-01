use actix_web::{web, HttpResponse};
use sqlx::MySqlPool;
use bcrypt::{hash, verify, DEFAULT_COST};
use uuid::Uuid;
use crate::models::*;
use crate::auth::create_jwt;
use crate::models::Claims;
use crate::repository::{UserRepository, AdminRepository};

pub async fn login(
    pool: web::Data<MySqlPool>,
    req: web::Json<LoginRequest>,
) -> HttpResponse {
    let user_repo = UserRepository::new(pool.get_ref().clone());
    let admin_repo = AdminRepository::new(pool.get_ref().clone());

    // D'abord vérifier dans la table users
    match user_repo.find_by_email(&req.email).await {
        Ok(Some(user)) => {
            return handle_login(user.id, user.email, user.password_hash, false, &req.password).await;
        }
        Err(e) => {
            log::error!("Database error querying users: {:?}", e);
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Internal server error"
            }));
        }
        Ok(None) => {} // Continuer
    }

    // Si pas trouvé, vérifier dans la table admins
    match admin_repo.find_by_email(&req.email).await {
        Ok(Some(admin)) => {
            return handle_login(admin.id, admin.email, admin.password_hash, true, &req.password).await;
        }
        Err(e) => {
            log::error!("Database error querying admins: {:?}", e);
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Internal server error"
            }));
        }
        Ok(None) => {} // Continuer
    }

    HttpResponse::Unauthorized().json(serde_json::json!({
        "error": "Invalid credentials"
    }))
}

async fn handle_login(
    id: String,
    email: String,
    password_hash: String,
    is_admin: bool,
    password: &str,
) -> HttpResponse {
    match verify(password, &password_hash) {
        Ok(valid) => {
            if valid {
                let secret = std::env::var("JWT_SECRET").unwrap();
                let expiration = std::env::var("JWT_EXPIRATION")
                                            .expect("JWT_EXPIRATION must be set")
                                            .parse::<i64>()
                                            .expect("JWT_EXPIRATION must be a valid number");

                match create_jwt(&id, &email, is_admin, &secret, expiration) {
                    Ok(token) => HttpResponse::Ok().json(serde_json::json!({
                        "token": token,
                        "user_id": id,
                        "email": email,
                        "is_admin": is_admin
                    })),
                    Err(_) => HttpResponse::InternalServerError().json(serde_json::json!({
                        "error": "Failed to create token"
                    }))
                }
            } else {
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

    let user_id = Uuid::new_v4().to_string();

    match user_repo.create(&user_id, &req.username, &req.email, &password_hash).await {
        Ok(_) => {
            let secret = std::env::var("JWT_SECRET").unwrap();
            let expiration = std::env::var("JWT_EXPIRATION")
                                            .expect("JWT_EXPIRATION must be set")
                                            .parse::<i64>()
                                            .expect("JWT_EXPIRATION must be a valid number");
            match create_jwt(&user_id, &req.email, false, &secret, expiration) {
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
    let admin_repo = AdminRepository::new(pool.get_ref().clone());

    if claims.is_admin {
        match admin_repo.find_by_id(&claims.sub).await {
            Ok(Some(admin)) => HttpResponse::Ok().json(serde_json::json!({
                "id": admin.id,
                "username": admin.username,
                "email": admin.email,
                "is_admin": true
            })),
            Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
                "error": "Admin not found"
            })),
            Err(e) => {
                log::error!("Database error: {:?}", e);
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Internal server error"
                }))
            }
        }
    } else {
        match user_repo.find_by_id(&claims.sub).await {
            Ok(Some(user)) => HttpResponse::Ok().json(serde_json::json!({
                "id": user.id,
                "username": user.username,
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
}

pub async fn get_all_users(
    pool: web::Data<MySqlPool>,
    claims: web::ReqData<Claims>,
) -> HttpResponse {
    if !claims.is_admin {
        return HttpResponse::Forbidden().json(serde_json::json!({
            "error": "Admin access required"
        }));
    }

    let user_repo = UserRepository::new(pool.get_ref().clone());

    match user_repo.get_all().await {
        Ok(users) => {
            let user_list: Vec<_> = users.iter().map(|u| serde_json::json!({
                "id": u.id,
                "username": u.username,
                "email": u.email,
                "is_active": u.is_active
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

pub async fn deactivate_user(
    pool: web::Data<MySqlPool>,
    user_id: web::Path<String>,
    claims: web::ReqData<Claims>,
) -> HttpResponse {
    if !claims.is_admin {
        return HttpResponse::Forbidden().json(serde_json::json!({
            "error": "Admin access required"
        }));
    }

    let user_repo = UserRepository::new(pool.get_ref().clone());

    match user_repo.deactivate(&user_id).await {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({
            "message": "User deactivated successfully"
        })),
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
    if !claims.is_admin {
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

    match admin_repo.create(&admin_id, &req.username, &req.email, &password_hash).await {
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