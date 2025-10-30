use crate::models::{Gender, Role, User};
use chrono::{NaiveDate, Utc};
use sqlx::{Error, MySqlPool, Row, mysql::MySqlRow};

pub struct UserRepository {
    pool: MySqlPool,
}

impl UserRepository {
    pub fn new(pool: MySqlPool) -> Self {
        Self { pool }
    }

    fn get_user(row: MySqlRow) -> User {
        let gender_str: String = row.get(3);
        let role_str: String = row.get(6);

        // Convertir TIMESTAMP en NaiveDateTime
        let created_at: chrono::DateTime<Utc> = row.get(11);
        let updated_at: chrono::DateTime<Utc> = row.get(12);

        User {
            user_id: row.get(0),
            first_name: row.get(1),
            last_name: row.get(2),
            gender: match gender_str.as_str() {
                "Male" => Gender::Male,
                "Female" => Gender::Female,
                "Other" => Gender::Other,
                _ => Gender::Other,
            },
            password_hash: row.get(4),
            email: row.get(5),
            role: match role_str.as_str() {
                "Administrator" => Role::Administrator,
                "Regular" => Role::Regular,
                _ => Role::Regular,
            },
            country: row.get(7),
            city: row.get(8),
            is_active: row.get(9),
            birth_date: row.get(10),
            created_at: created_at.naive_utc(),
            updated_at: updated_at.naive_utc(),
        }
    }

    pub async fn find_by_email(&self, email: &str) -> Result<Option<User>, Error> {
        let user = sqlx::query("CALL sp_get_user_by_email(?)")
            .bind(email)
            .map(|row: MySqlRow| Self::get_user(row))
            .fetch_optional(&self.pool)
            .await?;

        Ok(user)
    }

    pub async fn find_by_id(&self, user_id: u32) -> Result<Option<User>, Error> {
        let user = sqlx::query(
            "SELECT user_id, first_name, last_name, gender, password_hash, email, 
                    role, country, city, is_active, birth_date, created_at, updated_at
             FROM users 
             WHERE user_id = ? AND is_active = TRUE
             LIMIT 1",
        )
        .bind(user_id)
        .map(|row: MySqlRow| Self::get_user(row))
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    pub async fn get_all(&self) -> Result<Vec<User>, Error> {
        let users = sqlx::query(
            "SELECT user_id, first_name, last_name, gender, password_hash, email, 
                    role, country, city, is_active, birth_date, created_at, updated_at
             FROM users 
             ORDER BY created_at DESC",
        )
        .map(|row: MySqlRow| Self::get_user(row))
        .fetch_all(&self.pool)
        .await?;

        Ok(users)
    }
    pub async fn create(
        &self,
        first_name: &str,
        last_name: &str,
        gender: &str,
        password_hash: &str,
        email: &str,
        role: &str,
        country: Option<&str>,
        city: Option<&str>,
        birth_date: Option<NaiveDate>,
    ) -> Result<u32, Error> {
        // Acquérir UNE connexion du pool
        let mut conn = self.pool.acquire().await?;

        // Appeler la procédure sur CETTE connexion
        sqlx::query("CALL sp_create_user(?, ?, ?, ?, ?, ?, ?, ?, ?, @user_id, @error_msg)")
            .bind(first_name)
            .bind(last_name)
            .bind(gender)
            .bind(password_hash)
            .bind(email)
            .bind(role)
            .bind(country)
            .bind(city)
            .bind(birth_date)
            .execute(&mut *conn) // ← Sur la connexion acquise
            .await?;

        // Récupérer les variables sur LA MÊME connexion
        let result: (Option<i64>, Option<String>) = sqlx::query("SELECT @user_id, @error_msg")
            .map(|row: MySqlRow| (row.get(0), row.get(1)))
            .fetch_one(&mut *conn) // ← Sur la même connexion
            .await?;

        match result {
            (Some(user_id), None) => Ok(user_id as u32),
            (None, Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (Some(_), Some(error_msg)) => Err(Error::Protocol(error_msg)),
            (None, None) => Err(Error::Protocol(
                "Unknown error during user creation".to_string(),
            )),
        }
    }
}
