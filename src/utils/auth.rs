use crate::models::{Role, TokenClaims, User};
use actix_web::{Error, HttpMessage, dev::ServiceRequest};
use actix_web_httpauth::extractors::bearer::BearerAuth;
use chrono::Utc;
use jsonwebtoken::{DecodingKey, EncodingKey, Header, Validation, decode, encode};
impl TokenClaims {
    /// Crée des claims à partir d'un User
    pub fn from_user(user: &User, expiration_seconds: i64) -> Self {
        let expiration_time = Utc::now()
            .checked_add_signed(chrono::Duration::seconds(expiration_seconds))
            .expect("valid timestamp")
            .timestamp();

        Self {
            sub: user.user_id.to_string(),
            email: user.email.clone(),
            role: user.role.clone(),
            exp: expiration_time as usize,
        }
    }

    /// Vérifie si l'utilisateur est administrateur
    pub fn is_admin(&self) -> bool {
        matches!(self.role, Role::Administrator)
    }
}

/// Crée un token JWT pour un utilisateur
pub fn create_jwt(
    user: &User,
    secret: &str,
    expiration_seconds: i64,
) -> Result<String, jsonwebtoken::errors::Error> {
    let claims = TokenClaims::from_user(user, expiration_seconds);

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_ref()),
    )
}

/// Décode et valide un token JWT
pub fn decode_jwt(token: &str, secret: &str) -> Result<TokenClaims, jsonwebtoken::errors::Error> {
    let token_data = decode::<TokenClaims>(
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
