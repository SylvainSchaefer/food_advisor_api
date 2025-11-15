use crate::models::{SetPreferenceRequest, TokenClaims};
use crate::repositories::UserPreferencesRepository;
use actix_web::{HttpResponse, web};
use sqlx::MySqlPool;

// Helper pour extraire user_id
fn extract_user_id(claims: &TokenClaims) -> Result<i32, HttpResponse> {
    match claims.sub.parse::<i32>() {
        Ok(id) => Ok(id),
        Err(_) => {
            log::error!("Invalid user_id in claims");
            Err(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Invalid user identifier"
            })))
        }
    }
}

// =====================================================
// PRÉFÉRENCES DE CATÉGORIES
// =====================================================

/// Définir une préférence de catégorie
pub async fn set_category_preference(
    pool: web::Data<MySqlPool>,
    category_id: web::Path<i32>,
    req: web::Json<SetPreferenceRequest>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let repo = UserPreferencesRepository::new(pool.get_ref().clone());

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(response) => return response,
    };

    match repo
        .set_category_preference(user_id, *category_id, &req.preference_type)
        .await
    {
        Ok(()) => HttpResponse::Ok().json(serde_json::json!({
            "message": "Category preference set successfully"
        })),
        Err(e) => {
            log::error!("Failed to set category preference: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("not found") {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Category not found"
                }))
            } else if error_msg.contains("Invalid preference type") {
                HttpResponse::BadRequest().json(serde_json::json!({
                    "error": "Invalid preference type. Must be 'excluded' or 'preferred'"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to set category preference"
                }))
            }
        }
    }
}

/// Supprimer une préférence de catégorie
pub async fn remove_category_preference(
    pool: web::Data<MySqlPool>,
    category_id: web::Path<i32>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let repo = UserPreferencesRepository::new(pool.get_ref().clone());

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(response) => return response,
    };

    match repo.remove_category_preference(user_id, *category_id).await {
        Ok(()) => HttpResponse::NoContent().finish(),
        Err(e) => {
            log::error!("Failed to remove category preference: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to remove category preference"
            }))
        }
    }
}

/// Récupérer les préférences de catégories de l'utilisateur
pub async fn get_category_preferences(
    pool: web::Data<MySqlPool>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let repo = UserPreferencesRepository::new(pool.get_ref().clone());

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(response) => return response,
    };

    match repo.get_user_category_preferences(user_id).await {
        Ok(preferences) => HttpResponse::Ok().json(preferences),
        Err(e) => {
            log::error!("Failed to retrieve category preferences: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve category preferences"
            }))
        }
    }
}

// =====================================================
// PRÉFÉRENCES D'INGRÉDIENTS
// =====================================================

/// Définir une préférence d'ingrédient
pub async fn set_ingredient_preference(
    pool: web::Data<MySqlPool>,
    ingredient_id: web::Path<i32>,
    req: web::Json<SetPreferenceRequest>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let repo = UserPreferencesRepository::new(pool.get_ref().clone());

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(response) => return response,
    };

    match repo
        .set_ingredient_preference(user_id, *ingredient_id, &req.preference_type)
        .await
    {
        Ok(()) => HttpResponse::Ok().json(serde_json::json!({
            "message": "Ingredient preference set successfully"
        })),
        Err(e) => {
            log::error!("Failed to set ingredient preference: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("not found") {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Ingredient not found"
                }))
            } else if error_msg.contains("Invalid preference type") {
                HttpResponse::BadRequest().json(serde_json::json!({
                    "error": "Invalid preference type. Must be 'excluded' or 'preferred'"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to set ingredient preference"
                }))
            }
        }
    }
}

/// Supprimer une préférence d'ingrédient
pub async fn remove_ingredient_preference(
    pool: web::Data<MySqlPool>,
    ingredient_id: web::Path<i32>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let repo = UserPreferencesRepository::new(pool.get_ref().clone());

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(response) => return response,
    };

    match repo
        .remove_ingredient_preference(user_id, *ingredient_id)
        .await
    {
        Ok(()) => HttpResponse::NoContent().finish(),
        Err(e) => {
            log::error!("Failed to remove ingredient preference: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to remove ingredient preference"
            }))
        }
    }
}

/// Récupérer les préférences d'ingrédients de l'utilisateur
pub async fn get_ingredient_preferences(
    pool: web::Data<MySqlPool>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let repo = UserPreferencesRepository::new(pool.get_ref().clone());

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(response) => return response,
    };

    match repo.get_user_ingredient_preferences(user_id).await {
        Ok(preferences) => HttpResponse::Ok().json(preferences),
        Err(e) => {
            log::error!("Failed to retrieve ingredient preferences: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve ingredient preferences"
            }))
        }
    }
}

// =====================================================
// TOUTES LES PRÉFÉRENCES
// =====================================================

/// Récupérer toutes les préférences de l'utilisateur (catégories + ingrédients)
pub async fn get_all_preferences(
    pool: web::Data<MySqlPool>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let repo = UserPreferencesRepository::new(pool.get_ref().clone());

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(response) => return response,
    };

    match repo.get_all_user_preferences(user_id).await {
        Ok(preferences) => HttpResponse::Ok().json(preferences),
        Err(e) => {
            log::error!("Failed to retrieve all preferences: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve preferences"
            }))
        }
    }
}
