use crate::models::{
    AddIngredientToCategoryRequest, CreateCategoryRequest, TokenClaims, UpdateCategoryRequest,
};
use crate::repositories::IngredientCategoryRepository;
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
// GESTION DES CATÉGORIES
// =====================================================

/// Récupérer toutes les catégories (accessible à tous les utilisateurs authentifiés)
pub async fn get_all_categories(pool: web::Data<MySqlPool>) -> HttpResponse {
    let repo = IngredientCategoryRepository::new(pool.get_ref().clone());

    match repo.get_all_categories().await {
        Ok(categories) => HttpResponse::Ok().json(categories),
        Err(e) => {
            log::error!("Failed to retrieve categories: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve categories"
            }))
        }
    }
}

/// Récupérer une catégorie par ID avec ses ingrédients (accessible à tous)
pub async fn get_category(pool: web::Data<MySqlPool>, category_id: web::Path<i32>) -> HttpResponse {
    let repo = IngredientCategoryRepository::new(pool.get_ref().clone());

    match repo.find_category_by_id(*category_id).await {
        Ok(Some(category)) => HttpResponse::Ok().json(category),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "error": "Category not found"
        })),
        Err(e) => {
            log::error!("Failed to retrieve category: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve category"
            }))
        }
    }
}

/// Créer une catégorie (réservé aux administrateurs)
pub async fn create_category(
    pool: web::Data<MySqlPool>,
    req: web::Json<CreateCategoryRequest>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let repo = IngredientCategoryRepository::new(pool.get_ref().clone());

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(response) => return response,
    };

    match repo
        .create_category(&req.name, req.description.as_deref(), user_id)
        .await
    {
        Ok(category_id) => match repo.find_category_by_id(category_id).await {
            Ok(Some(category)) => HttpResponse::Created().json(category),
            Ok(None) => HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Category created but could not be retrieved"
            })),
            Err(e) => {
                log::error!("Failed to retrieve created category: {:?}", e);
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Category created but failed to retrieve"
                }))
            }
        },
        Err(e) => {
            log::error!("Failed to create category: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("already exists") || error_msg.contains("DUPLICATE") {
                HttpResponse::Conflict().json(serde_json::json!({
                    "error": "Category with this name already exists"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to create category"
                }))
            }
        }
    }
}

/// Modifier une catégorie (réservé aux administrateurs)
pub async fn update_category(
    pool: web::Data<MySqlPool>,
    category_id: web::Path<i32>,
    req: web::Json<UpdateCategoryRequest>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let repo = IngredientCategoryRepository::new(pool.get_ref().clone());

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(response) => return response,
    };

    match repo
        .update_category(*category_id, &req.name, req.description.as_deref(), user_id)
        .await
    {
        Ok(()) => match repo.find_category_by_id(*category_id).await {
            Ok(Some(category)) => HttpResponse::Ok().json(category),
            Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
                "error": "Category not found"
            })),
            Err(e) => {
                log::error!("Failed to retrieve updated category: {:?}", e);
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Category updated but failed to retrieve"
                }))
            }
        },
        Err(e) => {
            log::error!("Failed to update category: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("not found") {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Category not found"
                }))
            } else if error_msg.contains("already exists") || error_msg.contains("DUPLICATE") {
                HttpResponse::Conflict().json(serde_json::json!({
                    "error": "Category with this name already exists"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to update category"
                }))
            }
        }
    }
}

/// Supprimer une catégorie (réservé aux administrateurs)
pub async fn delete_category(
    pool: web::Data<MySqlPool>,
    category_id: web::Path<i32>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let repo = IngredientCategoryRepository::new(pool.get_ref().clone());

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(response) => return response,
    };

    match repo.delete_category(*category_id, user_id).await {
        Ok(()) => HttpResponse::NoContent().finish(),
        Err(e) => {
            log::error!("Failed to delete category: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("not found") {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Category not found"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to delete category"
                }))
            }
        }
    }
}

// =====================================================
// GESTION DES ASSIGNATIONS
// =====================================================

/// Ajouter un ingrédient à une catégorie (réservé aux administrateurs)
pub async fn add_ingredient_to_category(
    pool: web::Data<MySqlPool>,
    category_id: web::Path<i32>,
    req: web::Json<AddIngredientToCategoryRequest>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let repo = IngredientCategoryRepository::new(pool.get_ref().clone());

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(response) => return response,
    };

    match repo
        .add_ingredient_to_category(*category_id, req.ingredient_id, user_id)
        .await
    {
        Ok(()) => HttpResponse::Ok().json(serde_json::json!({
            "message": "Ingredient added to category successfully"
        })),
        Err(e) => {
            log::error!("Failed to add ingredient to category: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("Category not found") {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Category not found"
                }))
            } else if error_msg.contains("Ingredient not found") {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Ingredient not found"
                }))
            } else if error_msg.contains("already assigned") {
                HttpResponse::Conflict().json(serde_json::json!({
                    "error": "Ingredient already assigned to this category"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to add ingredient to category"
                }))
            }
        }
    }
}

/// Supprimer un ingrédient d'une catégorie (réservé aux administrateurs)
pub async fn remove_ingredient_from_category(
    pool: web::Data<MySqlPool>,
    path: web::Path<(i32, i32)>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let (category_id, ingredient_id) = path.into_inner();
    let repo = IngredientCategoryRepository::new(pool.get_ref().clone());

    let user_id = match extract_user_id(&claims) {
        Ok(id) => id,
        Err(response) => return response,
    };

    match repo
        .remove_ingredient_from_category(category_id, ingredient_id, user_id)
        .await
    {
        Ok(()) => HttpResponse::NoContent().finish(),
        Err(e) => {
            log::error!("Failed to remove ingredient from category: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("not found") {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Assignment not found"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to remove ingredient from category"
                }))
            }
        }
    }
}

/// Récupérer tous les ingrédients d'une catégorie
pub async fn get_category_ingredients(
    pool: web::Data<MySqlPool>,
    category_id: web::Path<i32>,
) -> HttpResponse {
    let repo = IngredientCategoryRepository::new(pool.get_ref().clone());

    match repo.get_category_ingredients(*category_id).await {
        Ok(ingredients) => HttpResponse::Ok().json(ingredients),
        Err(e) => {
            log::error!("Failed to retrieve category ingredients: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve ingredients"
            }))
        }
    }
}
