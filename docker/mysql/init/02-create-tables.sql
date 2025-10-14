USE food_advisor_db;

-- =============================================
-- File: 01_tables.sql
-- Description: Table creation for recipe system
-- Database: MySQL 8.0+
-- =============================================

-- Drop existing tables (in reverse dependency order)
DROP TABLE IF EXISTS shopping_list_ingredients;
DROP TABLE IF EXISTS shopping_lists;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS recipe_history;
DROP TABLE IF EXISTS user_stock;
DROP TABLE IF EXISTS recipe_steps;
DROP TABLE IF EXISTS recipe_ingredients;
DROP TABLE IF EXISTS favorite_recipes;
DROP TABLE IF EXISTS recipes;
DROP TABLE IF EXISTS ingredient_preferences;
DROP TABLE IF EXISTS dietary_preferences;
DROP TABLE IF EXISTS ingredient_allergens;
DROP TABLE IF EXISTS allergens;
DROP TABLE IF EXISTS ingredients;
DROP TABLE IF EXISTS ingredient_categories;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS dietary_regimens;

-- =============================================
-- Table: dietary_regimens
-- =============================================
CREATE TABLE dietary_regimens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: users
-- =============================================
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender ENUM('M', 'F', 'OTHER') DEFAULT 'OTHER',
    city VARCHAR(100),
    postal_code VARCHAR(10),
    country VARCHAR(100) DEFAULT 'France',
    role ENUM('user', 'administrator') DEFAULT 'user',
    dietary_regimen_id INT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (dietary_regimen_id) REFERENCES dietary_regimens(id) ON DELETE SET NULL,
    INDEX idx_email (email),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: ingredient_categories
-- =============================================
CREATE TABLE ingredient_categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: ingredients
-- =============================================
CREATE TABLE ingredients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    category_id INT NOT NULL,
    unit_of_measure ENUM('g', 'kg', 'ml', 'l', 'piece', 'teaspoon', 'tablespoon', 'cup', 'pinch') DEFAULT 'g',
    calories_per_100g DECIMAL(6,2),
    protein_per_100g DECIMAL(5,2),
    carbs_per_100g DECIMAL(5,2),
    fat_per_100g DECIMAL(5,2),
    fiber_per_100g DECIMAL(5,2),
    estimated_price DECIMAL(6,2),
    shelf_life_days INT DEFAULT 7,
    created_by INT,
    approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES ingredient_categories(id),
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_name (name),
    INDEX idx_category (category_id),
    INDEX idx_approved (approved)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: allergens
-- =============================================
CREATE TABLE allergens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    risk_level ENUM('low', 'medium', 'high') DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: ingredient_allergens
-- =============================================
CREATE TABLE ingredient_allergens (
    ingredient_id INT NOT NULL,
    allergen_id INT NOT NULL,
    PRIMARY KEY (ingredient_id, allergen_id),
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE,
    FOREIGN KEY (allergen_id) REFERENCES allergens(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: dietary_preferences
-- =============================================
CREATE TABLE dietary_preferences (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    allergen_id INT,
    preference_type ENUM('allergy', 'intolerance', 'aversion') NOT NULL,
    severity ENUM('mild', 'moderate', 'severe') DEFAULT 'moderate',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (allergen_id) REFERENCES allergens(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_allergen (user_id, allergen_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: ingredient_preferences
-- =============================================
CREATE TABLE ingredient_preferences (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    preference_type ENUM('excluded', 'avoided', 'preferred', 'favorite') NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_ingredient (user_id, ingredient_id),
    INDEX idx_user_pref (user_id, preference_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: recipes
-- =============================================
CREATE TABLE recipes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    instructions TEXT NOT NULL,
    prep_time INT, -- in minutes
    cook_time INT, -- in minutes
    total_time INT GENERATED ALWAYS AS (prep_time + cook_time) STORED,
    servings INT DEFAULT 4,
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'medium',
    estimated_cost DECIMAL(6,2),
    image_url VARCHAR(500),
    created_by INT NOT NULL,
    published BOOLEAN DEFAULT TRUE,
    average_rating DECIMAL(3,2) DEFAULT 0,
    rating_count INT DEFAULT 0,
    completion_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_title (title),
    INDEX idx_created_by (created_by),
    INDEX idx_published (published),
    INDEX idx_rating (average_rating),
    INDEX idx_difficulty (difficulty),
    FULLTEXT idx_fulltext (title, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: favorite_recipes
-- =============================================
CREATE TABLE favorite_recipes (
    user_id INT NOT NULL,
    recipe_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, recipe_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: recipe_ingredients
-- =============================================
CREATE TABLE recipe_ingredients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    recipe_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit_of_measure VARCHAR(20),
    optional BOOLEAN DEFAULT FALSE,
    notes VARCHAR(255),
    order_position INT DEFAULT 0,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id),
    INDEX idx_recipe (recipe_id),
    INDEX idx_ingredient (ingredient_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: recipe_steps
-- =============================================
CREATE TABLE recipe_steps (
    id INT PRIMARY KEY AUTO_INCREMENT,
    recipe_id INT NOT NULL,
    step_number INT NOT NULL,
    description TEXT NOT NULL,
    duration_minutes INT,
    image_url VARCHAR(500),
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    UNIQUE KEY unique_recipe_step (recipe_id, step_number),
    INDEX idx_recipe_step (recipe_id, step_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: user_stock
-- =============================================
CREATE TABLE user_stock (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit_of_measure VARCHAR(20),
    expiration_date DATE,
    location VARCHAR(50) DEFAULT 'kitchen',
    notes VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_ingredient_stock (user_id, ingredient_id, expiration_date),
    INDEX idx_user_stock (user_id),
    INDEX idx_expiration (expiration_date),
    INDEX idx_ingredient_stock (ingredient_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: recipe_history
-- =============================================
CREATE TABLE recipe_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    recipe_id INT NOT NULL,
    completion_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    actual_time_minutes INT,
    servings_made INT,
    stock_updated BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    INDEX idx_user_history (user_id, completion_date DESC),
    INDEX idx_recipe_history (recipe_id),
    INDEX idx_completion_date (completion_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: comments
-- =============================================
CREATE TABLE comments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    recipe_id INT NOT NULL,
    user_id INT NOT NULL,
    history_id INT,
    comment TEXT NOT NULL,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    visible BOOLEAN DEFAULT TRUE,
    moderated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (history_id) REFERENCES recipe_history(id) ON DELETE SET NULL,
    INDEX idx_recipe_comments (recipe_id, visible),
    INDEX idx_user_comments (user_id),
    INDEX idx_moderation (moderated, visible)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: shopping_lists
-- =============================================
CREATE TABLE shopping_lists (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    creation_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    planned_shopping_date DATE,
    status ENUM('in_progress', 'completed', 'archived') DEFAULT 'in_progress',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_list (user_id, status),
    INDEX idx_shopping_date (planned_shopping_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Table: shopping_list_ingredients
-- =============================================
CREATE TABLE shopping_list_ingredients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    list_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit_of_measure VARCHAR(20),
    recipe_id INT,
    purchased BOOLEAN DEFAULT FALSE,
    actual_price DECIMAL(6,2),
    notes VARCHAR(255),
    FOREIGN KEY (list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id),
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE SET NULL,
    INDEX idx_list (list_id),
    INDEX idx_purchased (purchased)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;