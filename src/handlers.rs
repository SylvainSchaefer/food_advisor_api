pub mod user_handler;
pub mod admin_handler;

// Ré-exports optionnels pour simplifier les imports
pub use user_handler::{login, register, get_profile};
pub use admin_handler::{get_all_users, create_admin};