USE food_advisor_db;

DELIMITER $$

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

