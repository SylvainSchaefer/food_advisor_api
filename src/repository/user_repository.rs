use sqlx::{MySqlPool, Error, Row};
use crate::models::User;

pub struct UserRepository {
    pool: MySqlPool,
}

impl UserRepository {
    pub fn new(pool: MySqlPool) -> Self {
        Self { pool }
    }

    pub async fn find_by_email(&self, email: &str) -> Result<Option<User>, Error> {
        let result = sqlx::query(
            "CALL sp_get_user_by_email(?)"
        )
        .bind(email)
        .fetch_all(&self.pool)
        .await;

        match result {
            Ok(rows) => {
                if rows.is_empty() {
                    return Ok(None);
                }
                
                let row = &rows[0];
                let user = User {
                    id: row.try_get(0)?,
                    username: row.try_get(1)?,
                    email: row.try_get(2)?,
                    password_hash: row.try_get(3)?,
                    is_active: row.try_get(4)?,
                    created_at: row.try_get(5)?,
                    updated_at: row.try_get(6)?,
                };
                Ok(Some(user))
            }
            Err(e) => {
                log::error!("Error calling sp_get_user_by_email: {:?}", e);
                Err(e)
            }
        }
    }

    pub async fn find_by_id(&self, id: &str) -> Result<Option<User>, Error> {
        let result = sqlx::query(
            "CALL sp_get_user_by_id(?)"
        )
        .bind(id)
        .fetch_all(&self.pool)
        .await;

        match result {
            Ok(rows) => {
                if rows.is_empty() {
                    return Ok(None);
                }
                
                let row = &rows[0];
                let user = User {
                    id: row.try_get(0)?,
                    username: row.try_get(1)?,
                    email: row.try_get(2)?,
                    password_hash: row.try_get(3)?,
                    is_active: row.try_get(4)?,
                    created_at: row.try_get(5)?,
                    updated_at: row.try_get(6)?,
                };
                Ok(Some(user))
            }
            Err(e) => {
                log::error!("Error calling sp_get_user_by_id: {:?}", e);
                Err(e)
            }
        }
    }

    pub async fn create(&self, id: &str, username: &str, email: &str, password_hash: &str) -> Result<(), Error> {
        let result = sqlx::query(
            "CALL sp_create_user(?, ?, ?, ?)"
        )
        .bind(id)
        .bind(username)
        .bind(email)
        .bind(password_hash)
        .execute(&self.pool)
        .await;

        match result {
            Ok(_) => Ok(()),
            Err(e) => {
                log::error!("Error calling sp_create_user: {:?}", e);
                Err(e)
            }
        }
    }

    pub async fn get_all(&self) -> Result<Vec<User>, Error> {
        let result = sqlx::query(
            "CALL sp_get_all_users()"
        )
        .fetch_all(&self.pool)
        .await;

        match result {
            Ok(rows) => {
                let users = rows.iter()
                    .filter_map(|row| {
                        Some(User {
                            id: row.try_get(0).ok()?,
                            username: row.try_get(1).ok()?,
                            email: row.try_get(2).ok()?,
                            password_hash: row.try_get(3).ok()?,
                            is_active: row.try_get(4).ok()?,
                            created_at: row.try_get(5).ok()?,
                            updated_at: row.try_get(6).ok()?,
                        })
                    })
                    .collect();
                Ok(users)
            }
            Err(e) => {
                log::error!("Error calling sp_get_all_users: {:?}", e);
                Err(e)
            }
        }
    }

    pub async fn deactivate(&self, id: &str) -> Result<(), Error> {
        let result = sqlx::query(
            "CALL sp_deactivate_user(?)"
        )
        .bind(id)
        .execute(&self.pool)
        .await;

        match result {
            Ok(_) => Ok(()),
            Err(e) => {
                log::error!("Error calling sp_deactivate_user: {:?}", e);
                Err(e)
            }
        }
    }
}