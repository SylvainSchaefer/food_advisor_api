use sqlx::{MySqlPool, Error, Row, mysql::MySqlRow};
use crate::models::{Gender, Role, User};

pub struct UserRepository {
    pool: MySqlPool,
}

impl UserRepository {
    pub fn new(pool: MySqlPool) -> Self {
        Self { pool }
    }

    fn get_user(row: MySqlRow) -> User
    {
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
                "administrator" => Role::Administrator,
                _ => Role::User
            },
            dietary_regimen_id: row.get(11),
            active: row.get(12),
            created_at: row.get(13),
            updated_at: row.get(14),
        } 
    }

    pub async fn find_by_email(&self, email: &str) -> Result<Option<User>, Error> {
        let result = sqlx::query("CALL sp_get_user_by_email(?)")
            .bind(email)
            .map(|row: MySqlRow| {
                Self::get_user(row)
            })
            .fetch_optional(&self.pool)
            .await?;
        
        Ok(result)
    }

    pub async fn find_by_id(&self, email: &str) -> Result<Option<User>, Error> {
        let user = sqlx::query("CALL sp_get_user_by_id(?)")
            .bind(email)
            .map(|row: MySqlRow| {
                Self::get_user(row)
            })
            .fetch_optional(&self.pool)
            .await?;
        
        Ok(user)
    }
 
    pub async fn create(&self, email: &str, password_hash: &str, first_name: &str, last_name : &str) -> Result<i32, Error> {
        let result: (u64,) = sqlx::query_as(
            "CALL sp_create_user(?, ?, ?, ?)"
        )
        .bind(email)
        .bind(password_hash)
        .bind(last_name)
        .bind(first_name)
        .fetch_one(&self.pool)
        .await?;

        Ok(result.0 as i32)
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