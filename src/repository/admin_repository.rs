use sqlx::{MySqlPool, Error, Row};
use crate::models::Admin;

pub struct AdminRepository {
    pool: MySqlPool,
}

impl AdminRepository {
    pub fn new(pool: MySqlPool) -> Self {
        Self { pool }
    }

    pub async fn find_by_email(&self, email: &str) -> Result<Option<Admin>, Error> {
        let result = sqlx::query(
            "CALL sp_get_admin_by_email(?)"
        )
        .bind(email)
        .fetch_all(&self.pool)
        .await;

        match result {
            Ok(rows) => {
                if rows.is_empty() {
                    log::info!("No admin found for email: {}", email);
                    return Ok(None);
                }
                
                let row = &rows[0];
                
                let admin = Admin {
                    id: row.try_get(0)?,              // ordinal: 0
                    username: row.try_get(1)?,        // ordinal: 1
                    email: row.try_get(2)?,           // ordinal: 2
                    password_hash: row.try_get(3)?,   // ordinal: 3
                    is_active: row.try_get(4)?,       // ordinal: 4
                    created_at: row.try_get(5)?,      // ordinal: 5
                    updated_at: row.try_get(6)?,      // ordinal: 6
                };
                Ok(Some(admin))
            }
            Err(e) => {
                log::error!("Error calling sp_get_admin_by_email: {:?}", e);
                Err(e)
            }
        }
    }

    pub async fn find_by_id(&self, id: &str) -> Result<Option<Admin>, Error> {
        let result = sqlx::query(
            "CALL sp_get_admin_by_id(?)"
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
                let admin = Admin {
                    id: row.try_get(0)?,
                    username: row.try_get(1)?,
                    email: row.try_get(2)?,
                    password_hash: row.try_get(3)?,
                    is_active: row.try_get(4)?,
                    created_at: row.try_get(5)?,
                    updated_at: row.try_get(6)?,
                };
                Ok(Some(admin))
            }
            Err(e) => {
                log::error!("Error calling sp_get_admin_by_id: {:?}", e);
                Err(e)
            }
        }
    }

    pub async fn create(&self, id: &str, username: &str, email: &str, password_hash: &str) -> Result<(), Error> {
        let result = sqlx::query(
            "CALL sp_create_admin(?, ?, ?, ?)"
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
                log::error!("Error calling sp_create_admin: {:?}", e);
                Err(e)
            }
        }
    }
}