USE food_advisor_db;


-- =====================================================
-- PERFORMANCE INDEXES FOR MAIN TABLES
-- =====================================================

-- Additional indexes for Users table
CREATE INDEX idx_users_country_city ON users(country, city);
CREATE INDEX idx_users_birth_date ON users(birth_date);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_last_name_first_name ON users(last_name, first_name);

-- Composite index for user authentication
CREATE UNIQUE INDEX idx_users_email_password ON users(email, password_hash);

-- Additional indexes for Recipes table
CREATE INDEX idx_recipes_created_at ON recipes(created_at);
CREATE INDEX idx_recipes_updated_at ON recipes(updated_at);
CREATE INDEX idx_recipes_servings ON recipes(servings);
CREATE INDEX idx_recipes_published_difficulty ON recipes(is_published, difficulty);
CREATE INDEX idx_recipes_author_published ON recipes(author_user_id, is_published);

-- Additional indexes for Ingredients table
CREATE INDEX idx_ingredients_calories ON ingredients(calories);
CREATE INDEX idx_ingredients_price ON ingredients(price);
CREATE INDEX idx_ingredients_measurement_unit ON ingredients(measurement_unit);

-- Composite indexes for nutritional queries
CREATE INDEX idx_ingredients_nutrition ON ingredients(calories, proteins, carbohydrates, fats);

-- Additional indexes for User Allergies
CREATE INDEX idx_user_allergies_severity ON user_allergies(severity);
CREATE INDEX idx_user_allergies_allergy_id ON user_allergies(allergy_id);

-- Additional indexes for Recipe Ingredients
CREATE INDEX idx_recipe_ingredients_ingredient ON recipe_ingredients(ingredient_id);
CREATE INDEX idx_recipe_ingredients_optional ON recipe_ingredients(is_optional);
CREATE INDEX idx_recipe_ingredients_quantity ON recipe_ingredients(quantity);

-- Additional indexes for Recipe Steps
CREATE INDEX idx_recipe_steps_type ON recipe_steps(step_type);
CREATE INDEX idx_recipe_steps_duration ON recipe_steps(duration_minutes);
CREATE INDEX idx_recipe_steps_order ON recipe_steps(recipe_id, step_order);

-- Additional indexes for Completed Recipes
CREATE INDEX idx_completed_recipes_user_date ON completed_recipes(user_id, completion_date DESC);
CREATE INDEX idx_completed_recipes_recipe_rating ON completed_recipes(recipe_id, rating);
CREATE INDEX idx_completed_recipes_date_desc ON completed_recipes(completion_date DESC);

-- Additional indexes for User Ingredient Stock
CREATE INDEX idx_user_stock_user_expiration ON user_ingredient_stock(user_id, expiration_date);
CREATE INDEX idx_user_stock_ingredient ON user_ingredient_stock(ingredient_id);
CREATE INDEX idx_user_stock_location ON user_ingredient_stock(storage_location);
CREATE INDEX idx_user_stock_quantity ON user_ingredient_stock(quantity);

-- Additional indexes for User Preferences
CREATE INDEX idx_user_ing_pref_user_type ON user_ingredient_preferences(user_id, preference_type);
CREATE INDEX idx_user_ing_pref_ingredient ON user_ingredient_preferences(ingredient_id);

CREATE INDEX idx_user_cat_pref_user_type ON user_ingredient_category_preferences(user_id, preference_type);
CREATE INDEX idx_user_cat_pref_category ON user_ingredient_category_preferences(category_id);

-- =====================================================
-- PERFORMANCE INDEXES FOR AUDIT/HISTORY TABLES
-- =====================================================

-- Indexes for History Users
CREATE INDEX idx_history_users_user_changed ON history_users(user_id, changed_at DESC);
CREATE INDEX idx_history_users_changed_by ON history_users(changed_by_user_id);

-- Indexes for History Recipes
CREATE INDEX idx_history_recipes_recipe_changed ON history_recipes(recipe_id, changed_at DESC);
CREATE INDEX idx_history_recipes_changed_by ON history_recipes(changed_by_user_id);
CREATE INDEX idx_history_recipes_change_type ON history_recipes(change_type);

-- Indexes for History Ingredients
CREATE INDEX idx_history_ingredients_ing_changed ON history_ingredients(ingredient_id, changed_at DESC);
CREATE INDEX idx_history_ingredients_changed_by ON history_ingredients(changed_by_user_id);

-- Indexes for Audit Deletions
CREATE INDEX idx_audit_deletions_table ON audit_deletions(table_name);
CREATE INDEX idx_audit_deletions_user_date ON audit_deletions(deleted_by_user_id, deleted_at DESC);

-- Indexes for Error Logs
CREATE INDEX idx_error_logs_procedure ON error_logs(procedure_name);
CREATE INDEX idx_error_logs_type_date ON error_logs(error_type, occurred_at DESC);
CREATE INDEX idx_error_logs_unresolved ON error_logs(resolved, occurred_at DESC);

-- Indexes for User Sessions
CREATE INDEX idx_sessions_user_active ON user_sessions(user_id, is_active);
CREATE INDEX idx_sessions_login_time ON user_sessions(login_time DESC);
CREATE INDEX idx_sessions_last_activity ON user_sessions(last_activity DESC);

-- Indexes for Performance Logs
CREATE INDEX idx_perf_logs_proc_date ON performance_logs(procedure_name, logged_at DESC);
CREATE INDEX idx_perf_logs_user ON performance_logs(user_id);
CREATE INDEX idx_perf_logs_slow_queries ON performance_logs(execution_time_ms DESC);

-- =====================================================
-- COVERING INDEXES FOR COMMON QUERIES
-- =====================================================

-- Covering index for user authentication with role check
CREATE INDEX idx_covering_user_auth ON users(email, password_hash, is_active, role, user_id);

-- Covering index for recipe listing with author info
CREATE INDEX idx_covering_recipe_list ON recipes(is_published, difficulty, created_at DESC, recipe_id, title, author_user_id);

-- Covering index for ingredient search by category
CREATE INDEX idx_covering_ing_category ON ingredient_category_assignments(category_id, ingredient_id);

-- Covering index for user recipe completion history
CREATE INDEX idx_covering_user_recipes ON completed_recipes(user_id, completion_date DESC, recipe_id, rating);

-- Covering index for expiring stock items
CREATE INDEX idx_covering_expiring_stock ON user_ingredient_stock(user_id, expiration_date, ingredient_id, quantity);

-- =====================================================
-- SPATIAL AND SPECIAL INDEXES
-- =====================================================

-- Hash index for session tokens (faster lookups)
-- Note: Hash indexes are memory-based in MySQL 8.0+
-- CREATE INDEX idx_hash_session_token ON user_sessions(session_token) USING HASH;

-- Partial index for active users only (MySQL 8.0.13+)
CREATE INDEX idx_active_users_email ON users(email);

-- Partial index for published recipes only
CREATE INDEX idx_published_recipes_recent ON recipes(created_at DESC) ;

