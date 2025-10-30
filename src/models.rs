use chrono::{NaiveDate, NaiveDateTime};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

// =====================================================
// ENUMS
// =====================================================

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "PascalCase")]
pub enum Gender {
    Male,
    Female,
    Other,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "PascalCase")]
pub enum Role {
    Administrator,
    Regular,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "PascalCase")]
pub enum Difficulty {
    Easy,
    Medium,
    Hard,
    Expert,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "PascalCase")]
pub enum Severity {
    Mild,
    Moderate,
    Severe,
    #[sqlx(rename = "Life-threatening")]
    LifeThreatening,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
pub enum PreferenceType {
    Excluded,
    Preferred,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
pub enum MeasurementUnit {
    Tablespoon,
    Teaspoon,
    Liters,
    Milliliters,
    Grams,
    Kilograms,
    Cups,
    Pieces,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
pub enum StepType {
    Cooking,
    Action,
}

// =====================================================
// MAIN MODELS
// =====================================================

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct User {
    pub user_id: u32,
    pub first_name: String,
    pub last_name: String,
    pub gender: Gender,
    pub password_hash: String,
    pub email: String,
    pub role: Role,
    pub country: Option<String>,
    pub city: Option<String>,
    pub is_active: bool,
    pub birth_date: Option<NaiveDate>,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserWithStats {
    pub user_id: u32,
    pub first_name: String,
    pub last_name: String,
    pub gender: Gender,
    pub email: String,
    pub role: Role,
    pub country: Option<String>,
    pub city: Option<String>,
    pub is_active: bool,
    pub birth_date: Option<NaiveDate>,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
    pub age: Option<i32>,
    pub recipes_created: Option<i64>,
    pub recipes_completed: Option<i64>,
    pub average_rating_given: Option<f64>,
    pub allergy_count: Option<i64>,
    pub stock_items_count: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserAllergyDetail {
    pub allergy_id: u32,
    pub allergy_name: String,
    pub severity: Severity,
    pub allergy_added_date: NaiveDateTime,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Allergy {
    pub allergy_id: u32,
    pub name: String,
    pub description: Option<String>,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserAllergy {
    pub user_id: u32,
    pub allergy_id: u32,
    pub severity: Severity,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Ingredient {
    pub ingredient_id: u32,
    pub name: String,
    pub carbohydrates: Option<f64>,
    pub proteins: Option<f64>,
    pub fats: Option<f64>,
    pub fibers: Option<f64>,
    pub calories: Option<f64>,
    pub price: Option<f64>,
    pub weight: Option<f64>,
    pub measurement_unit: MeasurementUnit,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct IngredientAllergy {
    pub ingredient_id: u32,
    pub allergy_id: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct IngredientCategory {
    pub category_id: u32,
    pub name: String,
    pub description: Option<String>,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct IngredientCategoryAssignment {
    pub ingredient_id: u32,
    pub category_id: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserIngredientCategoryPreference {
    pub user_id: u32,
    pub category_id: u32,
    pub preference_type: PreferenceType,
    pub created_at: NaiveDateTime,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserIngredientPreference {
    pub user_id: u32,
    pub ingredient_id: u32,
    pub preference_type: PreferenceType,
    pub created_at: NaiveDateTime,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserIngredientStock {
    pub stock_id: u32,
    pub user_id: u32,
    pub ingredient_id: u32,
    pub quantity: f64,
    pub expiration_date: Option<NaiveDate>,
    pub storage_location: Option<String>,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
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

// =====================================================
// AUDIT/HISTORY MODELS
// =====================================================

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AuditDeletion {
    pub audit_id: u32,
    pub table_name: String,
    pub record_id: u32,
    pub deleted_data: serde_json::Value,
    pub deleted_by_user_id: Option<u32>,
    pub deleted_at: NaiveDateTime,
    pub ip_address: Option<String>,
    pub user_agent: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct HistoryUser {
    pub history_id: u32,
    pub user_id: u32,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub gender: Option<Gender>,
    pub email: Option<String>,
    pub role: Option<Role>,
    pub country: Option<String>,
    pub city: Option<String>,
    pub is_active: Option<bool>,
    pub birth_date: Option<NaiveDate>,
    pub change_type: String,
    pub changed_by_user_id: Option<u32>,
    pub changed_at: NaiveDateTime,
    pub change_details: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ErrorLog {
    pub error_id: u32,
    pub error_type: String,
    pub error_message: String,
    pub error_details: Option<serde_json::Value>,
    pub procedure_name: Option<String>,
    pub user_id: Option<u32>,
    pub occurred_at: NaiveDateTime,
    pub ip_address: Option<String>,
    pub resolved: bool,
    pub resolved_at: Option<NaiveDateTime>,
    pub resolved_by_user_id: Option<u32>,
    pub resolution_notes: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserSession {
    pub session_id: u32,
    pub user_id: u32,
    pub session_token: String,
    pub ip_address: Option<String>,
    pub user_agent: Option<String>,
    pub login_time: NaiveDateTime,
    pub logout_time: Option<NaiveDateTime>,
    pub last_activity: NaiveDateTime,
    pub is_active: bool,
}
