USE food_advisor_db;

DELIMITER $$


-- =====================================================
-- RECIPE PROCEDURES WITH ENHANCED ERROR LOGGING
-- =====================================================

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
    DECLARE v_sql_error TEXT;
    DECLARE v_sql_state CHAR(5) DEFAULT '00000';
    DECLARE v_mysql_errno INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        
        GET DIAGNOSTICS CONDITION 1
            v_sql_state = RETURNED_SQLSTATE,
            v_mysql_errno = MYSQL_ERRNO,
            v_sql_error = MESSAGE_TEXT;
        
        SET p_error_message = COALESCE(v_sql_error, 'Unknown SQL error occurred');
        SET p_recipe_id = NULL;
        
        CALL sp_log_error(
            'SQL_EXCEPTION',
            p_error_message,
            JSON_OBJECT(
                'sql_state', v_sql_state,
                'mysql_errno', v_mysql_errno,
                'recipe_title', COALESCE(p_title, 'NULL'),
                'author_user_id', p_author_user_id,
                'operation', 'CREATE_RECIPE'
            ),
            'sp_create_recipe',
            p_author_user_id
        );

        -- Re-raise the error to propagate it to the calling code
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    INSERT INTO recipes (
        title, description, servings, difficulty, 
        image_url, author_user_id, is_published
    ) VALUES (
        p_title, p_description, p_servings, p_difficulty,
        p_image_url, p_author_user_id, p_is_published
    );
    
    SET p_recipe_id = LAST_INSERT_ID();
    SET p_error_message = NULL;
    
    -- Log performance
    SET v_execution_time = (UNIX_TIMESTAMP(NOW(6)) * 1000) - v_start_time;
    INSERT INTO performance_logs (procedure_name, execution_time_ms, user_id, logged_at)
    VALUES ('sp_create_recipe', v_execution_time, p_author_user_id, NOW());
    
    COMMIT;
END$$

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
    DECLARE v_sql_error TEXT;
    DECLARE v_sql_state CHAR(5) DEFAULT '00000';
    DECLARE v_mysql_errno INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        
        GET DIAGNOSTICS CONDITION 1
            v_sql_state = RETURNED_SQLSTATE,
            v_mysql_errno = MYSQL_ERRNO,
            v_sql_error = MESSAGE_TEXT;
        
        SET p_error_message = COALESCE(v_sql_error, 'Unknown SQL error occurred');
        SET p_success = FALSE;
        
        CALL sp_log_error(
            'SQL_EXCEPTION',
            p_error_message,
            JSON_OBJECT(
                'sql_state', v_sql_state,
                'mysql_errno', v_mysql_errno,
                'recipe_id', p_recipe_id,
                'ingredient_id', p_ingredient_id,
                'operation', 'ADD_RECIPE_INGREDIENT'
            ),
            'sp_add_recipe_ingredient',
            p_user_id
        );

        -- Re-raise the error to propagate it to the calling code
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    IF NOT EXISTS (
        SELECT 1 FROM recipes 
        WHERE recipe_id = p_recipe_id AND author_user_id = p_user_id
    ) THEN
        SET p_error_message = 'Recipe not found or you are not the author';
        SET p_success = FALSE;
        
        CALL sp_log_error(
            'RECIPE_AUTHORIZATION_ERROR',
            p_error_message,
            JSON_OBJECT(
                'recipe_id', p_recipe_id,
                'user_id', p_user_id,
                'operation', 'ADD_RECIPE_INGREDIENT'
            ),
            'sp_add_recipe_ingredient',
            p_user_id
        );
        
        ROLLBACK;
    ELSE
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
    DECLARE v_sql_error TEXT;
    DECLARE v_sql_state CHAR(5) DEFAULT '00000';
    DECLARE v_mysql_errno INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        
        GET DIAGNOSTICS CONDITION 1
            v_sql_state = RETURNED_SQLSTATE,
            v_mysql_errno = MYSQL_ERRNO,
            v_sql_error = MESSAGE_TEXT;
        
        SET p_error_message = COALESCE(v_sql_error, 'Unknown SQL error occurred');
        SET p_completion_id = NULL;
        
        CALL sp_log_error(
            'SQL_EXCEPTION',
            p_error_message,
            JSON_OBJECT(
                'sql_state', v_sql_state,
                'mysql_errno', v_mysql_errno,
                'user_id', p_user_id,
                'recipe_id', p_recipe_id,
                'operation', 'COMPLETE_RECIPE'
            ),
            'sp_complete_recipe',
            p_user_id
        );

        -- Re-raise the error to propagate it to the calling code
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    IF p_rating IS NOT NULL AND (p_rating < 1 OR p_rating > 5) THEN
        SET p_error_message = 'Rating must be between 1 and 5';
        SET p_completion_id = NULL;
        
        CALL sp_log_error(
            'INVALID_RATING',
            p_error_message,
            JSON_OBJECT(
                'rating', p_rating,
                'user_id', p_user_id,
                'recipe_id', p_recipe_id,
                'operation', 'COMPLETE_RECIPE'
            ),
            'sp_complete_recipe',
            p_user_id
        );
        
        ROLLBACK;
    ELSE
        INSERT INTO completed_recipes (user_id, recipe_id, rating, comment, completion_date)
        VALUES (p_user_id, p_recipe_id, p_rating, p_comment, NOW());
        
        SET p_completion_id = LAST_INSERT_ID();
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
END$$

-- =====================================================
-- STOCK MANAGEMENT WITH ENHANCED ERROR LOGGING
-- =====================================================

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
    DECLARE v_sql_error TEXT;
    DECLARE v_sql_state CHAR(5) DEFAULT '00000';
    DECLARE v_mysql_errno INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        
        GET DIAGNOSTICS CONDITION 1
            v_sql_state = RETURNED_SQLSTATE,
            v_mysql_errno = MYSQL_ERRNO,
            v_sql_error = MESSAGE_TEXT;
        
        SET p_error_message = COALESCE(v_sql_error, 'Unknown SQL error occurred');
        SET p_stock_id = NULL;
        
        CALL sp_log_error(
            'SQL_EXCEPTION',
            p_error_message,
            JSON_OBJECT(
                'sql_state', v_sql_state,
                'mysql_errno', v_mysql_errno,
                'user_id', p_user_id,
                'ingredient_id', p_ingredient_id,
                'operation', CONCAT('STOCK_', UPPER(p_operation))
            ),
            'sp_manage_user_stock',
            p_user_id
        );

        -- Re-raise the error to propagate it to the calling code
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
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
                UPDATE user_ingredient_stock
                SET quantity = quantity + p_quantity,
                    expiration_date = LEAST(COALESCE(expiration_date, p_expiration_date), p_expiration_date)
                WHERE stock_id = v_existing_stock_id;
                SET p_stock_id = v_existing_stock_id;
            ELSE
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
                
                CALL sp_log_error(
                    'STOCK_NOT_FOUND',
                    p_error_message,
                    JSON_OBJECT(
                        'user_id', p_user_id,
                        'ingredient_id', p_ingredient_id,
                        'operation', 'STOCK_UPDATE'
                    ),
                    'sp_manage_user_stock',
                    p_user_id
                );
                
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
                
                CALL sp_log_error(
                    'STOCK_NOT_FOUND',
                    p_error_message,
                    JSON_OBJECT(
                        'user_id', p_user_id,
                        'ingredient_id', p_ingredient_id,
                        'operation', 'STOCK_REMOVE'
                    ),
                    'sp_manage_user_stock',
                    p_user_id
                );
                
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

DELIMITER ;

