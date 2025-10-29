USE food_advisor_db;


DELIMITER $$

-- =====================================================
-- USER TRIGGERS
-- =====================================================

-- Trigger: Before user update - track changes
DROP TRIGGER IF EXISTS trg_before_user_update$$
CREATE TRIGGER trg_before_user_update
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    -- Record the change in history
    IF OLD.first_name != NEW.first_name OR 
       OLD.last_name != NEW.last_name OR
       OLD.email != NEW.email OR
       OLD.role != NEW.role OR
       OLD.is_active != NEW.is_active OR
       OLD.country != NEW.country OR
       OLD.city != NEW.city OR
       OLD.birth_date != NEW.birth_date THEN
        
        INSERT INTO history_users (
            user_id, first_name, last_name, gender, email, role, 
            country, city, is_active, birth_date, change_type, 
            changed_at, change_details
        ) VALUES (
            NEW.user_id, NEW.first_name, NEW.last_name, NEW.gender, 
            NEW.email, NEW.role, NEW.country, NEW.city, NEW.is_active, 
            NEW.birth_date, 'UPDATE', NOW(),
            JSON_OBJECT(
                'old_values', JSON_OBJECT(
                    'first_name', OLD.first_name,
                    'last_name', OLD.last_name,
                    'email', OLD.email,
                    'role', OLD.role,
                    'is_active', OLD.is_active,
                    'country', OLD.country,
                    'city', OLD.city,
                    'birth_date', OLD.birth_date
                )
            )
        );
    END IF;
END$$

-- Trigger: Before user delete - archive data
DROP TRIGGER IF EXISTS trg_before_user_delete$$
CREATE TRIGGER trg_before_user_delete
BEFORE DELETE ON users
FOR EACH ROW
BEGIN
    -- Archive user data
    INSERT INTO audit_deletions (
        table_name, record_id, deleted_data, deleted_at
    ) VALUES (
        'users', OLD.user_id,
        JSON_OBJECT(
            'user_id', OLD.user_id,
            'first_name', OLD.first_name,
            'last_name', OLD.last_name,
            'gender', OLD.gender,
            'email', OLD.email,
            'role', OLD.role,
            'country', OLD.country,
            'city', OLD.city,
            'birth_date', OLD.birth_date,
            'is_active', OLD.is_active,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NOW()
    );
    
    -- Record in history
    INSERT INTO history_users (
        user_id, first_name, last_name, gender, email, role, 
        country, city, is_active, birth_date, change_type, changed_at
    ) VALUES (
        OLD.user_id, OLD.first_name, OLD.last_name, OLD.gender, 
        OLD.email, OLD.role, OLD.country, OLD.city, OLD.is_active, 
        OLD.birth_date, 'DELETE', NOW()
    );
END$$

-- Trigger: Validate user email format
DROP TRIGGER IF EXISTS trg_before_user_insert$$
CREATE TRIGGER trg_before_user_insert
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    -- Validate email format
    IF NEW.email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Invalid email format';
    END IF;
    
    -- Validate birth date (must be in the past and user must be at least 13)
    IF NEW.birth_date IS NOT NULL THEN
        IF NEW.birth_date >= CURDATE() THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Birth date must be in the past';
        END IF;
        
        IF TIMESTAMPDIFF(YEAR, NEW.birth_date, CURDATE()) < 13 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'User must be at least 13 years old';
        END IF;
    END IF;
END$$

-- =====================================================
-- RECIPE TRIGGERS
-- =====================================================

-- Trigger: Before recipe update - track changes
DROP TRIGGER IF EXISTS trg_before_recipe_update$$
CREATE TRIGGER trg_before_recipe_update
BEFORE UPDATE ON recipes
FOR EACH ROW
BEGIN
    -- Record significant changes in history
    IF OLD.title != NEW.title OR 
       OLD.description != NEW.description OR
       OLD.servings != NEW.servings OR
       OLD.difficulty != NEW.difficulty OR
       OLD.is_published != NEW.is_published THEN
        
        INSERT INTO history_recipes (
            recipe_id, title, description, servings, difficulty,
            is_published, author_user_id, change_type, changed_at, change_details
        ) VALUES (
            NEW.recipe_id, NEW.title, NEW.description, NEW.servings, 
            NEW.difficulty, NEW.is_published, NEW.author_user_id, 
            'UPDATE', NOW(),
            JSON_OBJECT(
                'old_values', JSON_OBJECT(
                    'title', OLD.title,
                    'description', OLD.description,
                    'servings', OLD.servings,
                    'difficulty', OLD.difficulty,
                    'is_published', OLD.is_published
                )
            )
        );
    END IF;
END$$

-- Trigger: Before recipe delete - archive data
DROP TRIGGER IF EXISTS trg_before_recipe_delete$$
CREATE TRIGGER trg_before_recipe_delete
BEFORE DELETE ON recipes
FOR EACH ROW
BEGIN
    -- Archive recipe data
    INSERT INTO audit_deletions (
        table_name, record_id, deleted_data, deleted_at
    ) VALUES (
        'recipes', OLD.recipe_id,
        JSON_OBJECT(
            'recipe_id', OLD.recipe_id,
            'title', OLD.title,
            'description', OLD.description,
            'servings', OLD.servings,
            'difficulty', OLD.difficulty,
            'is_published', OLD.is_published,
            'image_url', OLD.image_url,
            'author_user_id', OLD.author_user_id,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NOW()
    );
    
    -- Record in history
    INSERT INTO history_recipes (
        recipe_id, title, description, servings, difficulty,
        is_published, author_user_id, change_type, changed_at
    ) VALUES (
        OLD.recipe_id, OLD.title, OLD.description, OLD.servings, 
        OLD.difficulty, OLD.is_published, OLD.author_user_id, 
        'DELETE', NOW()
    );
END$$

-- Trigger: Validate recipe data
DROP TRIGGER IF EXISTS trg_before_recipe_insert$$
CREATE TRIGGER trg_before_recipe_insert
BEFORE INSERT ON recipes
FOR EACH ROW
BEGIN
    -- Validate servings
    IF NEW.servings <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Servings must be greater than 0';
    END IF;
    
    -- Validate title length
    IF LENGTH(TRIM(NEW.title)) < 3 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Recipe title must be at least 3 characters';
    END IF;
END$$

-- =====================================================
-- INGREDIENT TRIGGERS
-- =====================================================

-- Trigger: Before ingredient update - track changes
DROP TRIGGER IF EXISTS trg_before_ingredient_update$$
CREATE TRIGGER trg_before_ingredient_update
BEFORE UPDATE ON ingredients
FOR EACH ROW
BEGIN
    -- Record significant changes
    IF OLD.name != NEW.name OR 
       ABS(OLD.calories - NEW.calories) > 0.01 OR
       ABS(OLD.proteins - NEW.proteins) > 0.01 OR
       ABS(OLD.carbohydrates - NEW.carbohydrates) > 0.01 OR
       ABS(OLD.fats - NEW.fats) > 0.01 OR
       ABS(OLD.price - NEW.price) > 0.01 THEN
        
        INSERT INTO history_ingredients (
            ingredient_id, name, carbohydrates, proteins, fats, 
            fibers, calories, price, change_type, changed_at, change_details
        ) VALUES (
            NEW.ingredient_id, NEW.name, NEW.carbohydrates, NEW.proteins, 
            NEW.fats, NEW.fibers, NEW.calories, NEW.price, 
            'UPDATE', NOW(),
            JSON_OBJECT(
                'old_values', JSON_OBJECT(
                    'name', OLD.name,
                    'calories', OLD.calories,
                    'proteins', OLD.proteins,
                    'carbohydrates', OLD.carbohydrates,
                    'fats', OLD.fats,
                    'fibers', OLD.fibers,
                    'price', OLD.price
                )
            )
        );
    END IF;
END$$

-- Trigger: Before ingredient delete - archive data
DROP TRIGGER IF EXISTS trg_before_ingredient_delete$$
CREATE TRIGGER trg_before_ingredient_delete
BEFORE DELETE ON ingredients
FOR EACH ROW
BEGIN
    -- Archive ingredient data
    INSERT INTO audit_deletions (
        table_name, record_id, deleted_data, deleted_at
    ) VALUES (
        'ingredients', OLD.ingredient_id,
        JSON_OBJECT(
            'ingredient_id', OLD.ingredient_id,
            'name', OLD.name,
            'carbohydrates', OLD.carbohydrates,
            'proteins', OLD.proteins,
            'fats', OLD.fats,
            'fibers', OLD.fibers,
            'calories', OLD.calories,
            'price', OLD.price,
            'weight', OLD.weight,
            'measurement_unit', OLD.measurement_unit,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NOW()
    );
    
    -- Record in history
    INSERT INTO history_ingredients (
        ingredient_id, name, carbohydrates, proteins, fats, 
        fibers, calories, price, change_type, changed_at
    ) VALUES (
        OLD.ingredient_id, OLD.name, OLD.carbohydrates, OLD.proteins, 
        OLD.fats, OLD.fibers, OLD.calories, OLD.price, 
        'DELETE', NOW()
    );
END$$

-- Trigger: Validate ingredient nutritional values
DROP TRIGGER IF EXISTS trg_before_ingredient_insert$$
CREATE TRIGGER trg_before_ingredient_insert
BEFORE INSERT ON ingredients
FOR EACH ROW
BEGIN
    -- Validate that nutritional values are non-negative
    IF NEW.calories < 0 OR NEW.proteins < 0 OR NEW.carbohydrates < 0 OR 
       NEW.fats < 0 OR NEW.fibers < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Nutritional values cannot be negative';
    END IF;
    
    -- Validate price
    IF NEW.price < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Price cannot be negative';
    END IF;
    
    -- Validate weight
    IF NEW.weight <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Weight must be greater than 0';
    END IF;
END$$

-- =====================================================
-- STOCK TRIGGERS
-- =====================================================

-- Trigger: Alert on low stock
DROP TRIGGER IF EXISTS trg_after_stock_update$$
CREATE TRIGGER trg_after_stock_update
AFTER UPDATE ON user_ingredient_stock
FOR EACH ROW
BEGIN
    -- Check if quantity is getting low (less than 10% of original)
    IF NEW.quantity < OLD.quantity * 0.1 AND NEW.quantity > 0 THEN
        INSERT INTO error_logs (
            error_type, 
            error_message, 
            error_details, 
            user_id, 
            occurred_at
        ) VALUES (
            'LOW_STOCK_WARNING',
            CONCAT('Low stock alert for ingredient #', NEW.ingredient_id),
            JSON_OBJECT(
                'stock_id', NEW.stock_id,
                'ingredient_id', NEW.ingredient_id,
                'current_quantity', NEW.quantity,
                'previous_quantity', OLD.quantity,
                'storage_location', NEW.storage_location
            ),
            NEW.user_id,
            NOW()
        );
    END IF;
END$$

-- Trigger: Alert on approaching expiration
DROP TRIGGER IF EXISTS trg_after_stock_insert$$
CREATE TRIGGER trg_after_stock_insert
AFTER INSERT ON user_ingredient_stock
FOR EACH ROW
BEGIN
    -- Check if item is expiring within 7 days
    IF NEW.expiration_date IS NOT NULL AND 
       DATEDIFF(NEW.expiration_date, CURDATE()) BETWEEN 0 AND 7 THEN
        INSERT INTO error_logs (
            error_type, 
            error_message, 
            error_details, 
            user_id, 
            occurred_at
        ) VALUES (
            'EXPIRATION_WARNING',
            CONCAT('Item expiring soon: ingredient #', NEW.ingredient_id),
            JSON_OBJECT(
                'stock_id', NEW.stock_id,
                'ingredient_id', NEW.ingredient_id,
                'expiration_date', NEW.expiration_date,
                'days_until_expiration', DATEDIFF(NEW.expiration_date, CURDATE()),
                'quantity', NEW.quantity,
                'storage_location', NEW.storage_location
            ),
            NEW.user_id,
            NOW()
        );
    END IF;
END$$

-- =====================================================
-- RECIPE COMPLETION TRIGGERS
-- =====================================================

-- Trigger: Validate rating on completion
DROP TRIGGER IF EXISTS trg_before_completion_insert$$
CREATE TRIGGER trg_before_completion_insert
BEFORE INSERT ON completed_recipes
FOR EACH ROW
BEGIN
    -- Validate rating is between 1 and 5 if provided
    IF NEW.rating IS NOT NULL AND (NEW.rating < 1 OR NEW.rating > 5) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Rating must be between 1 and 5';
    END IF;
    
    -- Ensure recipe exists and is published
    IF NOT EXISTS (
        SELECT 1 FROM recipes 
        WHERE recipe_id = NEW.recipe_id AND is_published = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot complete unpublished recipe';
    END IF;
END$$

-- =====================================================
-- SESSION TRIGGERS
-- =====================================================

-- Trigger: Auto-logout inactive sessions
DROP TRIGGER IF EXISTS trg_before_session_update$$
CREATE TRIGGER trg_before_session_update
BEFORE UPDATE ON user_sessions
FOR EACH ROW
BEGIN
    -- Auto-logout if session has been inactive for more than 24 hours
    IF NEW.is_active = TRUE AND 
       TIMESTAMPDIFF(HOUR, OLD.last_activity, NOW()) > 24 THEN
        SET NEW.is_active = FALSE;
        SET NEW.logout_time = NOW();
    END IF;
END$$

-- Trigger: Clean up old sessions on new login
DROP TRIGGER IF EXISTS trg_after_session_insert$$
CREATE TRIGGER trg_after_session_insert
AFTER INSERT ON user_sessions
FOR EACH ROW
BEGIN
    -- Deactivate all other sessions for this user
    UPDATE user_sessions
    SET is_active = FALSE,
        logout_time = NOW()
    WHERE user_id = NEW.user_id
    AND session_id != NEW.session_id
    AND is_active = TRUE;
END$$

-- =====================================================
-- RECIPE INGREDIENT TRIGGERS
-- =====================================================

-- Trigger: Validate recipe ingredient quantity
DROP TRIGGER IF EXISTS trg_before_recipe_ingredient_insert$$
CREATE TRIGGER trg_before_recipe_ingredient_insert
BEFORE INSERT ON recipe_ingredients
FOR EACH ROW
BEGIN
    -- Validate quantity is positive
    IF NEW.quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Ingredient quantity must be greater than 0';
    END IF;
END$$

-- =====================================================
-- ALLERGY TRIGGERS
-- =====================================================

-- Trigger: Alert when user adds recipe with allergens
DROP TRIGGER IF EXISTS trg_after_user_allergy_insert$$
CREATE TRIGGER trg_after_user_allergy_insert
AFTER INSERT ON user_allergies
FOR EACH ROW
BEGIN
    DECLARE v_recipe_count INT;
    
    -- Count completed recipes that contain this allergen
    SELECT COUNT(DISTINCT cr.recipe_id)
    INTO v_recipe_count
    FROM completed_recipes cr
    INNER JOIN recipe_ingredients ri ON cr.recipe_id = ri.recipe_id
    INNER JOIN ingredient_allergies ia ON ri.ingredient_id = ia.ingredient_id
    WHERE cr.user_id = NEW.user_id
    AND ia.allergy_id = NEW.allergy_id
    AND ri.is_optional = FALSE;
    
    -- If user has completed recipes with this allergen, log a warning
    IF v_recipe_count > 0 THEN
        INSERT INTO error_logs (
            error_type, 
            error_message, 
            error_details, 
            user_id, 
            occurred_at
        ) VALUES (
            'ALLERGY_RETROSPECTIVE_WARNING',
            CONCAT('User has completed ', v_recipe_count, ' recipes containing newly added allergen'),
            JSON_OBJECT(
                'allergy_id', NEW.allergy_id,
                'severity', NEW.severity,
                'affected_recipe_count', v_recipe_count
            ),
            NEW.user_id,
            NOW()
        );
    END IF;
END$$

-- =====================================================
-- RECIPE STEPS TRIGGERS
-- =====================================================

-- Trigger: Validate recipe step order
DROP TRIGGER IF EXISTS trg_before_recipe_step_insert$$
CREATE TRIGGER trg_before_recipe_step_insert
BEFORE INSERT ON recipe_steps
FOR EACH ROW
BEGIN
    DECLARE v_max_order INT;
    
    -- Get the current maximum step order for this recipe
    SELECT COALESCE(MAX(step_order), 0)
    INTO v_max_order
    FROM recipe_steps
    WHERE recipe_id = NEW.recipe_id;
    
    -- Ensure step order is sequential
    IF NEW.step_order > v_max_order + 1 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Recipe step order must be sequential';
    END IF;
    
    -- Validate duration
    IF NEW.duration_minutes < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Step duration cannot be negative';
    END IF;
END$$

-- =====================================================
-- ERROR LOG TRIGGERS
-- =====================================================

-- Trigger: Auto-escalate critical errors
DROP TRIGGER IF EXISTS trg_after_error_insert$$
CREATE TRIGGER trg_after_error_insert
AFTER INSERT ON error_logs
FOR EACH ROW
BEGIN
    DECLARE v_error_count INT;
    
    -- Count similar unresolved errors in the last hour
    SELECT COUNT(*)
    INTO v_error_count
    FROM error_logs
    WHERE error_type = NEW.error_type
    AND resolved = FALSE
    AND occurred_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR);
    
    -- If more than 10 similar errors in an hour, create escalation
    IF v_error_count > 10 THEN
        -- Update the error as critical
        UPDATE error_logs
        SET error_message = CONCAT('[CRITICAL - ESCALATED] ', error_message)
        WHERE error_id = NEW.error_id;
    END IF;
END$$

-- =====================================================
-- DATA INTEGRITY TRIGGERS
-- =====================================================

-- Trigger: Prevent deletion of users with active recipes
DROP TRIGGER IF EXISTS trg_before_user_soft_delete$$
CREATE TRIGGER trg_before_user_soft_delete
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    DECLARE v_published_recipes INT;
    
    -- If user is being deactivated
    IF OLD.is_active = TRUE AND NEW.is_active = FALSE THEN
        -- Count published recipes by this user
        SELECT COUNT(*)
        INTO v_published_recipes
        FROM recipes
        WHERE author_user_id = NEW.user_id
        AND is_published = TRUE;
        
        -- If user has published recipes, unpublish them
        IF v_published_recipes > 0 THEN
            UPDATE recipes
            SET is_published = FALSE
            WHERE author_user_id = NEW.user_id
            AND is_published = TRUE;
            
            -- Log this action
            INSERT INTO error_logs (
                error_type, 
                error_message, 
                error_details, 
                user_id, 
                occurred_at
            ) VALUES (
                'USER_DEACTIVATION_CASCADE',
                CONCAT('Unpublished ', v_published_recipes, ' recipes due to user deactivation'),
                JSON_OBJECT(
                    'affected_recipes', v_published_recipes,
                    'user_id', NEW.user_id
                ),
                NEW.user_id,
                NOW()
            );
        END IF;
    END IF;
END$$

-- =====================================================
-- PERFORMANCE MONITORING TRIGGERS
-- =====================================================

-- Trigger: Monitor slow recipe searches
DROP TRIGGER IF EXISTS trg_after_completed_recipe_insert$$
CREATE TRIGGER trg_after_completed_recipe_insert
AFTER INSERT ON completed_recipes
FOR EACH ROW
BEGIN
    DECLARE v_completion_count INT;
    DECLARE v_avg_rating DECIMAL(3,2);
    
    -- Get recipe statistics
    SELECT COUNT(*), AVG(rating)
    INTO v_completion_count, v_avg_rating
    FROM completed_recipes
    WHERE recipe_id = NEW.recipe_id;
    
    -- If recipe is popular (>100 completions) and highly rated (>4.5), flag for featuring
    IF v_completion_count > 100 AND v_avg_rating > 4.5 THEN
        INSERT INTO error_logs (
            error_type, 
            error_message, 
            error_details, 
            user_id, 
            occurred_at,
            resolved
        ) VALUES (
            'RECIPE_FEATURE_CANDIDATE',
            CONCAT('Recipe #', NEW.recipe_id, ' is a candidate for featuring'),
            JSON_OBJECT(
                'recipe_id', NEW.recipe_id,
                'completion_count', v_completion_count,
                'average_rating', v_avg_rating
            ),
            NULL,
            NOW(),
            FALSE
        );
    END IF;
END$$

DELIMITER ;