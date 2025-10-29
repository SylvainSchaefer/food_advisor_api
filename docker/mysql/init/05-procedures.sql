USE food_advisor_db;

DELIMITER //



DELIMITER $$

-- =====================================================
-- USER PROCEDURES
-- =====================================================

-- Procedure: Create a new user
DROP PROCEDURE IF EXISTS sp_create_user$$
CREATE PROCEDURE sp_create_user(
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_gender ENUM('Male', 'Female', 'Other'),
    IN p_password VARCHAR(255),
    IN p_email VARCHAR(255),
    IN p_role ENUM('Administrator', 'Regular'),
    IN p_country VARCHAR(100),
    IN p_city VARCHAR(100),
    IN p_birth_date DATE,
    OUT p_user_id INT,
    OUT p_error_message VARCHAR(500)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_error_message = MESSAGE_TEXT;
        
        -- Log error
        INSERT INTO error_logs (error_type, error_message, error_details, procedure_name, occurred_at)
        VALUES ('SQL_EXCEPTION', p_error_message, JSON_OBJECT('email', p_email), 'sp_create_user', NOW());
        
        SET p_user_id = NULL;
    END;
    
    START TRANSACTION;
    
    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        SET p_error_message = 'Email already exists';
        SET p_user_id = NULL;
        ROLLBACK;
    ELSE
        -- Insert new user
        INSERT INTO users (
            first_name, last_name, gender, password_hash, email, 
            role, country, city, birth_date, is_active
        ) VALUES (
            p_first_name, p_last_name, p_gender, SHA2(p_password, 256), p_email,
            p_role, p_country, p_city, p_birth_date, TRUE
        );
        
        SET p_user_id = LAST_INSERT_ID();
        SET p_error_message = NULL;
        
        -- Log successful creation in history
        INSERT INTO history_users (
            user_id, first_name, last_name, gender, email, role, 
            country, city, is_active, birth_date, change_type, changed_at
        ) VALUES (
            p_user_id, p_first_name, p_last_name, p_gender, p_email, p_role,
            p_country, p_city, TRUE, p_birth_date, 'INSERT', NOW()
        );
        
        COMMIT;
    END IF;
END$$

-- Procedure: Get user by ID
DROP PROCEDURE IF EXISTS sp_get_user$$
CREATE PROCEDURE sp_get_user(
    IN p_user_id INT
)
BEGIN
    -- Using view for consistent data access
    SELECT 
        u.user_id,
        u.full_name,
        u.email,
        u.role,
        u.country,
        u.city,
        u.birth_date,
        u.age,
        u.created_at,
        u.updated_at,
        us.recipes_created,
        us.recipes_completed,
        us.average_rating_given,
        us.allergy_count,
        us.stock_items_count
    FROM v_active_users u
    LEFT JOIN v_user_statistics us ON u.user_id = us.user_id
    WHERE u.user_id = p_user_id;
    
    -- Get user allergies
    SELECT 
        allergy_id,
        allergy_name,
        severity,
        allergy_added_date
    FROM v_user_allergies_detail
    WHERE user_id = p_user_id;
    
    -- Get user preferences
    SELECT * FROM v_user_preferences_summary
    WHERE user_id = p_user_id;
END$$

-- Procedure: Update user
DROP PROCEDURE IF EXISTS sp_update_user$$
CREATE PROCEDURE sp_update_user(
    IN p_user_id INT,
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_country VARCHAR(100),
    IN p_city VARCHAR(100),
    IN p_changed_by_user_id INT,
    OUT p_success BOOLEAN,
    OUT p_error_message VARCHAR(500)
)
BEGIN
    DECLARE v_old_first_name VARCHAR(100);
    DECLARE v_old_last_name VARCHAR(100);
    DECLARE v_old_country VARCHAR(100);
    DECLARE v_old_city VARCHAR(100);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_error_message = MESSAGE_TEXT;
        SET p_success = FALSE;
        
        INSERT INTO error_logs (error_type, error_message, procedure_name, user_id, occurred_at)
        VALUES ('SQL_EXCEPTION', p_error_message, 'sp_update_user', p_user_id, NOW());
    END;
    
    START TRANSACTION;
    
    -- Get old values for history
    SELECT first_name, last_name, country, city
    INTO v_old_first_name, v_old_last_name, v_old_country, v_old_city
    FROM users
    WHERE user_id = p_user_id AND is_active = TRUE;
    
    IF v_old_first_name IS NULL THEN
        SET p_error_message = 'User not found or inactive';
        SET p_success = FALSE;
        ROLLBACK;
    ELSE
        -- Update user
        UPDATE users
        SET 
            first_name = COALESCE(p_first_name, first_name),
            last_name = COALESCE(p_last_name, last_name),
            country = COALESCE(p_country, country),
            city = COALESCE(p_city, city)
        WHERE user_id = p_user_id;
        
        -- Log to history
        INSERT INTO history_users (
            user_id, first_name, last_name, country, city, 
            change_type, changed_by_user_id, changed_at, change_details
        ) VALUES (
            p_user_id, p_first_name, p_last_name, p_country, p_city,
            'UPDATE', p_changed_by_user_id, NOW(),
            JSON_OBJECT(
                'old_first_name', v_old_first_name,
                'old_last_name', v_old_last_name,
                'old_country', v_old_country,
                'old_city', v_old_city
            )
        );
        
        SET p_success = TRUE;
        SET p_error_message = NULL;
        COMMIT;
    END IF;
END$$

-- =====================================================
-- INGREDIENT PROCEDURES
-- =====================================================

-- Procedure: Create a new ingredient
DROP PROCEDURE IF EXISTS sp_create_ingredient$$
CREATE PROCEDURE sp_create_ingredient(
    IN p_name VARCHAR(200),
    IN p_carbohydrates DECIMAL(8,2),
    IN p_proteins DECIMAL(8,2),
    IN p_fats DECIMAL(8,2),
    IN p_fibers DECIMAL(8,2),
    IN p_calories DECIMAL(8,2),
    IN p_price DECIMAL(10,2),
    IN p_weight DECIMAL(10,2),
    IN p_measurement_unit VARCHAR(20),
    IN p_created_by_user_id INT,
    OUT p_ingredient_id INT,
    OUT p_error_message VARCHAR(500)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_error_message = MESSAGE_TEXT;
        SET p_ingredient_id = NULL;
        
        INSERT INTO error_logs (error_type, error_message, procedure_name, user_id, occurred_at)
        VALUES ('SQL_EXCEPTION', p_error_message, 'sp_create_ingredient', p_created_by_user_id, NOW());
    END;
    
    START TRANSACTION;
    
    -- Check if ingredient already exists
    IF EXISTS (SELECT 1 FROM ingredients WHERE name = p_name) THEN
        SET p_error_message = 'Ingredient with this name already exists';
        SET p_ingredient_id = NULL;
        ROLLBACK;
    ELSE
        -- Insert new ingredient
        INSERT INTO ingredients (
            name, carbohydrates, proteins, fats, fibers, 
            calories, price, weight, measurement_unit
        ) VALUES (
            p_name, p_carbohydrates, p_proteins, p_fats, p_fibers,
            p_calories, p_price, p_weight, p_measurement_unit
        );
        
        SET p_ingredient_id = LAST_INSERT_ID();
        SET p_error_message = NULL;
        
        -- Log to history
        INSERT INTO history_ingredients (
            ingredient_id, name, carbohydrates, proteins, fats, fibers,
            calories, price, change_type, changed_by_user_id, changed_at
        ) VALUES (
            p_ingredient_id, p_name, p_carbohydrates, p_proteins, p_fats, p_fibers,
            p_calories, p_price, 'INSERT', p_created_by_user_id, NOW()
        );
        
        COMMIT;
    END IF;
END$$

-- Procedure: Get ingredient by ID
DROP PROCEDURE IF EXISTS sp_get_ingredient$$
CREATE PROCEDURE sp_get_ingredient(
    IN p_ingredient_id INT
)
BEGIN
    -- Get ingredient details with categories
    SELECT 
        ingredient_id,
        ingredient_name,
        calories,
        proteins,
        carbohydrates,
        fats,
        fibers,
        price,
        measurement_unit,
        categories
    FROM v_ingredients_with_categories
    WHERE ingredient_id = p_ingredient_id;
    
    -- Get allergen information
    SELECT 
        ingredient_id,
        ingredient_name,
        allergens,
        allergen_count
    FROM v_ingredient_allergens
    WHERE ingredient_id = p_ingredient_id;
    
    -- Get usage statistics
    SELECT * FROM v_ingredient_usage_stats
    WHERE ingredient_id = p_ingredient_id;
END$$

-- Procedure: Search ingredients by name
DROP PROCEDURE IF EXISTS sp_search_ingredients$$
CREATE PROCEDURE sp_search_ingredients(
    IN p_search_term VARCHAR(100),
    IN p_category_id INT,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    SELECT 
        i.ingredient_id,
        i.ingredient_name,
        i.calories,
        i.proteins,
        i.carbohydrates,
        i.fats,
        i.price,
        i.measurement_unit,
        i.categories,
        ia.allergens
    FROM v_ingredients_with_categories i
    LEFT JOIN v_ingredient_allergens ia ON i.ingredient_id = ia.ingredient_id
    WHERE (p_search_term IS NULL OR i.ingredient_name LIKE CONCAT('%', p_search_term, '%'))
    AND (p_category_id IS NULL OR EXISTS (
        SELECT 1 FROM ingredient_category_assignments ica 
        WHERE ica.ingredient_id = i.ingredient_id 
        AND ica.category_id = p_category_id
    ))
    LIMIT p_limit OFFSET p_offset;
END$$

-- =====================================================
-- RECIPE PROCEDURES
-- =====================================================

-- Procedure: Create a new recipe
DROP PROCEDURE IF EXISTS sp_create_recipe$$
CREATE PROCEDURE sp_create_recipe(
    IN p_title VARCHAR(255),
    IN p_description TEXT,
    IN p_servings INT,
    IN p_difficulty VARCHAR(20),
    IN p_image_url VARCHAR(500),
    IN p_author_user_id INT,
    IN p_is_published BOOLEAN,
    OUT p_recipe_id INT,
    OUT p_error_message VARCHAR(500)
)
BEGIN
    DECLARE v_start_time BIGINT DEFAULT UNIX_TIMESTAMP(NOW(6)) * 1000;
    DECLARE v_execution_time INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_error_message = MESSAGE_TEXT;
        SET p_recipe_id = NULL;
        
        INSERT INTO error_logs (error_type, error_message, procedure_name, user_id, occurred_at)
        VALUES ('SQL_EXCEPTION', p_error_message, 'sp_create_recipe', p_author_user_id, NOW());
    END;
    
    START TRANSACTION;
    
    -- Insert new recipe
    INSERT INTO recipes (
        title, description, servings, difficulty, 
        image_url, author_user_id, is_published
    ) VALUES (
        p_title, p_description, p_servings, p_difficulty,
        p_image_url, p_author_user_id, p_is_published
    );
    
    SET p_recipe_id = LAST_INSERT_ID();
    SET p_error_message = NULL;
    
    -- Log to history
    INSERT INTO history_recipes (
        recipe_id, title, description, servings, difficulty,
        is_published, author_user_id, change_type, changed_by_user_id, changed_at
    ) VALUES (
        p_recipe_id, p_title, p_description, p_servings, p_difficulty,
        p_is_published, p_author_user_id, 'INSERT', p_author_user_id, NOW()
    );
    
    -- Log performance
    SET v_execution_time = (UNIX_TIMESTAMP(NOW(6)) * 1000) - v_start_time;
    INSERT INTO performance_logs (procedure_name, execution_time_ms, user_id, logged_at)
    VALUES ('sp_create_recipe', v_execution_time, p_author_user_id, NOW());
    
    COMMIT;
END$$

-- Procedure: Get recipe by ID
DROP PROCEDURE IF EXISTS sp_get_recipe$$
CREATE PROCEDURE sp_get_recipe(
    IN p_recipe_id INT,
    IN p_user_id INT
)
BEGIN
    -- Get recipe details from view
    SELECT * FROM v_published_recipes
    WHERE recipe_id = p_recipe_id;
    
    -- Get ingredients
    SELECT 
        i.ingredient_id,
        i.name AS ingredient_name,
        ri.quantity,
        i.measurement_unit,
        ri.is_optional,
        i.calories * ri.quantity / 100 AS total_calories,
        i.price * ri.quantity / i.weight AS estimated_cost
    FROM recipe_ingredients ri
    INNER JOIN ingredients i ON ri.ingredient_id = i.ingredient_id
    WHERE ri.recipe_id = p_recipe_id
    ORDER BY ri.is_optional, i.name;
    
    -- Get steps
    SELECT 
        step_order,
        description,
        duration_minutes,
        step_type
    FROM recipe_steps
    WHERE recipe_id = p_recipe_id
    ORDER BY step_order;
    
    -- Get nutritional information
    SELECT * FROM v_recipe_nutrition
    WHERE recipe_id = p_recipe_id;
    
    -- Check compatibility with user if user_id provided
    IF p_user_id IS NOT NULL THEN
        SELECT 
            is_allergy_safe,
            respects_preferences
        FROM v_user_compatible_recipes
        WHERE user_id = p_user_id AND recipe_id = p_recipe_id;
    END IF;
END$$

-- Procedure: Add ingredient to recipe
DROP PROCEDURE IF EXISTS sp_add_recipe_ingredient$$
CREATE PROCEDURE sp_add_recipe_ingredient(
    IN p_recipe_id INT,
    IN p_ingredient_id INT,
    IN p_quantity DECIMAL(10,2),
    IN p_is_optional BOOLEAN,
    IN p_user_id INT,
    OUT p_success BOOLEAN,
    OUT p_error_message VARCHAR(500)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_error_message = MESSAGE_TEXT;
        SET p_success = FALSE;
        
        INSERT INTO error_logs (error_type, error_message, procedure_name, user_id, occurred_at)
        VALUES ('SQL_EXCEPTION', p_error_message, 'sp_add_recipe_ingredient', p_user_id, NOW());
    END;
    
    START TRANSACTION;
    
    -- Check if recipe exists and user is author
    IF NOT EXISTS (
        SELECT 1 FROM recipes 
        WHERE recipe_id = p_recipe_id AND author_user_id = p_user_id
    ) THEN
        SET p_error_message = 'Recipe not found or you are not the author';
        SET p_success = FALSE;
        ROLLBACK;
    ELSE
        -- Insert or update ingredient
        INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional)
        VALUES (p_recipe_id, p_ingredient_id, p_quantity, p_is_optional)
        ON DUPLICATE KEY UPDATE
            quantity = p_quantity,
            is_optional = p_is_optional;
        
        SET p_success = TRUE;
        SET p_error_message = NULL;
        COMMIT;
    END IF;
END$$

-- Procedure: Record recipe completion
DROP PROCEDURE IF EXISTS sp_complete_recipe$$
CREATE PROCEDURE sp_complete_recipe(
    IN p_user_id INT,
    IN p_recipe_id INT,
    IN p_rating INT,
    IN p_comment TEXT,
    OUT p_completion_id INT,
    OUT p_error_message VARCHAR(500)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_error_message = MESSAGE_TEXT;
        SET p_completion_id = NULL;
        
        INSERT INTO error_logs (error_type, error_message, procedure_name, user_id, occurred_at)
        VALUES ('SQL_EXCEPTION', p_error_message, 'sp_complete_recipe', p_user_id, NOW());
    END;
    
    START TRANSACTION;
    
    -- Validate rating
    IF p_rating IS NOT NULL AND (p_rating < 1 OR p_rating > 5) THEN
        SET p_error_message = 'Rating must be between 1 and 5';
        SET p_completion_id = NULL;
        ROLLBACK;
    ELSE
        -- Insert completion record
        INSERT INTO completed_recipes (user_id, recipe_id, rating, comment, completion_date)
        VALUES (p_user_id, p_recipe_id, p_rating, p_comment, NOW());
        
        SET p_completion_id = LAST_INSERT_ID();
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
END$$

-- =====================================================
-- STOCK MANAGEMENT PROCEDURES
-- =====================================================

-- Procedure: Add or update user stock
DROP PROCEDURE IF EXISTS sp_manage_user_stock$$
CREATE PROCEDURE sp_manage_user_stock(
    IN p_user_id INT,
    IN p_ingredient_id INT,
    IN p_quantity DECIMAL(10,2),
    IN p_expiration_date DATE,
    IN p_storage_location VARCHAR(100),
    IN p_operation ENUM('add', 'update', 'remove'),
    OUT p_stock_id INT,
    OUT p_error_message VARCHAR(500)
)
BEGIN
    DECLARE v_existing_stock_id INT;
    DECLARE v_existing_quantity DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_error_message = MESSAGE_TEXT;
        SET p_stock_id = NULL;
        
        INSERT INTO error_logs (error_type, error_message, procedure_name, user_id, occurred_at)
        VALUES ('SQL_EXCEPTION', p_error_message, 'sp_manage_user_stock', p_user_id, NOW());
    END;
    
    START TRANSACTION;
    
    -- Check existing stock
    SELECT stock_id, quantity 
    INTO v_existing_stock_id, v_existing_quantity
    FROM user_ingredient_stock
    WHERE user_id = p_user_id 
    AND ingredient_id = p_ingredient_id
    AND (p_storage_location IS NULL OR storage_location = p_storage_location)
    LIMIT 1;
    
    CASE p_operation
        WHEN 'add' THEN
            IF v_existing_stock_id IS NOT NULL THEN
                -- Update existing stock
                UPDATE user_ingredient_stock
                SET quantity = quantity + p_quantity,
                    expiration_date = LEAST(COALESCE(expiration_date, p_expiration_date), p_expiration_date)
                WHERE stock_id = v_existing_stock_id;
                SET p_stock_id = v_existing_stock_id;
            ELSE
                -- Insert new stock
                INSERT INTO user_ingredient_stock (
                    user_id, ingredient_id, quantity, expiration_date, storage_location
                ) VALUES (
                    p_user_id, p_ingredient_id, p_quantity, p_expiration_date, p_storage_location
                );
                SET p_stock_id = LAST_INSERT_ID();
            END IF;
            
        WHEN 'update' THEN
            IF v_existing_stock_id IS NULL THEN
                SET p_error_message = 'Stock item not found';
                SET p_stock_id = NULL;
                ROLLBACK;
            ELSE
                UPDATE user_ingredient_stock
                SET quantity = p_quantity,
                    expiration_date = p_expiration_date,
                    storage_location = COALESCE(p_storage_location, storage_location)
                WHERE stock_id = v_existing_stock_id;
                SET p_stock_id = v_existing_stock_id;
            END IF;
            
        WHEN 'remove' THEN
            IF v_existing_stock_id IS NULL THEN
                SET p_error_message = 'Stock item not found';
                SET p_stock_id = NULL;
                ROLLBACK;
            ELSE
                IF p_quantity IS NULL OR p_quantity >= v_existing_quantity THEN
                    DELETE FROM user_ingredient_stock WHERE stock_id = v_existing_stock_id;
                ELSE
                    UPDATE user_ingredient_stock
                    SET quantity = quantity - p_quantity
                    WHERE stock_id = v_existing_stock_id;
                END IF;
                SET p_stock_id = v_existing_stock_id;
            END IF;
    END CASE;
    
    SET p_error_message = NULL;
    COMMIT;
END$$

-- =====================================================
-- SEARCH AND RECOMMENDATION PROCEDURES
-- =====================================================

-- Procedure: Search recipes with filters
DROP PROCEDURE IF EXISTS sp_search_recipes$$
CREATE PROCEDURE sp_search_recipes(
    IN p_search_term VARCHAR(255),
    IN p_difficulty VARCHAR(20),
    IN p_max_duration INT,
    IN p_user_id INT,
    IN p_only_compatible BOOLEAN,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    SELECT DISTINCT
        r.recipe_id,
        r.title,
        r.description,
        r.servings,
        r.difficulty,
        r.image_url,
        r.author_name,
        r.average_rating,
        r.times_completed,
        r.ingredient_count,
        r.total_duration_minutes,
        CASE WHEN p_user_id IS NOT NULL THEN ucr.is_allergy_safe ELSE TRUE END AS is_allergy_safe,
        CASE WHEN p_user_id IS NOT NULL THEN ucr.respects_preferences ELSE TRUE END AS respects_preferences
    FROM v_published_recipes r
    LEFT JOIN v_user_compatible_recipes ucr ON r.recipe_id = ucr.recipe_id 
        AND ucr.user_id = p_user_id
    WHERE (p_search_term IS NULL OR MATCH(r.title, r.description) AGAINST(p_search_term IN NATURAL LANGUAGE MODE))
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_duration IS NULL OR r.total_duration_minutes <= p_max_duration)
    AND (NOT p_only_compatible OR (ucr.is_allergy_safe = TRUE AND ucr.respects_preferences = TRUE))
    ORDER BY r.average_rating DESC, r.times_completed DESC
    LIMIT p_limit OFFSET p_offset;
END$$

-- Procedure: Get recipe recommendations for user
DROP PROCEDURE IF EXISTS sp_get_recipe_recommendations$$
CREATE PROCEDURE sp_get_recipe_recommendations(
    IN p_user_id INT,
    IN p_limit INT
)
BEGIN
    -- Get recipes based on user's preferred ingredients and categories
    -- Exclude recipes with allergens and excluded ingredients
    SELECT DISTINCT
        r.recipe_id,
        r.title,
        r.description,
        r.difficulty,
        r.average_rating,
        r.times_completed,
        COUNT(DISTINCT CASE 
            WHEN uip.preference_type = 'preferred' THEN ri.ingredient_id 
        END) AS preferred_ingredient_count,
        ucr.is_allergy_safe,
        ucr.respects_preferences
    FROM v_published_recipes r
    INNER JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id
    LEFT JOIN user_ingredient_preferences uip ON ri.ingredient_id = uip.ingredient_id 
        AND uip.user_id = p_user_id
    INNER JOIN v_user_compatible_recipes ucr ON r.recipe_id = ucr.recipe_id 
        AND ucr.user_id = p_user_id
    LEFT JOIN completed_recipes cr ON r.recipe_id = cr.recipe_id 
        AND cr.user_id = p_user_id
    WHERE ucr.is_allergy_safe = TRUE 
    AND ucr.respects_preferences = TRUE
    AND cr.completion_id IS NULL  -- Not yet completed by user
    GROUP BY r.recipe_id
    ORDER BY 
        preferred_ingredient_count DESC,
        r.average_rating DESC,
        r.times_completed DESC
    LIMIT p_limit;
END$$

-- =====================================================
-- UTILITY PROCEDURES
-- =====================================================

-- Procedure: Clean expired stock items
DROP PROCEDURE IF EXISTS sp_clean_expired_stock$$
CREATE PROCEDURE sp_clean_expired_stock()
BEGIN
    DECLARE v_deleted_count INT;
    
    START TRANSACTION;
    
    -- Archive expired items before deletion
    INSERT INTO audit_deletions (table_name, record_id, deleted_data, deleted_at)
    SELECT 
        'user_ingredient_stock',
        stock_id,
        JSON_OBJECT(
            'user_id', user_id,
            'ingredient_id', ingredient_id,
            'quantity', quantity,
            'expiration_date', expiration_date,
            'storage_location', storage_location
        ),
        NOW()
    FROM user_ingredient_stock
    WHERE expiration_date < DATE_SUB(CURDATE(), INTERVAL 30 DAY);
    
    -- Delete expired items
    DELETE FROM user_ingredient_stock
    WHERE expiration_date < DATE_SUB(CURDATE(), INTERVAL 30 DAY);
    
    SET v_deleted_count = ROW_COUNT();
    
    -- Log the cleanup
    INSERT INTO performance_logs (procedure_name, execution_time_ms, query_count, parameters, logged_at)
    VALUES ('sp_clean_expired_stock', 0, v_deleted_count, JSON_OBJECT('deleted_count', v_deleted_count), NOW());
    
    COMMIT;
    
    SELECT v_deleted_count AS items_deleted;
END$$

-- Procedure: Get user activity summary
DROP PROCEDURE IF EXISTS sp_get_user_activity_summary$$
CREATE PROCEDURE sp_get_user_activity_summary(
    IN p_user_id INT,
    IN p_days_back INT
)
BEGIN
    SELECT 
        activity_type,
        entity_name,
        activity_date
    FROM v_recent_user_activity
    WHERE user_id = p_user_id
    AND activity_date >= DATE_SUB(CURDATE(), INTERVAL p_days_back DAY)
    ORDER BY activity_date DESC;
END$$

DELIMITER ;