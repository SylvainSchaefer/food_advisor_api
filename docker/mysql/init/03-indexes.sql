USE food_advisor_db;

-- Index for recipe search by user and status
CREATE INDEX idx_recipes_user_published 
ON recipes(created_by, published, created_at DESC);

-- Index for recipe recommendations
CREATE INDEX idx_recipes_recommendation 
ON recipes(published, average_rating DESC, rating_count DESC);

-- Index for recipe search by difficulty and time
CREATE INDEX idx_recipes_difficulty_time
ON recipes(difficulty, total_time, published);

-- Index for managing stock close to expiration
CREATE INDEX idx_stock_expiration_user 
ON user_stock(user_id, expiration_date, quantity);

-- Index for recent recipe history
CREATE INDEX idx_history_recent 
ON recipe_history(user_id, completion_date DESC, rating);

-- Index for recipes achievable with available stock
CREATE INDEX idx_recipe_ingredients_quantity 
ON recipe_ingredients(ingredient_id, quantity, optional);

-- Index for user preferences
CREATE INDEX idx_preferences_active 
ON ingredient_preferences(user_id, preference_type);

-- Index for recent comments
CREATE INDEX idx_comments_recent 
ON comments(recipe_id, created_at DESC);

-- Index for allergen search
CREATE INDEX idx_ingredient_allergens_search 
ON ingredient_allergens(allergen_id, ingredient_id);

-- Index for shopping lists
CREATE INDEX idx_shopping_list_active 
ON shopping_lists(user_id, status, planned_shopping_date);

-- Index for user statistics
CREATE INDEX idx_history_stats 
ON recipe_history(user_id, rating, completion_date);

-- Index for favorite recipes search
CREATE INDEX idx_favorites_user_date 
ON favorite_recipes(user_id, created_at DESC);

-- Index for cost calculation optimization
CREATE INDEX idx_ingredients_price 
ON ingredients(approved, estimated_price);

-- Index for search by ingredient category
CREATE INDEX idx_ingredients_category_name 
ON ingredients(category_id, name, approved);

-- =============================================
-- Additional fulltext indexes
-- =============================================

-- Fulltext index for search in instructions
ALTER TABLE recipes 
ADD FULLTEXT idx_fulltext_instructions (instructions);

-- Fulltext index for search in comments
ALTER TABLE comments 
ADD FULLTEXT idx_fulltext_comment (comment);

-- Fulltext index for ingredient search
ALTER TABLE ingredients 
ADD FULLTEXT idx_fulltext_name (name);

-- =============================================
-- Materialized views (simulated with tables)
-- =============================================

-- Table to store calculated recipe statistics
CREATE TABLE IF NOT EXISTS recipe_stats (
    recipe_id INT PRIMARY KEY,
    average_rating DECIMAL(3,2),
    rating_count INT,
    completion_count INT,
    last_completion DATETIME,
    average_cost DECIMAL(6,2),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    INDEX idx_stats_rating (average_rating DESC),
    INDEX idx_stats_popularity (completion_count DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table to store diet/recipe compatibility
CREATE TABLE IF NOT EXISTS recipe_diet_compatibility (
    recipe_id INT NOT NULL,
    diet_id INT NOT NULL,
    compatible BOOLEAN DEFAULT TRUE,
    verified BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (recipe_id, diet_id),
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (diet_id) REFERENCES dietary_regimens(id) ON DELETE CASCADE,
    INDEX idx_diet_compatible (diet_id, compatible)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Indexes for join performance
-- =============================================

-- Performance improvement for frequent joins
CREATE INDEX idx_recipe_ingredients_join 
ON recipe_ingredients(recipe_id, ingredient_id, quantity);

CREATE INDEX idx_stock_join 
ON user_stock(user_id, ingredient_id, quantity);

CREATE INDEX idx_history_join 
ON recipe_history(user_id, recipe_id, completion_date);