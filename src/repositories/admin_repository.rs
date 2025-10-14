use sqlx::{MySqlPool, Error, Row};

pub struct AdminRepository {
    pool: MySqlPool,
}

impl AdminRepository {
    pub fn new(pool: MySqlPool) -> Self {
        Self { pool }
    }
    pub async fn create(&self, id: &str, first_name: &str, last_name: &str, email: &str, password_hash: &str) -> Result<(), Error> {
        let result = sqlx::query(
            "CALL sp_create_admin(?, ?, ?, ?)"
        )
        .bind(id)
        .bind(first_name)
        .bind(last_name)
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