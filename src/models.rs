use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use validator::Validate;

// =============================================
// Enums
// =============================================

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(rename_all = "UPPERCASE")]
pub enum Gender {
    M,
    F,
    Other,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(rename_all = "lowercase")]
pub enum Role {
    User,
    Administrator,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
pub enum UnitOfMeasure {
    #[sqlx(rename = "g")]
    Gram,
    #[sqlx(rename = "kg")]
    Kilogram,
    #[sqlx(rename = "ml")]
    Milliliter,
    #[sqlx(rename = "l")]
    Liter,
    #[sqlx(rename = "piece")]
    Piece,
    #[sqlx(rename = "teaspoon")]
    Teaspoon,
    #[sqlx(rename = "tablespoon")]
    Tablespoon,
    #[sqlx(rename = "cup")]
    Cup,
    #[sqlx(rename = "pinch")]
    Pinch,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
pub enum Difficulty {
    Easy,
    Medium,
    Hard,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
pub enum PreferenceType {
    Allergy,
    Intolerance,
    Aversion,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
pub enum Severity {
    Mild,
    Moderate,
    Severe,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
pub enum IngredientPreferenceType {
    Excluded,
    Avoided,
    Preferred,
    Favorite,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
pub enum RiskLevel {
    Low,
    Medium,
    High,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
pub enum ListStatus {
    #[sqlx(rename = "in_progress")]
    InProgress,
    #[sqlx(rename = "completed")]
    Completed,
    #[sqlx(rename = "archived")]
    Archived,
}

// =============================================
// Main tables
// =============================================

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct DietaryRegimen {
    pub id: i32,
    pub name: String,
    pub description: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
#[sqlx(rename_all = "snake_case")]
pub struct User {
    pub id: i32,
    pub email: String,
    pub password_hash: String,
    pub last_name: String,
    pub first_name: String,
    pub date_of_birth: Option<NaiveDate>,
    pub gender: Gender,
    pub city: Option<String>,
    pub postal_code: Option<String>,
    pub country: String,
    pub role: Role,
    pub dietary_regimen_id: Option<i32>,
    pub active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct IngredientCategory {
    pub id: i32,
    pub name: String,
    pub description: Option<String>,
    pub icon: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct Ingredient {
    pub id: i32,
    pub name: String,
    pub category_id: i32,
    pub unit_of_measure: UnitOfMeasure,
    pub calories_per_100g: Option<rust_decimal::Decimal>,
    pub protein_per_100g: Option<rust_decimal::Decimal>,
    pub carbs_per_100g: Option<rust_decimal::Decimal>,
    pub fat_per_100g: Option<rust_decimal::Decimal>,
    pub fiber_per_100g: Option<rust_decimal::Decimal>,
    pub estimated_price: Option<rust_decimal::Decimal>,
    pub shelf_life_days: i32,
    pub created_by: Option<i32>,
    pub approved: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct Allergen {
    pub id: i32,
    pub name: String,
    pub description: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct IngredientAllergen {
    pub ingredient_id: i32,
    pub allergen_id: i32,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct DietaryPreference {
    pub id: i32,
    pub user_id: i32,
    pub allergen_id: Option<i32>,
    pub preference_type: PreferenceType,
    pub severity: Severity,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct IngredientPreference {
    pub id: i32,
    pub user_id: i32,
    pub ingredient_id: i32,
    pub preference_type: IngredientPreferenceType,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct Recipe {
    pub id: i32,
    pub title: String,
    pub description: Option<String>,
    pub instructions: String,
    pub prep_time: Option<i32>,
    pub cook_time: Option<i32>,
    pub total_time: Option<i32>,
    pub servings: i32,
    pub difficulty: Difficulty,
    pub estimated_cost: Option<rust_decimal::Decimal>,
    pub image_url: Option<String>,
    pub created_by: i32,
    pub published: bool,
    pub average_rating: rust_decimal::Decimal,
    pub rating_count: i32,
    pub completion_count: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct FavoriteRecipe {
    pub user_id: i32,
    pub recipe_id: i32,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct RecipeIngredient {
    pub id: i32,
    pub recipe_id: i32,
    pub ingredient_id: i32,
    pub quantity: rust_decimal::Decimal,
    pub unit_of_measure: Option<String>,
    pub optional: bool,
    pub notes: Option<String>,
    pub order_position: i32,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct RecipeStep {
    pub id: i32,
    pub recipe_id: i32,
    pub step_number: i32,
    pub description: String,
    pub duration_minutes: Option<i32>,
    pub image_url: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct UserStock {
    pub id: i32,
    pub user_id: i32,
    pub ingredient_id: i32,
    pub quantity: rust_decimal::Decimal,
    pub unit_of_measure: Option<String>,
    pub expiration_date: Option<NaiveDate>,
    pub location: String,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct RecipeHistory {
    pub id: i32,
    pub user_id: i32,
    pub recipe_id: i32,
    pub completion_date: DateTime<Utc>,
    pub rating: Option<i32>,
    pub actual_time_minutes: Option<i32>,
    pub servings_made: Option<i32>,
    pub stock_updated: bool,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct Comment {
    pub id: i32,
    pub recipe_id: i32,
    pub user_id: i32,
    pub history_id: Option<i32>,
    pub comment: String,
    pub rating: Option<i32>,
    pub visible: bool,
    pub moderated: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct ShoppingList {
    pub id: i32,
    pub user_id: i32,
    pub name: String,
    pub creation_date: NaiveDate,
    pub planned_shopping_date: Option<NaiveDate>,
    pub status: ListStatus,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct ShoppingListIngredient {
    pub id: i32,
    pub list_id: i32,
    pub ingredient_id: i32,
    pub quantity: rust_decimal::Decimal,
    pub unit_of_measure: Option<String>,
    pub recipe_id: Option<i32>,
    pub purchased: bool,
    pub actual_price: Option<rust_decimal::Decimal>,
    pub notes: Option<String>,
}

// =============================================
// DTOs for requests
// =============================================

#[derive(Debug, Deserialize, Validate)]
pub struct RegisterRequest {
    #[validate(email)]
    pub email: String,
    #[validate(length(min = 8))]
    pub password: String,
    #[validate(length(min = 2, max = 100))]
    pub last_name: String,
    #[validate(length(min = 2, max = 100))]
    pub first_name: String,
    pub date_of_birth: Option<NaiveDate>,
    pub gender: Option<Gender>,
    pub city: Option<String>,
    pub postal_code: Option<String>,
    pub dietary_regimen_id: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub token: String,
    pub user: UserResponse,
}

#[derive(Debug, Serialize)]
pub struct UserResponse {
    pub id: i32,
    pub email: String,
    pub last_name: String,
    pub first_name: String,
    pub role: Role,
    pub active: bool,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        UserResponse {
            id: user.id,
            email: user.email,
            last_name: user.last_name,
            first_name: user.first_name,
            role: user.role,
            active: user.active,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: String,
    pub email: String,
    pub role: Role,
    pub exp: usize,
}

// =============================================
// DTOs for recipe creation
// =============================================

#[derive(Debug, Deserialize, Validate)]
pub struct CreateRecipeRequest {
    #[validate(length(min = 3, max = 200))]
    pub title: String,
    pub description: Option<String>,
    #[validate(length(min = 10))]
    pub instructions: String,
    pub prep_time: Option<i32>,
    pub cook_time: Option<i32>,
    pub servings: i32,
    pub difficulty: Difficulty,
    pub image_url: Option<String>,
    pub ingredients: Vec<CreateRecipeIngredientRequest>,
    pub steps: Vec<CreateRecipeStepRequest>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CreateRecipeIngredientRequest {
    pub ingredient_id: i32,
    pub quantity: rust_decimal::Decimal,
    pub unit_of_measure: Option<String>,
    pub optional: bool,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CreateRecipeStepRequest {
    pub step_number: i32,
    #[validate(length(min = 5))]
    pub description: String,
    pub duration_minutes: Option<i32>,
    pub image_url: Option<String>,
}

// =============================================
// DTOs for stock
// =============================================

#[derive(Debug, Deserialize, Validate)]
pub struct CreateStockRequest {
    pub ingredient_id: i32,
    pub quantity: rust_decimal::Decimal,
    pub unit_of_measure: Option<String>,
    pub expiration_date: Option<NaiveDate>,
    pub location: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateStockRequest {
    pub quantity: Option<rust_decimal::Decimal>,
    pub expiration_date: Option<NaiveDate>,
    pub location: Option<String>,
    pub notes: Option<String>,
}
