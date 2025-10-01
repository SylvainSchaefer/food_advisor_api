mod models;
mod handlers;
mod auth;
mod repository;

use actix_web::{web, App, HttpServer, middleware};
use actix_web_httpauth::middleware::HttpAuthentication;
use actix_cors::Cors;
use sqlx::mysql::MySqlPoolOptions;
use dotenv::dotenv;
use std::time::Duration;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv().ok();
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    
    // Récupérer l'hôte et le port depuis les variables d'environnement
    let host = std::env::var("SERVER_HOST").unwrap_or_else(|_| "0.0.0.0".to_string());
    let port = std::env::var("SERVER_PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .expect("SERVER_PORT must be a valid port number");

    println!("🔌 Connecting to database...");
    
    // Ajouter des tentatives de connexion avec délai pour attendre MySQL
    let mut retries = 5;
    let mut pool = None;
    
    while retries > 0 {
        match MySqlPoolOptions::new()
            .max_connections(5)
            .acquire_timeout(Duration::from_secs(10))
            .connect(&database_url)
            .await
        {
            Ok(p) => {
                pool = Some(p);
                break;
            }
            Err(e) => {
                println!("⏳ Database connection failed, retrying... ({} attempts left)", retries);
                println!("   Error: {}", e);
                retries -= 1;
                if retries > 0 {
                    tokio::time::sleep(Duration::from_secs(5)).await;
                }
            }
        }
    }
    
    let pool = pool.expect("Failed to connect to database after multiple attempts");
    
    println!("✅ Database connection established");
    
    // Test de la connexion
    sqlx::query("SELECT 1")
        .fetch_one(&pool)
        .await
        .expect("Failed to execute test query");
    
    println!("✅ Database is responding");
    
    let bind_address = format!("{}:{}", host, port);
    println!("\n🚀 Server starting on http://{}", bind_address);
    println!("📝 API Documentation: http://{}/api", bind_address);
    println!("🔑 JWT Secret configured: {}", 
        if std::env::var("JWT_SECRET").is_ok() { "✅" } else { "❌" }
    );

    HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        let auth = HttpAuthentication::bearer(auth::validator);

        App::new()
            .app_data(web::Data::new(pool.clone()))
            .wrap(middleware::Logger::default())
            .wrap(cors)
            // Route de santé pour vérifier que l'API fonctionne
            .route("/health", web::get().to(health_check))
            .service(
                web::scope("/api")
                    .service(
                        web::scope("/auth")
                            .route("/register", web::post().to(handlers::register))
                            .route("/login", web::post().to(handlers::login))
                    )
                    .service(
                        web::scope("/users")
                            .wrap(auth.clone())
                            .route("/profile", web::get().to(handlers::get_profile))
                            .route("/all", web::get().to(handlers::get_all_users))
                            .route("/{id}/deactivate", web::put().to(handlers::deactivate_user))
                    )
                    .service(
                        web::scope("/admin")
                            .wrap(auth)
                            .route("/create", web::post().to(handlers::create_admin))
                    )
            )
    })
    .bind(&bind_address)?
    .run()
    .await
}

// Endpoint de santé
async fn health_check() -> actix_web::Result<impl actix_web::Responder> {
    Ok(actix_web::HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "food_advisor_api",
        "timestamp": chrono::Utc::now().to_rfc3339()
    })))
}