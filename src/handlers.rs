pub mod admin_handler;
pub mod user_handler;

// Ré-exports optionnels pour simplifier les imports
pub use admin_handler::{create_admin, get_all_users};
pub use user_handler::{login, register};
