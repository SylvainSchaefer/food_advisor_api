use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Ingredient {
    pub ingredient_id: u32,
    pub name: String,
    pub carbohydrates: rust_decimal::Decimal,
    pub proteins: rust_decimal::Decimal,
    pub fats: rust_decimal::Decimal,
    pub fibers: rust_decimal::Decimal,
    pub calories: rust_decimal::Decimal,
    pub price: rust_decimal::Decimal,
    pub weight: rust_decimal::Decimal,
    pub measurement_unit: String,
}

#[derive(Debug, Deserialize)]
pub struct CreateIngredientRequest {
    pub name: String,
    pub carbohydrates: rust_decimal::Decimal,
    pub proteins: rust_decimal::Decimal,
    pub fats: rust_decimal::Decimal,
    pub fibers: rust_decimal::Decimal,
    pub calories: rust_decimal::Decimal,
    pub price: rust_decimal::Decimal,
    pub weight: rust_decimal::Decimal,
    pub measurement_unit: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateIngredientRequest {
    pub name: String,
    pub carbohydrates: rust_decimal::Decimal,
    pub proteins: rust_decimal::Decimal,
    pub fats: rust_decimal::Decimal,
    pub fibers: rust_decimal::Decimal,
    pub calories: rust_decimal::Decimal,
    pub price: rust_decimal::Decimal,
    pub weight: rust_decimal::Decimal,
    pub measurement_unit: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct IngredientCategoryAssignment {
    pub ingredient_id: u32,
    pub category_id: u32,
}
