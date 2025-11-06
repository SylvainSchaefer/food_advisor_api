use chrono::NaiveDateTime;
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use validator::{Validate, ValidationError};

#[derive(Debug, Serialize, Deserialize)]
pub struct RecipeStep {
    pub recipe_step_id: u32,
    pub recipe_id: u32,
    pub step_order: u32,
    pub description: String,
    pub duration_minutes: u32,
    pub step_type: String,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Recipe {
    pub recipe_id: u32,
    pub title: String,
    pub description: Option<String>,
    pub servings: u32,
    pub difficulty: String,
    pub author_user_id: u32,
    pub is_published: bool,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub author_first_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub author_last_name: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RecipeWithIngredients {
    #[serde(flatten)]
    pub recipe: Recipe,
    pub ingredients: Vec<RecipeIngredientDetail>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct RecipeIngredientDetail {
    pub recipe_id: u32,
    pub ingredient_id: u32,
    pub ingredient_name: String,
    pub quantity: Decimal,
    pub measurement_unit: String,
    pub is_optional: bool,
    pub carbohydrates: Decimal,
    pub proteins: Decimal,
    pub fats: Decimal,
    pub fibers: Decimal,
    pub calories: Decimal,
    pub price: Decimal,
    pub weight: Decimal,
}

#[derive(Debug, Deserialize)]
pub struct CreateRecipeRequest {
    pub title: String,
    pub description: Option<String>,
    pub servings: u32,
    pub difficulty: String,
    pub is_published: bool,
}

#[derive(Debug, Deserialize)]
pub struct UpdateRecipeRequest {
    pub title: String,
    pub description: Option<String>,
    pub servings: u32,
    pub difficulty: String,
    pub is_published: bool,
}

#[derive(Debug, Deserialize)]
pub struct AddRecipeIngredientRequest {
    pub ingredient_id: u32,
    pub quantity: Decimal,
    pub is_optional: bool,
}

#[derive(Debug, Deserialize)]
pub struct CompleteRecipeRequest {
    pub rating: Option<u32>,
    pub comment: Option<String>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct AddRecipeStepRequest {
    #[validate(range(min = 1, message = "Step order must be at least 1"))]
    pub step_order: u32,

    #[validate(length(
        min = 1,
        max = 5000,
        message = "Description must be between 1 and 5000 characters"
    ))]
    pub description: String,

    #[validate(range(min = 0, message = "Duration cannot be negative"))]
    pub duration_minutes: Option<u32>,

    #[validate(custom = "validate_step_type")]
    pub step_type: String,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateRecipeStepRequest {
    #[validate(range(min = 1, message = "Step order must be at least 1"))]
    pub step_order: u32,

    #[validate(length(
        min = 1,
        max = 5000,
        message = "Description must be between 1 and 5000 characters"
    ))]
    pub description: String,

    #[validate(range(min = 0, message = "Duration cannot be negative"))]
    pub duration_minutes: Option<u32>,

    #[validate(custom = "validate_step_type")]
    pub step_type: String,
}

// Fonction de validation personnalisée pour step_type
fn validate_step_type(step_type: &str) -> Result<(), validator::ValidationError> {
    if step_type == "cooking" || step_type == "action" {
        Ok(())
    } else {
        Err(validator::ValidationError::new(
            "Invalid step type. Must be 'cooking' or 'action'",
        ))
    }
}
