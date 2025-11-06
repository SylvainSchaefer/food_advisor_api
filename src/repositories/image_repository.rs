use crate::models::{EntityType, Image, Role};
use chrono::Utc;
use sqlx::{Error, MySqlPool, Row, mysql::MySqlRow};

pub struct ImageRepository {
    pool: MySqlPool,
}

impl ImageRepository {
    pub fn new(pool: MySqlPool) -> Self {
        Self { pool }
    }

    fn map_image(row: &MySqlRow) -> Image {
        let entity_type_str: String = row.get(1);
        let created_at: chrono::DateTime<Utc> = row.get(12);
        let updated_at: chrono::DateTime<Utc> = row.get(13);

        Image {
            image_id: row.get(0),
            entity_type: match entity_type_str.as_str() {
                "recipe" => EntityType::Recipe,
                "ingredient" => EntityType::Ingredient,
                _ => EntityType::Recipe,
            },
            entity_id: row.get(2),
            image_data: row.get(3),
            image_name: row.get(4),
            image_type: row.get(5),
            image_size: row.get(6),
            width: row.get(7),
            height: row.get(8),
            is_primary: row.get(9),
            alt_text: row.get(10),
            uploaded_by_user_id: row.get(11),
            created_at: created_at.naive_utc(),
            updated_at: updated_at.naive_utc(),
        }
    }

    pub async fn get_recipe_image(&self, recipe_id: u32) -> Result<Option<Image>, Error> {
        let image = sqlx::query("CALL sp_get_recipe_image(?)")
            .bind(recipe_id)
            .map(|row: MySqlRow| Self::map_image(&row))
            .fetch_optional(&self.pool)
            .await?;

        Ok(image)
    }

    pub async fn get_ingredient_image(&self, ingredient_id: u32) -> Result<Option<Image>, Error> {
        let image = sqlx::query("CALL sp_get_ingredient_image(?)")
            .bind(ingredient_id)
            .map(|row: MySqlRow| Self::map_image(&row))
            .fetch_optional(&self.pool)
            .await?;

        Ok(image)
    }

    pub async fn add_recipe_image(
        &self,
        recipe_id: u32,
        image_data: Vec<u8>,
        image_name: String,
        image_type: String,
        image_size: u32,
        width: Option<u32>,
        height: Option<u32>,
        is_primary: bool,
        alt_text: Option<String>,
        uploaded_by_user_id: u32,
        user_role: &str,
    ) -> Result<u32, Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query(
            "CALL sp_add_recipe_image(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @image_id, @error_msg)",
        )
        .bind(recipe_id)
        .bind(&image_data)
        .bind(&image_name)
        .bind(&image_type)
        .bind(image_size)
        .bind(width)
        .bind(height)
        .bind(is_primary)
        .bind(&alt_text)
        .bind(uploaded_by_user_id)
        .bind(user_role)
        .execute(&mut *conn)
        .await?;

        let result: (Option<u64>, Option<String>) = sqlx::query("SELECT @image_id, @error_msg")
            .map(|row: MySqlRow| (row.get(0), row.get(1)))
            .fetch_one(&mut *conn)
            .await?;

        match result {
            (Some(image_id), None) => Ok(image_id as u32),
            (None, Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (Some(_), Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (None, None) => Err(Error::Protocol(
                "Unknown error during image creation".to_string(),
            )),
        }
    }

    pub async fn add_ingredient_image(
        &self,
        ingredient_id: u32,
        image_data: Vec<u8>,
        image_name: String,
        image_type: String,
        image_size: u32,
        width: Option<u32>,
        height: Option<u32>,
        is_primary: bool,
        alt_text: Option<String>,
        uploaded_by_user_id: u32,
        user_role: &str,
    ) -> Result<u32, Error> {
        let mut conn = self.pool.acquire().await?;

        sqlx::query(
            "CALL sp_add_ingredient_image(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @image_id, @error_msg)",
        )
        .bind(ingredient_id)
        .bind(&image_data)
        .bind(&image_name)
        .bind(&image_type)
        .bind(image_size)
        .bind(width)
        .bind(height)
        .bind(is_primary)
        .bind(&alt_text)
        .bind(uploaded_by_user_id)
        .bind(user_role)
        .execute(&mut *conn)
        .await?;

        let result: (Option<u64>, Option<String>) = sqlx::query("SELECT @image_id, @error_msg")
            .map(|row: MySqlRow| (row.get(0), row.get(1)))
            .fetch_one(&mut *conn)
            .await?;

        match result {
            (Some(image_id), None) => Ok(image_id as u32),
            (None, Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (Some(_), Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (None, None) => Err(Error::Protocol(
                "Unknown error during image creation".to_string(),
            )),
        }
    }
}
