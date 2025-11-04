use crate::models::Ingredient;
use rust_decimal::Decimal;
use sqlx::{Error, MySqlPool, Row, mysql::MySqlRow};

pub struct IngredientRepository {
    pool: MySqlPool,
}

impl IngredientRepository {
    pub fn new(pool: MySqlPool) -> Self {
        Self { pool }
    }

    fn get_ingredient(row: &MySqlRow) -> Ingredient {
        Ingredient {
            ingredient_id: row.get(0),
            name: row.get(1),
            carbohydrates: row.get(2),
            proteins: row.get(3),
            fats: row.get(4),
            fibers: row.get(5),
            calories: row.get(6),
            price: row.get(7),
            weight: row.get(8),
            measurement_unit: row.get(9),
        }
    }

    pub async fn get_all(
        &self,
        page: i32,
        page_size: i32,
    ) -> Result<(Vec<Ingredient>, i64), Error> {
        // Appel de la procédure stockée avec pagination
        let results = sqlx::query("CALL sp_get_all_ingredients(?, ?)")
            .bind(page)
            .bind(page_size)
            .fetch_all(&self.pool)
            .await?;

        // Le premier résultat contient le count total
        let total_count: i64 = if !results.is_empty() {
            results[0].get(0)
        } else {
            0
        };

        // Les résultats suivants contiennent les ingrédients
        let ingredients: Vec<Ingredient> = results
            .iter()
            .skip(1) // Sauter le premier résultat (count)
            .map(|row| Self::get_ingredient(row))
            .collect();

        Ok((ingredients, total_count))
    }

    pub async fn find_by_id(&self, ingredient_id: i32) -> Result<Option<Ingredient>, Error> {
        let ingredient = sqlx::query("CALL sp_get_ingredient(?, @p_error_message)")
            .bind(ingredient_id)
            .map(|row: MySqlRow| Self::get_ingredient(&row))
            .fetch_optional(&self.pool)
            .await?;

        Ok(ingredient)
    }

    pub async fn create(
        &self,
        name: &str,
        carbohydrates: Decimal,
        proteins: Decimal,
        fats: Decimal,
        fibers: Decimal,
        calories: Decimal,
        price: Decimal,
        weight: Decimal,
        measurement_unit: &str,
        created_by_user_id: i32,
    ) -> Result<i32, Error> {
        // Acquérir UNE connexion du pool
        let mut conn = self.pool.acquire().await?;

        // Appeler la procédure sur CETTE connexion
        sqlx::query(
            "CALL sp_create_ingredient(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @p_ingredient_id, @p_error_message)"
        )
        .bind(name)
        .bind(carbohydrates)
        .bind(proteins)
        .bind(fats)
        .bind(fibers)
        .bind(calories)
        .bind(price)
        .bind(weight)
        .bind(measurement_unit)
        .bind(created_by_user_id)
        .execute(&mut *conn)
        .await?;

        // Récupérer les variables sur LA MÊME connexion
        let result: (Option<i32>, Option<String>) =
            sqlx::query("SELECT @p_ingredient_id, @p_error_message")
                .map(|row: MySqlRow| (row.get(0), row.get(1)))
                .fetch_one(&mut *conn)
                .await?;

        match result {
            (Some(ingredient_id), None) => Ok(ingredient_id),
            (None, Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (Some(_), Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (None, None) => Err(Error::Protocol(
                "Unknown error during ingredient creation".to_string(),
            )),
        }
    }

    pub async fn update(
        &self,
        ingredient_id: i32,
        name: &str,
        carbohydrates: Decimal,
        proteins: Decimal,
        fats: Decimal,
        fibers: Decimal,
        calories: Decimal,
        price: Decimal,
        weight: Decimal,
        measurement_unit: &str,
        updated_by_user_id: i32,
    ) -> Result<(), Error> {
        // Acquérir UNE connexion du pool
        let mut conn = self.pool.acquire().await?;

        // Appeler la procédure sur CETTE connexion
        sqlx::query("CALL sp_update_ingredient(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @p_error_message)")
            .bind(ingredient_id)
            .bind(name)
            .bind(carbohydrates)
            .bind(proteins)
            .bind(fats)
            .bind(fibers)
            .bind(calories)
            .bind(price)
            .bind(weight)
            .bind(measurement_unit)
            .bind(updated_by_user_id)
            .execute(&mut *conn)
            .await?;

        // Récupérer la variable d'erreur sur LA MÊME connexion
        let error_message: Option<String> = sqlx::query("SELECT @p_error_message")
            .map(|row: MySqlRow| row.get(0))
            .fetch_one(&mut *conn)
            .await?;

        match error_message {
            None => Ok(()),
            Some(error_msg) => Err(Error::Protocol(error_msg)),
        }
    }

    pub async fn delete(&self, ingredient_id: i32, deleted_by_user_id: i32) -> Result<(), Error> {
        // Acquérir UNE connexion du pool
        let mut conn = self.pool.acquire().await?;

        // Appeler la procédure sur CETTE connexion
        sqlx::query("CALL sp_delete_ingredient(?, ?, @p_error_message)")
            .bind(ingredient_id)
            .bind(deleted_by_user_id)
            .execute(&mut *conn)
            .await?;

        // Récupérer la variable d'erreur sur LA MÊME connexion
        let error_message: Option<String> = sqlx::query("SELECT @p_error_message")
            .map(|row: MySqlRow| row.get(0))
            .fetch_one(&mut *conn)
            .await?;

        match error_message {
            None => Ok(()),
            Some(error_msg) => Err(Error::Protocol(error_msg)),
        }
    }
}
