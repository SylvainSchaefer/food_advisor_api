pub mod ingredient_repository;
pub mod user_repository;

// Ré-exporter les structs pour simplifier les imports
pub use ingredient_repository::IngredientRepository;
pub use user_repository::UserRepository;
