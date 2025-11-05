use crate::models::{CompletedRecipe, Recipe, RecipeIngredientDetail, RecipeWithIngredients};
use chrono::{NaiveDateTime, Utc};
use rust_decimal::Decimal;
use sqlx::{Error, MySqlPool, Row, mysql::MySqlRow};

pub struct RecipeRepository {
    pool: MySqlPool,
}

impl RecipeRepository {
    pub fn new(pool: MySqlPool) -> Self {
        Self { pool }
    }

    fn get_recipe(row: &MySqlRow) -> Recipe {
        let created_at: chrono::DateTime<Utc> = row.get(8);
        let updated_at: chrono::DateTime<Utc> = row.get(9);

        Recipe {
            recipe_id: row.get(0),
            title: row.get(1),
            description: row.get(2),
            servings: row.get(3),
            difficulty: row.get(4),
            image_url: row.get(5),
            author_user_id: row.get(6),
            is_published: row.get(7),
            created_at: created_at.naive_utc(),
            updated_at: updated_at.naive_utc(),
            author_first_name: row.try_get(10).ok(),
            author_last_name: row.try_get(11).ok(),
        }
    }

    fn get_recipe_ingredient(row: &MySqlRow) -> RecipeIngredientDetail {
        RecipeIngredientDetail {
            recipe_id: row.get(0),
            ingredient_id: row.get(1),
            ingredient_name: row.get(2),
            quantity: row.get(3),
            measurement_unit: row.get(4),
            is_optional: row.get(5),
            carbohydrates: row.get(6),
            proteins: row.get(7),
            fats: row.get(8),
            fibers: row.get(9),
            calories: row.get(10),
            price: row.get(11),
            weight: row.get(12),
        }
    }

    pub async fn get_all(&self, page: i32, page_size: i32) -> Result<(Vec<Recipe>, i64), Error> {
        let results = sqlx::query("CALL sp_get_all_recipes(?, ?)")
            .bind(page)
            .bind(page_size)
            .fetch_all(&self.pool)
            .await?;

        let total_count: i64 = if !results.is_empty() {
            results[0].get(0)
        } else {
            0
        };

        let recipes: Vec<Recipe> = results
            .iter()
            .skip(1)
            .map(|row| Self::get_recipe(row))
            .collect();

        Ok((recipes, total_count))
    }

    pub async fn find_by_id(&self, recipe_id: u32) -> Result<Option<RecipeWithIngredients>, Error> {
        let results = sqlx::query("CALL sp_get_recipe_by_id(?, @p_error_message)")
            .bind(recipe_id)
            .fetch_all(&self.pool)
            .await?;

        if results.is_empty() {
            return Ok(None);
        }

        let recipe = Self::get_recipe(&results[0]);

        let ingredients: Vec<RecipeIngredientDetail> = results
            .iter()
            .skip(1)
            .map(|row| Self::get_recipe_ingredient(row))
            .collect();

        Ok(Some(RecipeWithIngredients {
            recipe,
            ingredients,
        }))
    }

    pub async fn get_user_recipes(
        &self,
        user_id: u32,
        page: i32,
        page_size: i32,
    ) -> Result<(Vec<Recipe>, i64), Error> {
        let results = sqlx::query("CALL sp_get_user_recipes(?, ?, ?)")
            .bind(user_id)
            .bind(page)
            .bind(page_size)
            .fetch_all(&self.pool)
            .await?;

        let total_count: i64 = if !results.is_empty() {
            results[0].get(0)
        } else {
            0
        };

        let recipes: Vec<Recipe> = results
            .iter()
            .skip(1)
            .map(|row| Self::get_recipe(row))
            .collect();

        Ok((recipes, total_count))
    }

    pub async fn create(
        &self,
        title: &str,
        description: Option<&str>,
        servings: u32,
        difficulty: &str,
        image_url: Option<&str>,
        author_user_id: u32,
        is_published: bool,
    ) -> Result<u32, Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_create_recipe(?, ?, ?, ?, ?, ?, ?, @p_recipe_id, @p_error_message)")
            .bind(title)
            .bind(description)
            .bind(servings)
            .bind(difficulty)
            .bind(image_url)
            .bind(author_user_id)
            .bind(is_published)
            .execute(&mut *conn)
            .await?;

        let result: (Option<i64>, Option<String>) =
            sqlx::query("SELECT @p_recipe_id, @p_error_message")
                .map(|row: MySqlRow| (row.get(0), row.get(1)))
                .fetch_one(&mut *conn)
                .await?;

        match result {
            (Some(recipe_id), None) => Ok(recipe_id as u32),
            (None, Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (Some(_), Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (None, None) => Err(Error::Protocol(
                "Unknown error during recipe creation".to_string(),
            )),
        }
    }

    pub async fn update(
        &self,
        recipe_id: u32,
        title: &str,
        description: Option<&str>,
        servings: u32,
        difficulty: &str,
        image_url: Option<&str>,
        is_published: bool,
        user_id: u32,
        user_role: &str,
    ) -> Result<(), Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_update_recipe(?, ?, ?, ?, ?, ?, ?, ?, ?, @p_error_message)")
            .bind(recipe_id)
            .bind(title)
            .bind(description)
            .bind(servings)
            .bind(difficulty)
            .bind(image_url)
            .bind(is_published)
            .bind(user_id)
            .bind(user_role)
            .execute(&mut *conn)
            .await?;

        let error_message: Option<String> = sqlx::query("SELECT @p_error_message")
            .map(|row: MySqlRow| row.get(0))
            .fetch_one(&mut *conn)
            .await?;

        match error_message {
            None => Ok(()),
            Some(error_msg) => Err(Error::Protocol(error_msg)),
        }
    }

    pub async fn delete(&self, recipe_id: u32, user_id: u32, user_role: &str) -> Result<(), Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_delete_recipe(?, ?, ?, @p_error_message)")
            .bind(recipe_id)
            .bind(user_id)
            .bind(user_role)
            .execute(&mut *conn)
            .await?;

        let error_message: Option<String> = sqlx::query("SELECT @p_error_message")
            .map(|row: MySqlRow| row.get(0))
            .fetch_one(&mut *conn)
            .await?;

        match error_message {
            None => Ok(()),
            Some(error_msg) => Err(Error::Protocol(error_msg)),
        }
    }

    pub async fn add_ingredient(
        &self,
        recipe_id: u32,
        ingredient_id: u32,
        quantity: Decimal,
        is_optional: bool,
        user_id: u32,
        user_role: &str,
    ) -> Result<(), Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query(
            "CALL sp_add_recipe_ingredient(?, ?, ?, ?, ?, ?, @p_success, @p_error_message)",
        )
        .bind(recipe_id)
        .bind(ingredient_id)
        .bind(quantity)
        .bind(is_optional)
        .bind(user_id)
        .bind(user_role)
        .execute(&mut *conn)
        .await?;

        let result: (Option<bool>, Option<String>) =
            sqlx::query("SELECT @p_success, @p_error_message")
                .map(|row: MySqlRow| (row.get(0), row.get(1)))
                .fetch_one(&mut *conn)
                .await?;

        match result {
            (Some(true), None) => Ok(()),
            (Some(false), Some(error_msg)) | (None, Some(error_msg)) => {
                Err(Error::Protocol(error_msg))
            }
            _ => Err(Error::Protocol(
                "Unknown error adding ingredient".to_string(),
            )),
        }
    }

    pub async fn remove_ingredient(
        &self,
        recipe_id: u32,
        ingredient_id: u32,
        user_id: u32,
        user_role: &str,
    ) -> Result<(), Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_remove_recipe_ingredient(?, ?, ?, ?, @p_error_message)")
            .bind(recipe_id)
            .bind(ingredient_id)
            .bind(user_id)
            .bind(user_role)
            .execute(&mut *conn)
            .await?;

        let error_message: Option<String> = sqlx::query("SELECT @p_error_message")
            .map(|row: MySqlRow| row.get(0))
            .fetch_one(&mut *conn)
            .await?;

        match error_message {
            None => Ok(()),
            Some(error_msg) => Err(Error::Protocol(error_msg)),
        }
    }

    pub async fn complete_recipe(
        &self,
        user_id: u32,
        recipe_id: u32,
        rating: Option<u32>,
        comment: Option<&str>,
    ) -> Result<u32, Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_complete_recipe(?, ?, ?, ?, @p_completion_id, @p_error_message)")
            .bind(user_id)
            .bind(recipe_id)
            .bind(rating)
            .bind(comment)
            .execute(&mut *conn)
            .await?;

        let result: (Option<i64>, Option<String>) =
            sqlx::query("SELECT @p_completion_id, @p_error_message")
                .map(|row: MySqlRow| (row.get(0), row.get(1)))
                .fetch_one(&mut *conn)
                .await?;

        match result {
            (Some(completion_id), None) => Ok(completion_id as u32),
            (None, Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (Some(_), Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (None, None) => Err(Error::Protocol(
                "Unknown error completing recipe".to_string(),
            )),
        }
    }
}
