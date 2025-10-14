pub mod admin_repository;
pub mod user_repository;

// Ré-exporter les structs pour simplifier les imports
pub use admin_repository::AdminRepository;
pub use user_repository::UserRepository;