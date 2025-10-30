use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "PascalCase")]
pub enum Severity {
    Mild,
    Moderate,
    Severe,
    #[sqlx(rename = "Life-threatening")]
    LifeThreatening,
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
pub struct IngredientAllergy {
    pub ingredient_id: u32,
    pub allergy_id: u32,
}
