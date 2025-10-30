use chrono::{NaiveDate, NaiveDateTime};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

use crate::models::{Gender, Role};

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AuditDeletion {
    pub audit_id: u32,
    pub table_name: String,
    pub record_id: u32,
    pub deleted_data: serde_json::Value,
    pub deleted_by_user_id: Option<u32>,
    pub deleted_at: NaiveDateTime,
    pub ip_address: Option<String>,
    pub user_agent: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct HistoryUser {
    pub history_id: u32,
    pub user_id: u32,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub gender: Option<Gender>,
    pub email: Option<String>,
    pub role: Option<Role>,
    pub country: Option<String>,
    pub city: Option<String>,
    pub is_active: Option<bool>,
    pub birth_date: Option<NaiveDate>,
    pub change_type: String,
    pub changed_by_user_id: Option<u32>,
    pub changed_at: NaiveDateTime,
    pub change_details: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ErrorLog {
    pub error_id: u32,
    pub error_type: String,
    pub error_message: String,
    pub error_details: Option<serde_json::Value>,
    pub procedure_name: Option<String>,
    pub user_id: Option<u32>,
    pub occurred_at: NaiveDateTime,
    pub ip_address: Option<String>,
    pub resolved: bool,
    pub resolved_at: Option<NaiveDateTime>,
    pub resolved_by_user_id: Option<u32>,
    pub resolution_notes: Option<String>,
}

// =====================================================
// REQUEST/RESPONSE MODELS
// =====================================================

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub token: String,
    pub user_id: u32,
    pub email: String,
    pub role: Role,
}
