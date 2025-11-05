use crate::models::{
    CreateIngredientRequest, PaginatedResponse, PaginationInfo, PaginationParams, TokenClaims,
    UpdateIngredientRequest,
};
use crate::repositories::IngredientRepository;
use actix_web::{HttpResponse, web};
use sqlx::MySqlPool;

// =====================================================
// HANDLERS
// =====================================================

// Récupérer tous les ingrédients (accessible à tous les utilisateurs authentifiés)
pub async fn get_all_ingredients(
    pool: web::Data<MySqlPool>,
    query: web::Query<PaginationParams>,
) -> HttpResponse {
    let params = query.into_inner();
    let ingredient_repo = IngredientRepository::new(pool.get_ref().clone());

    match ingredient_repo.get_all(params.page, params.page_size).await {
        Ok((ingredients, total_count)) => {
            let total_pages = ((total_count as f64) / (params.page_size as f64)).ceil() as i32;

            let response = PaginatedResponse {
                data: ingredients,
                pagination: PaginationInfo {
                    current_page: params.page,
                    page_size: params.page_size,
                    total_count,
                    total_pages,
                    has_next: params.page < total_pages,
                    has_previous: params.page > 1,
                },
            };

            HttpResponse::Ok().json(response)
        }
        Err(e) => {
            log::error!("Failed to retrieve ingredients: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve ingredients"
            }))
        }
    }
}

// Récupérer un ingrédient par ID (accessible à tous les utilisateurs authentifiés)
pub async fn get_ingredient(
    pool: web::Data<MySqlPool>,
    ingredient_id: web::Path<i32>,
) -> HttpResponse {
    let ingredient_repo = IngredientRepository::new(pool.get_ref().clone());

    match ingredient_repo.find_by_id(*ingredient_id).await {
        Ok(Some(ingredient)) => HttpResponse::Ok().json(ingredient),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "error": "Ingredient not found"
        })),
        Err(e) => {
            log::error!("Failed to retrieve ingredient: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve ingredient"
            }))
        }
    }
}

// Créer un ingrédient (accessible à tous les utilisateurs authentifiés)
pub async fn create_ingredient(
    pool: web::Data<MySqlPool>,
    req: web::Json<CreateIngredientRequest>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let ingredient_repo = IngredientRepository::new(pool.get_ref().clone());

    // Extraire l'user_id depuis les claims
    let user_id = match claims.sub.parse::<i32>() {
        Ok(id) => id,
        Err(_) => {
            log::error!("Invalid user_id in claims");
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Invalid user identifier"
            }));
        }
    };

    match ingredient_repo
        .create(
            &req.name,
            req.carbohydrates,
            req.proteins,
            req.fats,
            req.fibers,
            req.calories,
            req.price,
            req.weight,
            &req.measurement_unit,
            user_id,
        )
        .await
    {
        Ok(ingredient_id) => {
            // Récupérer l'ingrédient créé
            match ingredient_repo.find_by_id(ingredient_id).await {
                Ok(Some(ingredient)) => HttpResponse::Created().json(ingredient),
                Ok(None) => HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Ingredient created but could not be retrieved"
                })),
                Err(e) => {
                    log::error!("Failed to retrieve created ingredient: {:?}", e);
                    HttpResponse::InternalServerError().json(serde_json::json!({
                        "error": "Ingredient created but failed to retrieve"
                    }))
                }
            }
        }
        Err(e) => {
            log::error!("Failed to create ingredient: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("already exists") || error_msg.contains("DUPLICATE") {
                HttpResponse::Conflict().json(serde_json::json!({
                    "error": "Ingredient with this name already exists"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to create ingredient"
                }))
            }
        }
    }
}

// Modifier un ingrédient (réservé aux administrateurs)
pub async fn update_ingredient(
    pool: web::Data<MySqlPool>,
    ingredient_id: web::Path<i32>,
    req: web::Json<UpdateIngredientRequest>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let ingredient_repo = IngredientRepository::new(pool.get_ref().clone());

    // Extraire l'user_id depuis les claims
    let user_id = match claims.sub.parse::<i32>() {
        Ok(id) => id,
        Err(_) => {
            log::error!("Invalid user_id in claims");
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Invalid user identifier"
            }));
        }
    };

    match ingredient_repo
        .update(
            *ingredient_id,
            &req.name,
            req.carbohydrates,
            req.proteins,
            req.fats,
            req.fibers,
            req.calories,
            req.price,
            req.weight,
            &req.measurement_unit,
            user_id,
        )
        .await
    {
        Ok(()) => {
            // Récupérer l'ingrédient modifié
            match ingredient_repo.find_by_id(*ingredient_id).await {
                Ok(Some(ingredient)) => HttpResponse::Ok().json(ingredient),
                Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Ingredient not found"
                })),
                Err(e) => {
                    log::error!("Failed to retrieve updated ingredient: {:?}", e);
                    HttpResponse::InternalServerError().json(serde_json::json!({
                        "error": "Ingredient updated but failed to retrieve"
                    }))
                }
            }
        }
        Err(e) => {
            log::error!("Failed to update ingredient: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("not found") {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Ingredient not found"
                }))
            } else if error_msg.contains("already exists") || error_msg.contains("DUPLICATE") {
                HttpResponse::Conflict().json(serde_json::json!({
                    "error": "Ingredient with this name already exists"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to update ingredient"
                }))
            }
        }
    }
}

// Supprimer un ingrédient (réservé aux administrateurs)
pub async fn delete_ingredient(
    pool: web::Data<MySqlPool>,
    ingredient_id: web::Path<i32>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let ingredient_repo = IngredientRepository::new(pool.get_ref().clone());

    // Extraire l'user_id depuis les claims
    let user_id = match claims.sub.parse::<i32>() {
        Ok(id) => id,
        Err(_) => {
            log::error!("Invalid user_id in claims");
            return HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Invalid user identifier"
            }));
        }
    };

    match ingredient_repo.delete(*ingredient_id, user_id).await {
        Ok(()) => HttpResponse::NoContent().finish(),
        Err(e) => {
            log::error!("Failed to delete ingredient: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("not found") {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Ingredient not found"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to delete ingredient"
                }))
            }
        }
    }
}
