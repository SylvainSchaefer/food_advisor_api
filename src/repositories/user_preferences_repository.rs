use crate::models::{AllUserPreferences, UserCategoryPreference, UserIngredientPreference};
use chrono::Utc;
use sqlx::{Error, MySqlPool, Row, mysql::MySqlRow};

pub struct UserPreferencesRepository {
    pool: MySqlPool,
}

impl UserPreferencesRepository {
    pub fn new(pool: MySqlPool) -> Self {
        Self { pool }
    }

    fn get_category_preference(row: &MySqlRow) -> UserCategoryPreference {
        // Convertir TIMESTAMP en NaiveDateTime
        let created_at: chrono::DateTime<Utc> = row.get(5);
        UserCategoryPreference {
            user_id: row.get(0),
            category_id: row.get(1),
            category_name: row.get(2),
            category_description: row.get(3),
            preference_type: row.get(4),
            created_at: created_at.naive_utc(),
        }
    }

    fn get_ingredient_preference(row: &MySqlRow) -> UserIngredientPreference {
        // Convertir TIMESTAMP en NaiveDateTime
        let created_at: chrono::DateTime<Utc> = row.get(4);
        UserIngredientPreference {
            user_id: row.get(0),
            ingredient_id: row.get(1),
            ingredient_name: row.get(2),
            preference_type: row.get(3),
            created_at: created_at.naive_utc(),
        }
    }

    // =====================================================
    // PRÉFÉRENCES DE CATÉGORIES
    // =====================================================

    pub async fn set_category_preference(
        &self,
        user_id: i32,
        category_id: i32,
        preference_type: &str,
    ) -> Result<(), Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_set_category_preference(?, ?, ?, @p_error_message)")
            .bind(user_id)
            .bind(category_id)
            .bind(preference_type)
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

    pub async fn remove_category_preference(
        &self,
        user_id: i32,
        category_id: i32,
    ) -> Result<(), Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_remove_category_preference(?, ?, @p_error_message)")
            .bind(user_id)
            .bind(category_id)
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

    pub async fn get_user_category_preferences(
        &self,
        user_id: i32,
    ) -> Result<Vec<UserCategoryPreference>, Error> {
        let preferences = sqlx::query("CALL sp_get_user_category_preferences(?, @p_error_message)")
            .bind(user_id)
            .map(|row: MySqlRow| Self::get_category_preference(&row))
            .fetch_all(&self.pool)
            .await?;

        Ok(preferences)
    }

    // =====================================================
    // PRÉFÉRENCES D'INGRÉDIENTS
    // =====================================================

    pub async fn set_ingredient_preference(
        &self,
        user_id: i32,
        ingredient_id: i32,
        preference_type: &str,
    ) -> Result<(), Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_set_ingredient_preference(?, ?, ?, @p_error_message)")
            .bind(user_id)
            .bind(ingredient_id)
            .bind(preference_type)
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

    pub async fn remove_ingredient_preference(
        &self,
        user_id: i32,
        ingredient_id: i32,
    ) -> Result<(), Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query("CALL sp_remove_ingredient_preference(?, ?, @p_error_message)")
            .bind(user_id)
            .bind(ingredient_id)
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

    pub async fn get_user_ingredient_preferences(
        &self,
        user_id: i32,
    ) -> Result<Vec<UserIngredientPreference>, Error> {
        let preferences =
            sqlx::query("CALL sp_get_user_ingredient_preferences(?, @p_error_message)")
                .bind(user_id)
                .map(|row: MySqlRow| Self::get_ingredient_preference(&row))
                .fetch_all(&self.pool)
                .await?;

        Ok(preferences)
    }

    // =====================================================
    // TOUTES LES PRÉFÉRENCES
    // =====================================================

    pub async fn get_all_user_preferences(
        &self,
        user_id: i32,
    ) -> Result<AllUserPreferences, Error> {
        let mut results = sqlx::query("CALL sp_get_all_user_preferences(?, @p_error_message)")
            .bind(user_id)
            .fetch_all(&self.pool)
            .await?;

        // Le premier ensemble de résultats contient les préférences de catégories
        let mut category_preferences = Vec::new();
        let mut ingredient_preferences = Vec::new();
        let mut in_categories = true;

        for row in results.iter() {
            // Détecter le changement de résultat set
            // Si on a 6 colonnes, ce sont les catégories
            // Si on a 5 colonnes, ce sont les ingrédients
            if row.len() == 6 && in_categories {
                category_preferences.push(Self::get_category_preference(row));
            } else {
                in_categories = false;
                if row.len() == 5 {
                    ingredient_preferences.push(Self::get_ingredient_preference(row));
                }
            }
        }

        Ok(AllUserPreferences {
            category_preferences,
            ingredient_preferences,
        })
    }
}
