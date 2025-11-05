use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Image {
    pub image_id: u32,
    pub entity_type: EntityType,
    pub entity_id: u32,
    #[serde(skip_serializing)]
    pub image_data: Vec<u8>,
    pub image_name: String,
    pub image_type: String,
    pub image_size: u32,
    pub width: Option<u32>,
    pub height: Option<u32>,
    pub is_primary: bool,
    pub alt_text: Option<String>,
    pub uploaded_by_user_id: u32,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "lowercase")]
pub enum EntityType {
    Recipe,
    Ingredient,
}
