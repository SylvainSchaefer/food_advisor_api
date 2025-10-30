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


DELIMITER ;