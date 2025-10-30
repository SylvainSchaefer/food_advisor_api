mod handlers;
mod middlewares;
mod models;
mod repositories;
mod utils;

use actix_cors::Cors;
use actix_web::{App, HttpServer, middleware, web};
use actix_web_httpauth::middleware::HttpAuthentication;
use dotenv::dotenv;
use sqlx::mysql::MySqlPoolOptions;
use std::time::Duration;

use crate::middlewares::AdminOnly;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    println!("🚀 Starting Food Advisor API...");

    dotenv().ok();
    println!("✅ Environment variables loaded");

    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    println!("✅ Logger initialized");

    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    println!("✅ Database URL: {}", database_url);

    let host = std::env::var("SERVER_HOST").unwrap_or_else(|_| "0.0.0.0".to_string());
    let port = std::env::var("SERVER_PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .expect("SERVER_PORT must be a valid port number");

    println!("🔌 Connecting to database...");

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
                println!("✅ Database connection established");
                break;
            }
            Err(e) => {
                eprintln!(
                    "⏳ Database connection failed, retrying... ({} attempts left)",
                    retries
                );
                eprintln!("   Error: {}", e);
                retries -= 1;
                if retries > 0 {
                    tokio::time::sleep(Duration::from_secs(5)).await;
                }
            }
        }
    }

    let pool = pool.expect("Failed to connect to database after multiple attempts");

    // Test de la connexion
    match sqlx::query("SELECT 1").fetch_one(&pool).await {
        Ok(_) => println!("✅ Database is responding"),
        Err(e) => {
            eprintln!("❌ Database test query failed: {}", e);
            return Err(std::io::Error::new(
                std::io::ErrorKind::Other,
                "Database not responding",
            ));
        }
    }

    let bind_address = format!("{}:{}", host, port);
    println!("\n🚀 Server starting on http://{}", bind_address);
    println!("📝 API: http://{}/api", bind_address);
    println!(
        "🔑 JWT Secret configured: {}",
        if std::env::var("JWT_SECRET").is_ok() {
            "✅"
        } else {
            "❌"
        }
    );

    let server = HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        let auth = HttpAuthentication::bearer(utils::validator);

        App::new()
            .app_data(web::Data::new(pool.clone()))
            .wrap(middleware::Logger::default())
            .wrap(cors)
            .route("/health", web::get().to(health_check))
            .service(
                web::scope("/api")
                    .service(
                        web::scope("/auth")
                            .route("/register", web::post().to(handlers::register))
                            .route("/login", web::post().to(handlers::login)),
                    )
                    .service(
                        web::scope("/users")
                            .wrap(AdminOnly)
                            .wrap(auth.clone())
                            .route("/all", web::get().to(handlers::get_all_users)),
                    )
                    .service(
                        web::scope("/admin")
                            .wrap(AdminOnly)
                            .wrap(auth)
                            .route("/create", web::post().to(handlers::create_admin)),
                    ),
            )
    })
    .bind(&bind_address)?;

    println!("✅ Server bound to {}", bind_address);
    println!("🎉 Server is now running and listening for requests!");

    server.run().await
}

// Endpoint de santé
async fn health_check() -> actix_web::Result<impl actix_web::Responder> {
    Ok(actix_web::HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "food_advisor_api",
        "timestamp": chrono::Utc::now().to_rfc3339()
    })))
}
