pub mod admin_handler;
pub mod ingredient_handler;
pub mod user_handler;

// Ré-exports optionnels pour simplifier les imports
pub use admin_handler::{create_admin, get_all_users};
pub use ingredient_handler::{
    create_ingredient, delete_ingredient, get_all_ingredients, get_ingredient, update_ingredient,
};
pub use user_handler::{login, register};
