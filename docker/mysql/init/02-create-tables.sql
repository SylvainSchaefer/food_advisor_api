USE food_advisor_db;


-- =====================================================
-- MAIN TABLES
-- =====================================================

-- Users table
CREATE TABLE users (
    user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    role ENUM('Administrator', 'Regular') NOT NULL DEFAULT 'Regular',
    country VARCHAR(100),
    city VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    birth_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_first_name(first_name),
    INDEX idx_last_name(last_name),
    INDEX idx_active (is_active)
) ENGINE=InnoDB;

-- Allergies table
CREATE TABLE allergies (
    allergy_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name(name)
) ENGINE=InnoDB;

-- User allergies table
CREATE TABLE user_allergies (
    user_id INT UNSIGNED NOT NULL,
    allergy_id INT UNSIGNED NOT NULL,
    severity ENUM('Mild', 'Moderate', 'Severe', 'Life-threatening') NOT NULL DEFAULT 'Moderate',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, allergy_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (allergy_id) REFERENCES allergies(allergy_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Ingredients table
CREATE TABLE ingredients (
    ingredient_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL UNIQUE,
    carbohydrates DECIMAL(8,2) DEFAULT 0 COMMENT 'Per 100g',
    proteins DECIMAL(8,2) DEFAULT 0 COMMENT 'Per 100g',
    fats DECIMAL(8,2) DEFAULT 0 COMMENT 'Per 100g',
    fibers DECIMAL(8,2) DEFAULT 0 COMMENT 'Per 100g',
    calories DECIMAL(8,2) DEFAULT 0 COMMENT 'Per 100g',
    price DECIMAL(10,2) DEFAULT 0,
    weight DECIMAL(10,2) DEFAULT 100 COMMENT 'In grams',
    measurement_unit ENUM('tablespoon', 'teaspoon', 'liters', 'milliliters', 'grams', 'kilograms', 'cups', 'pieces') DEFAULT 'grams',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB;

-- Ingredient allergies table
CREATE TABLE ingredient_allergies (
    ingredient_id INT UNSIGNED NOT NULL,
    allergy_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (ingredient_id, allergy_id),
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    FOREIGN KEY (allergy_id) REFERENCES allergies(allergy_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Ingredient categories table
CREATE TABLE ingredient_categories (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB;

-- Ingredient category assignments table
CREATE TABLE ingredient_category_assignments (
    ingredient_id INT UNSIGNED NOT NULL,
    category_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (ingredient_id, category_id),
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES ingredient_categories(category_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- User ingredient category preferences table
CREATE TABLE user_ingredient_category_preferences (
    user_id INT UNSIGNED NOT NULL,
    category_id INT UNSIGNED NOT NULL,
    preference_type ENUM('excluded', 'preferred') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, category_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES ingredient_categories(category_id) ON DELETE CASCADE,
    INDEX idx_preference_type (preference_type)
) ENGINE=InnoDB;

-- User ingredient preferences table
CREATE TABLE user_ingredient_preferences (
    user_id INT UNSIGNED NOT NULL,
    ingredient_id INT UNSIGNED NOT NULL,
    preference_type ENUM('excluded', 'preferred') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, ingredient_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    INDEX idx_preference_type (preference_type)
) ENGINE=InnoDB;

-- User ingredient stock table
CREATE TABLE user_ingredient_stock (
    stock_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    ingredient_id INT UNSIGNED NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    expiration_date DATE,
    storage_location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    INDEX idx_user_ingredient (user_id, ingredient_id),
    INDEX idx_expiration (expiration_date)
) ENGINE=InnoDB;

-- Recipes table
CREATE TABLE recipes (
    recipe_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    servings INT UNSIGNED DEFAULT 4,
    is_published BOOLEAN DEFAULT FALSE,
    difficulty ENUM('Easy', 'Medium', 'Hard', 'Expert') DEFAULT 'Medium',
    author_user_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (author_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_published (is_published),
    INDEX idx_difficulty (difficulty),
    INDEX idx_author (author_user_id),
    FULLTEXT idx_title_description (title, description)
) ENGINE=InnoDB;

-- Recipe ingredients table
CREATE TABLE recipe_ingredients (
    recipe_id INT UNSIGNED NOT NULL,
    ingredient_id INT UNSIGNED NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    is_optional BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (recipe_id, ingredient_id),
    FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Recipe steps table
CREATE TABLE recipe_steps (
    recipe_id INT UNSIGNED NOT NULL,
    step_order INT UNSIGNED NOT NULL,
    description TEXT NOT NULL,
    duration_minutes INT UNSIGNED DEFAULT 0,
    step_type ENUM('cooking', 'action') NOT NULL DEFAULT 'action',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (recipe_id, step_order),
    FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Completed recipes table
CREATE TABLE completed_recipes (
    completion_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    recipe_id INT UNSIGNED NOT NULL,
    completion_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    comment TEXT,
    rating INT UNSIGNED CHECK (rating >= 1 AND rating <= 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE,
    INDEX idx_user_recipe (user_id, recipe_id),
    INDEX idx_completion_date (completion_date),
    INDEX idx_rating (rating)
) ENGINE=InnoDB;

-- =====================================================
-- AUDIT/HISTORY TABLES
-- =====================================================

-- General audit log table for all deletions
CREATE TABLE audit_deletions (
    audit_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INT UNSIGNED NOT NULL,
    deleted_data JSON NOT NULL,
    deleted_by_user_id INT UNSIGNED,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent VARCHAR(255),
    INDEX idx_table_record (table_name, record_id),
    INDEX idx_deleted_at (deleted_at),
    INDEX idx_deleted_by (deleted_by_user_id)
) ENGINE=InnoDB;

-- History table for user modifications
CREATE TABLE history_users (
    history_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    gender ENUM('Male', 'Female', 'Other'),
    email VARCHAR(255),
    role ENUM('Administrator', 'Regular'),
    country VARCHAR(100),
    city VARCHAR(100),
    is_active BOOLEAN,
    birth_date DATE,
    change_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    changed_by_user_id INT UNSIGNED,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    change_details JSON,
    INDEX idx_user_id (user_id),
    INDEX idx_changed_at (changed_at),
    INDEX idx_change_type (change_type)
) ENGINE=InnoDB;

-- History table for recipe modifications
CREATE TABLE history_recipes (
    history_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    recipe_id INT UNSIGNED NOT NULL,
    title VARCHAR(255),
    description TEXT,
    servings INT UNSIGNED,
    is_published BOOLEAN,
    difficulty ENUM('Easy', 'Medium', 'Hard', 'Expert'),
    author_user_id INT UNSIGNED,
    change_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    changed_by_user_id INT UNSIGNED,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    change_details JSON,
    INDEX idx_recipe_id (recipe_id),
    INDEX idx_changed_at (changed_at)
) ENGINE=InnoDB;

-- History table for ingredient modifications
CREATE TABLE history_ingredients (
    history_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ingredient_id INT UNSIGNED NOT NULL,
    name VARCHAR(200),
    carbohydrates DECIMAL(8,2),
    proteins DECIMAL(8,2),
    fats DECIMAL(8,2),
    fibers DECIMAL(8,2),
    calories DECIMAL(8,2),
    price DECIMAL(10,2),
    change_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    changed_by_user_id INT UNSIGNED,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    change_details JSON,
    INDEX idx_ingredient_id (ingredient_id),
    INDEX idx_changed_at (changed_at)
) ENGINE=InnoDB;

-- Error log table
CREATE TABLE error_logs (
    error_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    error_type VARCHAR(100) NOT NULL,
    error_message TEXT NOT NULL,
    error_details JSON,
    procedure_name VARCHAR(100),
    user_id INT UNSIGNED,
    occurred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP NULL,
    resolved_by_user_id INT UNSIGNED,
    resolution_notes TEXT,
    INDEX idx_error_type (error_type),
    INDEX idx_occurred_at (occurred_at),
    INDEX idx_resolved (resolved),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB;

-- Session tracking table for security auditing
CREATE TABLE user_sessions (
    session_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    session_token VARCHAR(255) NOT NULL UNIQUE,
    ip_address VARCHAR(45),
    user_agent VARCHAR(255),
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_time TIMESTAMP NULL,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_session_token (session_token),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB;

-- Performance monitoring table
CREATE TABLE performance_logs (
    log_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    procedure_name VARCHAR(100),
    execution_time_ms INT UNSIGNED,
    query_count INT UNSIGNED,
    user_id INT UNSIGNED,
    parameters JSON,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_procedure (procedure_name)
) ENGINE=InnoDB;


-- Images table for recipes and ingredients
CREATE TABLE images (
    image_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    entity_type ENUM('recipe', 'ingredient') NOT NULL,
    entity_id INT UNSIGNED NOT NULL,
    image_data MEDIUMBLOB NOT NULL COMMENT 'Stores binary image data',
    image_name VARCHAR(255) NOT NULL,
    image_type VARCHAR(50) NOT NULL COMMENT 'MIME type (e.g., image/jpeg, image/png)',
    image_size INT UNSIGNED NOT NULL COMMENT 'Size in bytes',
    width INT UNSIGNED COMMENT 'Image width in pixels',
    height INT UNSIGNED COMMENT 'Image height in pixels',
    is_primary BOOLEAN DEFAULT FALSE COMMENT 'Primary image for the entity',
    alt_text VARCHAR(500) COMMENT 'Alternative text for accessibility',
    uploaded_by_user_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (uploaded_by_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_entity_id (entity_id)
) ENGINE=InnoDB;