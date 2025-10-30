use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

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
