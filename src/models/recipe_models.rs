use chrono::{NaiveDate, NaiveDateTime};
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
pub struct Recipe {
    pub recipe_id: u32,
    pub title: String,
    pub description: Option<String>,
    pub servings: Option<u32>,
    pub is_published: bool,
    pub difficulty: Difficulty,
    pub image_url: Option<String>,
    pub author_user_id: u32,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
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

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct CompletedRecipe {
    pub completion_id: u32,
    pub user_id: u32,
    pub recipe_id: u32,
    pub completion_date: NaiveDateTime,
    pub comment: Option<String>,
    pub rating: Option<u32>,
    pub created_at: NaiveDateTime,
}
