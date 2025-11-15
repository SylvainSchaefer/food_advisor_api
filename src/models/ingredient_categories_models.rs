use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

use crate::models::Ingredient;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct IngredientCategory {
    pub category_id: u32,
    pub name: String,
    pub description: Option<String>,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CategoryWithIngredients {
    #[serde(flatten)]
    pub category: IngredientCategory,
    pub ingredients: Vec<Ingredient>,
}

#[derive(Debug, Deserialize)]
pub struct CreateCategoryRequest {
    pub name: String,
    pub description: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateCategoryRequest {
    pub name: String,
    pub description: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AddIngredientToCategoryRequest {
    pub ingredient_id: u32,
}
