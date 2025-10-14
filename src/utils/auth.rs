use actix_web::{dev::ServiceRequest, Error, HttpMessage};
use actix_web_httpauth::extractors::bearer::BearerAuth;
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use chrono::Utc;
use crate::models::{Claims, Role};

/// Crée un token JWT pour un utilisateur
pub fn create_jwt(
    user_id: i32,
    email: &str,
    role: Role,
    secret: &str,
    expiration: i64,
) -> Result<String, jsonwebtoken::errors::Error> {
    let expiration_time = Utc::now()
        .checked_add_signed(chrono::Duration::seconds(expiration))
        .expect("valid timestamp")
        .timestamp();

    let claims = Claims {
        sub: user_id.to_string(),
        email: email.to_owned(),
        role,
        exp: expiration_time as usize,
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_ref()),
    )
}

/// Décode et valide un token JWT
pub fn decode_jwt(token: &str, secret: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_ref()),
        &Validation::default(),
    )?;

    Ok(token_data.claims)
}

/// Validator pour actix-web-httpauth
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

/// Middleware helper pour vérifier si l'utilisateur est administrateur
pub fn is_admin(claims: &Claims) -> bool {
    claims.role == Role::Administrator
}

/// Middleware helper pour extraire les claims depuis la requête
pub fn get_claims_from_request(req: &ServiceRequest) -> Option<Claims> {
    req.extensions().get::<Claims>().cloned()
}