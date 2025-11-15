use chrono::{NaiveDate, NaiveDateTime};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

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

/// Structure pour les claims JWT (légère, seulement ce qui est nécessaire)
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TokenClaims {
    pub sub: String, // user_id
    pub email: String,
    pub role: Role,
    pub exp: usize, // expiration timestamp
}

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

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub first_name: String,
    pub last_name: String,
    pub gender: String,             // "Male", "Female", "Other"
    pub birth_date: Option<String>, // Format: "YYYY-MM-DD"
    pub country: Option<String>,
    pub city: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ProfileResponse {
    pub user_id: u32,
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub role: Role,
    pub gender: String,
    pub birth_date: Option<NaiveDate>,
    pub country: Option<String>,
    pub city: Option<String>,
    pub created_at: String,
}
