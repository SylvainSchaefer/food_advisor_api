use chrono::NaiveDateTime;
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "PascalCase")]
pub enum Difficulty {
    Easy,
    Medium,
    Hard,
    Expert,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
pub enum StepType {
    Cooking,
    Action,
}
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct RecipeIngredient {
    pub recipe_id: u32,
    pub ingredient_id: u32,
    pub quantity: f64,
    pub is_optional: bool,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct RecipeStep {
    pub recipe_id: u32,
    pub step_order: u32,
    pub description: String,
    pub duration_minutes: Option<u32>,
    pub step_type: StepType,
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

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct CompletedRecipe {
    pub completion_id: u32,
    pub user_id: u32,
    pub recipe_id: u32,
    pub rating: Option<u32>,
    pub comment: Option<String>,
    pub completion_date: NaiveDateTime,
}
