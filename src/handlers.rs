pub mod admin_handler;
pub mod ingredient_handler;
pub mod recipe_handler;
pub mod user_handler;

// Ré-exports optionnels pour simplifier les imports
pub use admin_handler::{create_admin, get_all_users};
pub use ingredient_handler::{
    create_ingredient, delete_ingredient, get_all_ingredients, get_ingredient, update_ingredient,
};
pub use recipe_handler::{
    add_recipe_ingredient, complete_recipe, create_recipe, delete_recipe, get_all_recipes,
    get_recipe, get_user_recipes, remove_recipe_ingredient, update_recipe,
};
pub use user_handler::{login, register};
