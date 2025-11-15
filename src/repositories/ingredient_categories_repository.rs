use crate::{
    models::{CategoryWithIngredients, Ingredient, IngredientCategory},
    repositories::{IngredientRepository, ingredient_repository},
};
use chrono::Utc;
use sqlx::{Error, MySqlPool, Row, mysql::MySqlRow};

pub struct IngredientCategoryRepository {
    pool: MySqlPool,
}

impl IngredientCategoryRepository {
    pub fn new(pool: MySqlPool) -> Self {
        Self { pool }
    }

    fn get_category(row: &MySqlRow) -> IngredientCategory {
        // Convertir TIMESTAMP en NaiveDateTime
        let created_at: chrono::DateTime<Utc> = row.get(3);
        let updated_at: chrono::DateTime<Utc> = row.get(4);

        IngredientCategory {
            category_id: row.get(0),
            name: row.get(1),
            description: row.get(2),
            created_at: created_at.naive_utc(),
            updated_at: updated_at.naive_utc(),
        }
    }

    // =====================================================
    // GESTION DES CATÉGORIES
    // =====================================================

    pub async fn get_all_categories(&self) -> Result<Vec<IngredientCategory>, Error> {
        let categories = sqlx::query("CALL sp_get_all_categories(@p_error_message)")
            .map(|row: MySqlRow| Self::get_category(&row))
            .fetch_all(&self.pool)
            .await?;

        Ok(categories)
    }

    pub async fn find_category_by_id(
        &self,
        category_id: i32,
    ) -> Result<Option<CategoryWithIngredients>, Error> {
        let mut results = sqlx::query("CALL sp_get_category_by_id(?, @p_error_message)")
            .bind(category_id)
            .fetch_all(&self.pool)
            .await?;

        if results.is_empty() {
            return Ok(None);
        }

        // Le premier résultat contient la catégorie
        let category = Self::get_category(&results[0]);

        // Les résultats suivants contiennent les ingrédients
        let ingredients: Vec<Ingredient> = results
            .iter()
            .skip(1)
            .map(|row| IngredientRepository::get_ingredient(row))
            .collect();

        Ok(Some(CategoryWithIngredients {
            category,
            ingredients,
        }))
    }

    pub async fn create_category(
        &self,
        name: &str,
        description: Option<&str>,
        created_by_user_id: i32,
    ) -> Result<i32, Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_create_category(?, ?, ?, @p_category_id, @p_error_message)")
            .bind(name)
            .bind(description)
            .bind(created_by_user_id)
            .execute(&mut *conn)
            .await?;

        let result: (Option<i32>, Option<String>) =
            sqlx::query("SELECT @p_category_id, @p_error_message")
                .map(|row: MySqlRow| (row.get(0), row.get(1)))
                .fetch_one(&mut *conn)
                .await?;

        match result {
            (Some(category_id), None) => Ok(category_id),
            (None, Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (Some(_), Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (None, None) => Err(Error::Protocol(
                "Unknown error during category creation".to_string(),
            )),
        }
    }

    pub async fn update_category(
        &self,
        category_id: i32,
        name: &str,
        description: Option<&str>,
        updated_by_user_id: i32,
    ) -> Result<(), Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_update_category(?, ?, ?, ?, @p_error_message)")
            .bind(category_id)
            .bind(name)
            .bind(description)
            .bind(updated_by_user_id)
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

    pub async fn delete_category(
        &self,
        category_id: i32,
        deleted_by_user_id: i32,
    ) -> Result<(), Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_delete_category(?, ?, @p_error_message)")
            .bind(category_id)
            .bind(deleted_by_user_id)
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

    // =====================================================
    // GESTION DES ASSIGNATIONS
    // =====================================================

    pub async fn add_ingredient_to_category(
        &self,
        category_id: i32,
        ingredient_id: u32,
        user_id: i32,
    ) -> Result<(), Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_add_ingredient_to_category(?, ?, ?, @p_error_message)")
            .bind(category_id)
            .bind(ingredient_id)
            .bind(user_id)
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

    pub async fn remove_ingredient_from_category(
        &self,
        category_id: i32,
        ingredient_id: i32,
        user_id: i32,
    ) -> Result<(), Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_remove_ingredient_from_category(?, ?, ?, @p_error_message)")
            .bind(category_id)
            .bind(ingredient_id)
            .bind(user_id)
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

    pub async fn get_category_ingredients(
        &self,
        category_id: i32,
    ) -> Result<Vec<Ingredient>, Error> {
        let ingredients = sqlx::query("CALL sp_get_category_ingredients(?, @p_error_message)")
            .bind(category_id)
            .map(|row: MySqlRow| IngredientRepository::get_ingredient(&row))
            .fetch_all(&self.pool)
            .await?;

        Ok(ingredients)
    }
}
