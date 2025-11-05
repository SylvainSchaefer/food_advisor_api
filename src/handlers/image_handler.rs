use crate::models::TokenClaims;
use crate::{repositories::ImageRepository, utils::auth::extract_user_info};
use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use futures_util::stream::StreamExt as _;
use sqlx::MySqlPool;

const MAX_IMAGE_SIZE: usize = 10 * 1024 * 1024; // 10 MB
const ALLOWED_MIME_TYPES: &[&str] = &["image/jpeg", "image/png", "image/gif", "image/webp"];

/// Ajouter une image à une recette
pub async fn add_recipe_image(
    pool: web::Data<MySqlPool>,
    path: web::Path<u32>,
    mut payload: Multipart,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let recipe_id = path.into_inner();

    // Extraire l'utilisateur du JWT
    let (user_id, _) = match extract_user_info(&claims) {
        Ok(info) => info,
        Err(response) => return response,
    };

    let mut image_data: Vec<u8> = Vec::new();
    let mut image_name = String::new();
    let mut image_type = String::new();
    let mut alt_text: Option<String> = None;
    let mut is_primary = false;

    // Traiter le multipart
    while let Some(item) = payload.next().await {
        let mut field = match item {
            Ok(f) => f,
            Err(e) => {
                log::error!("Multipart error: {:?}", e);
                return HttpResponse::BadRequest().json(serde_json::json!({
                    "error": "Invalid multipart data",
                    "message": format!("Multipart error: {}", e)
                }));
            }
        };

        // Extraire le nom du champ
        let field_name = match field.content_disposition() {
            Some(cd) => cd.get_name().unwrap_or(""),
            None => "",
        };

        match field_name {
            "image" => {
                // Extraire le nom du fichier
                image_name = match field.content_disposition() {
                    Some(cd) => cd.get_filename().unwrap_or("image.jpg").to_string(),
                    None => "image.jpg".to_string(),
                };

                image_type = field
                    .content_type()
                    .map(|ct| ct.to_string())
                    .unwrap_or_else(|| "image/jpeg".to_string());

                // Vérifier le type MIME
                if !ALLOWED_MIME_TYPES.contains(&image_type.as_str()) {
                    return HttpResponse::BadRequest().json(serde_json::json!({
                        "error": "Invalid image type",
                        "message": format!("Only {} are allowed", ALLOWED_MIME_TYPES.join(", "))
                    }));
                }

                // Lire les données de l'image
                while let Some(chunk) = field.next().await {
                    let data = match chunk {
                        Ok(d) => d,
                        Err(e) => {
                            log::error!("Read error: {:?}", e);
                            return HttpResponse::BadRequest().json(serde_json::json!({
                                "error": "Failed to read image data",
                                "message": format!("Read error: {}", e)
                            }));
                        }
                    };
                    image_data.extend_from_slice(&data);

                    // Vérifier la taille
                    if image_data.len() > MAX_IMAGE_SIZE {
                        return HttpResponse::PayloadTooLarge().json(serde_json::json!({
                            "error": "Image too large",
                            "message": format!("Maximum size is {} MB", MAX_IMAGE_SIZE / 1024 / 1024)
                        }));
                    }
                }
            }
            "alt_text" => {
                let mut text = String::new();
                while let Some(chunk) = field.next().await {
                    let data = match chunk {
                        Ok(d) => d,
                        Err(e) => {
                            log::error!("Read error: {:?}", e);
                            continue;
                        }
                    };
                    text.push_str(&String::from_utf8_lossy(&data));
                }
                if !text.trim().is_empty() {
                    alt_text = Some(text.trim().to_string());
                }
            }
            "is_primary" => {
                let mut text = String::new();
                while let Some(chunk) = field.next().await {
                    let data = match chunk {
                        Ok(d) => d,
                        Err(e) => {
                            log::error!("Read error: {:?}", e);
                            continue;
                        }
                    };
                    text.push_str(&String::from_utf8_lossy(&data));
                }
                is_primary = text.trim() == "true" || text.trim() == "1";
            }
            _ => {
                // Ignorer les autres champs
                while let Some(_) = field.next().await {}
            }
        }
    }

    if image_data.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "error": "No image provided",
            "message": "Please upload an image file"
        }));
    }

    // Obtenir les dimensions de l'image (optionnel)
    let (width, height) = match image::load_from_memory(&image_data) {
        Ok(img) => (Some(img.width()), Some(img.height())),
        Err(e) => {
            log::warn!("Could not read image dimensions: {:?}", e);
            (None, None)
        }
    };

    let image_size = image_data.len() as u32;

    // Ajouter l'image à la base de données
    let repo = ImageRepository::new(pool.get_ref().clone());
    match repo
        .add_recipe_image(
            recipe_id, image_data, image_name, image_type, image_size, width, height, is_primary,
            alt_text, user_id,
        )
        .await
    {
        Ok(image_id) => HttpResponse::Created().json(serde_json::json!({
            "message": "Image added successfully",
            "image_id": image_id,
            "recipe_id": recipe_id
        })),
        Err(e) => {
            log::error!("Failed to add recipe image: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to add recipe image",
                "message": e.to_string()
            }))
        }
    }
}

/// Ajouter une image à un ingrédient
pub async fn add_ingredient_image(
    pool: web::Data<MySqlPool>,
    path: web::Path<u32>,
    mut payload: Multipart,
    claims: web::ReqData<TokenClaims>,
) -> HttpResponse {
    let ingredient_id = path.into_inner();

    // Extraire l'utilisateur du JWT
    let (user_id, _) = match extract_user_info(&claims) {
        Ok(info) => info,
        Err(response) => return response,
    };

    let mut image_data: Vec<u8> = Vec::new();
    let mut image_name = String::new();
    let mut image_type = String::new();
    let mut alt_text: Option<String> = None;
    let mut is_primary = false;

    // Traiter le multipart
    while let Some(item) = payload.next().await {
        let mut field = match item {
            Ok(f) => f,
            Err(e) => {
                log::error!("Multipart error: {:?}", e);
                return HttpResponse::BadRequest().json(serde_json::json!({
                    "error": "Invalid multipart data",
                    "message": format!("Multipart error: {}", e)
                }));
            }
        };

        // Extraire le nom du champ
        let field_name = match field.content_disposition() {
            Some(cd) => cd.get_name().unwrap_or(""),
            None => "",
        };

        match field_name {
            "image" => {
                // Extraire le nom du fichier
                image_name = match field.content_disposition() {
                    Some(cd) => cd.get_filename().unwrap_or("image.jpg").to_string(),
                    None => "image.jpg".to_string(),
                };

                image_type = field
                    .content_type()
                    .map(|ct| ct.to_string())
                    .unwrap_or_else(|| "image/jpeg".to_string());

                // Vérifier le type MIME
                if !ALLOWED_MIME_TYPES.contains(&image_type.as_str()) {
                    return HttpResponse::BadRequest().json(serde_json::json!({
                        "error": "Invalid image type",
                        "message": format!("Only {} are allowed", ALLOWED_MIME_TYPES.join(", "))
                    }));
                }

                // Lire les données de l'image
                while let Some(chunk) = field.next().await {
                    let data = match chunk {
                        Ok(d) => d,
                        Err(e) => {
                            log::error!("Read error: {:?}", e);
                            return HttpResponse::BadRequest().json(serde_json::json!({
                                "error": "Failed to read image data",
                                "message": format!("Read error: {}", e)
                            }));
                        }
                    };
                    image_data.extend_from_slice(&data);

                    // Vérifier la taille
                    if image_data.len() > MAX_IMAGE_SIZE {
                        return HttpResponse::PayloadTooLarge().json(serde_json::json!({
                            "error": "Image too large",
                            "message": format!("Maximum size is {} MB", MAX_IMAGE_SIZE / 1024 / 1024)
                        }));
                    }
                }
            }
            "alt_text" => {
                let mut text = String::new();
                while let Some(chunk) = field.next().await {
                    let data = match chunk {
                        Ok(d) => d,
                        Err(e) => {
                            log::error!("Read error: {:?}", e);
                            continue;
                        }
                    };
                    text.push_str(&String::from_utf8_lossy(&data));
                }
                if !text.trim().is_empty() {
                    alt_text = Some(text.trim().to_string());
                }
            }
            "is_primary" => {
                let mut text = String::new();
                while let Some(chunk) = field.next().await {
                    let data = match chunk {
                        Ok(d) => d,
                        Err(e) => {
                            log::error!("Read error: {:?}", e);
                            continue;
                        }
                    };
                    text.push_str(&String::from_utf8_lossy(&data));
                }
                is_primary = text.trim() == "true" || text.trim() == "1";
            }
            _ => {
                // Ignorer les autres champs
                while let Some(_) = field.next().await {}
            }
        }
    }

    if image_data.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "error": "No image provided",
            "message": "Please upload an image file"
        }));
    }

    // Obtenir les dimensions de l'image (optionnel)
    let (width, height) = match image::load_from_memory(&image_data) {
        Ok(img) => (Some(img.width()), Some(img.height())),
        Err(e) => {
            log::warn!("Could not read image dimensions: {:?}", e);
            (None, None)
        }
    };

    let image_size = image_data.len() as u32;

    // Ajouter l'image à la base de données
    let repo = ImageRepository::new(pool.get_ref().clone());
    match repo
        .add_ingredient_image(
            ingredient_id,
            image_data,
            image_name,
            image_type,
            image_size,
            width,
            height,
            is_primary,
            alt_text,
            user_id,
        )
        .await
    {
        Ok(image_id) => HttpResponse::Created().json(serde_json::json!({
            "message": "Image added successfully",
            "image_id": image_id,
            "ingredient_id": ingredient_id
        })),
        Err(e) => {
            log::error!("Failed to add ingredient image: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to add ingredient image",
                "message": e.to_string()
            }))
        }
    }
}

/// Récupérer l'image d'une recette (pas besoin de claims pour la lecture)
pub async fn get_recipe_image(pool: web::Data<MySqlPool>, path: web::Path<u32>) -> HttpResponse {
    let recipe_id = path.into_inner();
    let repo = ImageRepository::new(pool.get_ref().clone());

    match repo.get_recipe_image(recipe_id).await {
        Ok(Some(image)) => HttpResponse::Ok()
            .content_type(image.image_type)
            .append_header((
                "Content-Disposition",
                format!("inline; filename=\"{}\"", image.image_name),
            ))
            .append_header(("Cache-Control", "public, max-age=86400"))
            .body(image.image_data),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "error": "Image not found",
            "message": format!("No image found for recipe with id {}", recipe_id)
        })),
        Err(e) => {
            log::error!("Failed to retrieve recipe image: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve recipe image"
            }))
        }
    }
}

/// Récupérer l'image d'un ingrédient (pas besoin de claims pour la lecture)
pub async fn get_ingredient_image(
    pool: web::Data<MySqlPool>,
    path: web::Path<u32>,
) -> HttpResponse {
    let ingredient_id = path.into_inner();
    let repo = ImageRepository::new(pool.get_ref().clone());

    match repo.get_ingredient_image(ingredient_id).await {
        Ok(Some(image)) => HttpResponse::Ok()
            .content_type(image.image_type)
            .append_header((
                "Content-Disposition",
                format!("inline; filename=\"{}\"", image.image_name),
            ))
            .append_header(("Cache-Control", "public, max-age=86400"))
            .body(image.image_data),
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({
            "error": "Image not found",
            "message": format!("No image found for ingredient with id {}", ingredient_id)
        })),
        Err(e) => {
            log::error!("Failed to retrieve ingredient image: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to retrieve ingredient image"
            }))
        }
    }
}
