use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct UserCategoryPreference {
    pub user_id: u32,
    pub category_id: u32,
    pub category_name: String,
    pub category_description: Option<String>,
    pub preference_type: String,
    pub created_at: NaiveDateTime,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct UserIngredientPreference {
    pub user_id: u32,
    pub ingredient_id: u32,
    pub ingredient_name: String,
    pub preference_type: String,
    pub created_at: NaiveDateTime,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AllUserPreferences {
    pub category_preferences: Vec<UserCategoryPreference>,
    pub ingredient_preferences: Vec<UserIngredientPreference>,
}

#[derive(Debug, Deserialize)]
pub struct SetPreferenceRequest {
    pub preference_type: String, // "excluded" ou "preferred"
}
