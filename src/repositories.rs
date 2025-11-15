pub mod image_repository;
pub mod ingredient_categories_repository;
pub mod ingredient_repository;
pub mod recipe_repository;
pub mod user_preferences_repository;
pub mod user_repository;

// Ré-exporter les structs pour simplifier les imports
pub use image_repository::ImageRepository;
pub use ingredient_categories_repository::IngredientCategoryRepository;
pub use ingredient_repository::IngredientRepository;
pub use recipe_repository::RecipeRepository;
pub use user_preferences_repository::UserPreferencesRepository;
pub use user_repository::UserRepository;
