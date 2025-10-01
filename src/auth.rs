use actix_web::{dev::ServiceRequest, Error, HttpMessage};
use actix_web_httpauth::extractors::bearer::BearerAuth;
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use bcrypt::{hash, verify, DEFAULT_COST};
use chrono::Utc;
use crate::models::Claims;

pub fn hash_password(password: &str) -> Result<String, bcrypt::BcryptError> {
    hash(password, DEFAULT_COST)
}

pub fn verify_password(password: &str, hash: &str) -> Result<bool, bcrypt::BcryptError> {
    println!("{}", password);
    println!("{}", hash);
    verify(password, hash)
}

pub fn create_jwt(user_id: &str, email: &str, is_admin: bool, secret: &str, expiration: i64) -> Result<String, jsonwebtoken::errors::Error> {
    let expiration_time = Utc::now()
        .checked_add_signed(chrono::Duration::seconds(expiration))
        .expect("valid timestamp")
        .timestamp();

    let claims = Claims {
        sub: user_id.to_owned(),
        email: email.to_owned(),
        is_admin,
        exp: expiration_time as usize,
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_ref()),
    )
}

pub fn decode_jwt(token: &str, secret: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_ref()),
        &Validation::default(),
    )?;
    Ok(token_data.claims)
}

pub async fn validator(
    req: ServiceRequest,
    credentials: BearerAuth,
) -> Result<ServiceRequest, (Error, ServiceRequest)> {
    let secret = std::env::var("JWT_SECRET").expect("JWT_SECRET must be set");
    
    match decode_jwt(credentials.token(), &secret) {
        Ok(claims) => {
            req.extensions_mut().insert(claims);
            Ok(req)
        }
        Err(_) => Err((actix_web::error::ErrorUnauthorized("Invalid token"), req)),
    }
}