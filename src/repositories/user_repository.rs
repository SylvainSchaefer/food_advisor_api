use sqlx::{MySqlPool, Error, Row, mysql::MySqlRow};
use crate::models::{Gender, Role, User};

pub struct UserRepository {
    pool: MySqlPool,
}

impl UserRepository {
    pub fn new(pool: MySqlPool) -> Self {
        Self { pool }
    }

    pub async fn find_by_email(&self, email: &str) -> Result<Option<User>, Error> {
    let result = sqlx::query("CALL sp_get_user_by_email(?)")
        .bind(email)
        .map(|row: MySqlRow| {
            // Lire les ENUMs comme des Strings
            let gender_str: String = row.get(6);
            let role_str: String = row.get(10);
            
            User {
                id: row.get(0),
                email: row.get(1),
                password_hash: row.get(2),
                last_name: row.get(3),
                first_name: row.get(4),
                date_of_birth: row.get(5),
                gender: match gender_str.as_str() {
                    "M" => Gender::M,
                    "F" => Gender::F,
                    _ => Gender::Other,
                },
                city: row.get(7),
                postal_code: row.get(8),
                country: row.get(9),
                role: match role_str.as_str() {
                    "user" => Role::User,
                    _ => Role::Administrator,
                },
                dietary_regimen_id: row.get(11),
                active: row.get(12),
                created_at: row.get(13),
                updated_at: row.get(14),
            }
        })
        .fetch_optional(&self.pool)
        .await?;
    
    Ok(result)
}

    pub async fn find_by_id(&self, email: &str) -> Result<Option<User>, Error> {
        let user = sqlx::query_as::<_, User>(
            "CALL sp_get_user_by_id(?)"
        )
        .bind(email)
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(user)
    }
 
    pub async fn create(&self, username: &str, email: &str, password_hash: &str) -> Result<i32, Error> {
        let result = sqlx::query(
            "CALL sp_create_user(?, ?, ?, ?)"
        )
        .bind(username)
        .bind(email)
        .bind(password_hash)
        .execute(&self.pool)
        .await?;

        Ok(result.last_insert_id() as i32)
    }

    pub async fn get_all(&self) -> Result<Vec<User>, Error> {
    let users = sqlx::query_as::<_, User>(
        "CALL sp_get_all_users()"
    )
    .fetch_all(&self.pool)
    .await?;
    
    Ok(users)
}
}