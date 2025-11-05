pub mod ingredient_repository;
pub mod recipe_repository;
pub mod user_repository;

// Ré-exporter les structs pour simplifier les imports
pub use ingredient_repository::IngredientRepository;
pub use recipe_repository::RecipeRepository;
pub use user_repository::UserRepository;
