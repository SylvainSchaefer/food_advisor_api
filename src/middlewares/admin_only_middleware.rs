use actix_web::HttpMessage;
use actix_web::http::header::ContentType;
use actix_web::{
    Error, HttpResponse,
    body::EitherBody,
    dev::{Service, ServiceRequest, ServiceResponse, Transform, forward_ready},
};
use futures_util::future::LocalBoxFuture;
use std::future::{Ready, ready};

// Middleware struct
pub struct AdminOnly;

impl<S, B> Transform<S, ServiceRequest> for AdminOnly
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B>>;
    type Error = Error;
    type InitError = ();
    type Transform = AdminOnlyMiddleware<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(AdminOnlyMiddleware { service }))
    }
}

pub struct AdminOnlyMiddleware<S> {
    service: S,
}

impl<S, B> Service<ServiceRequest> for AdminOnlyMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B>>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        // Récupérer les TokenClaims depuis les extensions (ajoutés par le middleware auth)
        let extensions = req.extensions();
        let claims = extensions.get::<crate::models::TokenClaims>().cloned();
        drop(extensions); // Libérer le borrow

        // Vérifier si l'utilisateur est admin
        match claims {
            Some(claims) if claims.is_admin() => {
                // L'utilisateur est admin, on continue
                let fut = self.service.call(req);
                Box::pin(async move {
                    let res = fut.await?;
                    Ok(res.map_into_left_body())
                })
            }
            _ => {
                // Pas admin
                let (request, _) = req.into_parts();
                let response = HttpResponse::Forbidden()
                    .content_type(ContentType::json())
                    .json(serde_json::json!({
                        "error": "Admin access required"
                    }));

                Box::pin(async move {
                    Ok(ServiceResponse::new(request, response).map_into_right_body())
                })
            }
        }
    }
}
