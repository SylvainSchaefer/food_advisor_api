use crate::models::{
    AddRecipeIngredientRequest, CompleteRecipeRequest, CreateRecipeRequest, PaginatedResponse,
    PaginationInfo, PaginationParams, TokenClaims, UpdateRecipeRequest,
};
use crate::repositories::RecipeRepository;
use crate::utils::auth::extract_user_info;
use actix_web::{HttpResponse, web};
use sqlx::MySqlPool;

// =====================================================
// HANDLERS - Recettes publiques
// =====================================================

/// Récupérer toutes les recettes publiées (accessible à tous)
pub async fn get_all_recipes(
    pool: web::Data<MySqlPool>,
    query: web::Query<PaginationParams>,
) -> HttpResponse {
    let params = query.into_inner();
    let recipe_repo = RecipeRepository::new(pool.get_ref().clone());

    match recipe_repo.get_all(params.page, params.page_size).await {
        Ok((recipes, total_count)) => {
            let total_pages = ((total_count as f64) / (params.page_size as f64)).ceil() as i32;

            let response = PaginatedResponse {
                data: recipes,
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
            log::error!("Failed to retrieve recipes: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve recipes"
            }))
        }
    }
}

/// Récupérer une recette par ID avec ses ingrédients (accessible à tous)
pub async fn get_recipe(pool: web::Data<MySqlPool>, recipe_id: web::Path<u32>) -> HttpResponse {
    let recipe_repo = RecipeRepository::new(pool.get_ref().clone());

    match recipe_repo.find_by_id(*recipe_id).await {
        Ok(Some(recipe_with_ingredients)) => HttpResponse::Ok().json(recipe_with_ingredients),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "error": "Recipe not found"
        })),
        Err(e) => {
            log::error!("Failed to retrieve recipe: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve recipe"
            }))
        }
    }
}

// =====================================================
// HANDLERS - Gestion des recettes (utilisateur authentifié)
// =====================================================

/// Créer une recette (accessible aux utilisateurs authentifiés)
pub async fn create_recipe(
    pool: web::Data<MySqlPool>,
    req: web::Json<CreateRecipeRequest>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let recipe_repo = RecipeRepository::new(pool.get_ref().clone());

    let (user_id, _) = match extract_user_info(&claims) {
        Ok(info) => info,
        Err(response) => return response,
    };

    match recipe_repo
        .create(
            &req.title,
            req.description.as_deref(),
            req.servings,
            &req.difficulty,
            user_id,
            req.is_published,
        )
        .await
    {
        Ok(recipe_id) => match recipe_repo.find_by_id(recipe_id).await {
            Ok(Some(recipe)) => HttpResponse::Created().json(recipe),
            Ok(None) => HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Recipe created but could not be retrieved"
            })),
            Err(e) => {
                log::error!("Failed to retrieve created recipe: {:?}", e);
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Recipe created but failed to retrieve"
                }))
            }
        },
        Err(e) => {
            log::error!("Failed to create recipe: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to create recipe"
            }))
        }
    }
}

/// Récupérer les recettes d'un utilisateur
pub async fn get_user_recipes(
    pool: web::Data<MySqlPool>,
    query: web::Query<PaginationParams>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let params = query.into_inner();
    let recipe_repo = RecipeRepository::new(pool.get_ref().clone());

    let (user_id, _) = match extract_user_info(&claims) {
        Ok(info) => info,
        Err(response) => return response,
    };

    match recipe_repo
        .get_user_recipes(user_id, params.page, params.page_size)
        .await
    {
        Ok((recipes, total_count)) => {
            let total_pages = ((total_count as f64) / (params.page_size as f64)).ceil() as i32;

            let response = PaginatedResponse {
                data: recipes,
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
            log::error!("Failed to retrieve user recipes: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve recipes"
            }))
        }
    }
}

/// Modifier une recette (auteur ou administrateur)
pub async fn update_recipe(
    pool: web::Data<MySqlPool>,
    recipe_id: web::Path<u32>,
    req: web::Json<UpdateRecipeRequest>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let recipe_repo = RecipeRepository::new(pool.get_ref().clone());

    let (user_id, user_role) = match extract_user_info(&claims) {
        Ok(info) => info,
        Err(response) => return response,
    };

    match recipe_repo
        .update(
            *recipe_id,
            &req.title,
            req.description.as_deref(),
            req.servings,
            &req.difficulty,
            req.is_published,
            user_id,
            &user_role,
        )
        .await
    {
        Ok(()) => match recipe_repo.find_by_id(*recipe_id).await {
            Ok(Some(recipe)) => HttpResponse::Ok().json(recipe),
            Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
                "error": "Recipe not found"
            })),
            Err(e) => {
                log::error!("Failed to retrieve updated recipe: {:?}", e);
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Recipe updated but failed to retrieve"
                }))
            }
        },
        Err(e) => {
            log::error!("Failed to update recipe: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("not found") {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Recipe not found"
                }))
            } else if error_msg.contains("not authorized") {
                HttpResponse::Forbidden().json(serde_json::json!({
                    "error": "You are not authorized to update this recipe"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to update recipe"
                }))
            }
        }
    }
}

/// Supprimer une recette (auteur ou administrateur)
pub async fn delete_recipe(
    pool: web::Data<MySqlPool>,
    recipe_id: web::Path<u32>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let recipe_repo = RecipeRepository::new(pool.get_ref().clone());

    let (user_id, user_role) = match extract_user_info(&claims) {
        Ok(info) => info,
        Err(response) => return response,
    };

    match recipe_repo.delete(*recipe_id, user_id, &user_role).await {
        Ok(()) => HttpResponse::NoContent().finish(),
        Err(e) => {
            log::error!("Failed to delete recipe: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("not found") {
                HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Recipe not found"
                }))
            } else if error_msg.contains("not authorized") {
                HttpResponse::Forbidden().json(serde_json::json!({
                    "error": "You are not authorized to delete this recipe"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to delete recipe"
                }))
            }
        }
    }
}

// =====================================================
// HANDLERS - Gestion des ingrédients de recette
// =====================================================

/// Ajouter un ingrédient à une recette (auteur ou administrateur)
pub async fn add_recipe_ingredient(
    pool: web::Data<MySqlPool>,
    recipe_id: web::Path<u32>,
    req: web::Json<AddRecipeIngredientRequest>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let recipe_repo = RecipeRepository::new(pool.get_ref().clone());

    let (user_id, user_role) = match extract_user_info(&claims) {
        Ok(info) => info,
        Err(response) => return response,
    };

    match recipe_repo
        .add_ingredient(
            *recipe_id,
            req.ingredient_id,
            req.quantity,
            req.is_optional,
            user_id,
            &user_role,
        )
        .await
    {
        Ok(()) => HttpResponse::Ok().json(serde_json::json!({
            "message": "Ingredient added successfully"
        })),
        Err(e) => {
            log::error!("Failed to add ingredient to recipe: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("not found") || error_msg.contains("not authorized") {
                HttpResponse::Forbidden().json(serde_json::json!({
                    "error": "Recipe not found or you are not authorized"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to add ingredient"
                }))
            }
        }
    }
}

/// Supprimer un ingrédient d'une recette (auteur ou administrateur)
pub async fn remove_recipe_ingredient(
    pool: web::Data<MySqlPool>,
    path: web::Path<(u32, u32)>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let (recipe_id, ingredient_id) = path.into_inner();
    let recipe_repo = RecipeRepository::new(pool.get_ref().clone());

    let (user_id, user_role) = match extract_user_info(&claims) {
        Ok(info) => info,
        Err(response) => return response,
    };

    match recipe_repo
        .remove_ingredient(recipe_id, ingredient_id, user_id, &user_role)
        .await
    {
        Ok(()) => HttpResponse::NoContent().finish(),
        Err(e) => {
            log::error!("Failed to remove ingredient from recipe: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("not found") || error_msg.contains("not authorized") {
                HttpResponse::Forbidden().json(serde_json::json!({
                    "error": "Recipe not found or you are not authorized"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to remove ingredient"
                }))
            }
        }
    }
}

// =====================================================
// HANDLERS - Complétion de recette
// =====================================================

/// Marquer une recette comme complétée avec un rating
pub async fn complete_recipe(
    pool: web::Data<MySqlPool>,
    recipe_id: web::Path<u32>,
    req: web::Json<CompleteRecipeRequest>,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let recipe_repo = RecipeRepository::new(pool.get_ref().clone());

    let (user_id, _) = match extract_user_info(&claims) {
        Ok(info) => info,
        Err(response) => return response,
    };

    match recipe_repo
        .complete_recipe(user_id, *recipe_id, req.rating, req.comment.as_deref())
        .await
    {
        Ok(completion_id) => HttpResponse::Created().json(serde_json::json!({
            "completion_id": completion_id,
            "message": "Recipe marked as completed"
        })),
        Err(e) => {
            log::error!("Failed to complete recipe: {:?}", e);

            let error_msg = format!("{:?}", e);
            if error_msg.contains("Rating must be") {
                HttpResponse::BadRequest().json(serde_json::json!({
                    "error": "Rating must be between 1 and 5"
                }))
            } else {
                HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to complete recipe"
                }))
            }
        }
    }
}
