USE food_advisor_db;

DELIMITER $$


-- =====================================================
-- INGREDIENT PROCEDURES WITH ENHANCED ERROR LOGGING
-- =====================================================

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
        SET p_ingredient_id = NULL;
        
        CALL sp_log_error(
            'SQL_EXCEPTION',
            p_error_message,
            JSON_OBJECT(
                'sql_state', v_sql_state,
                'mysql_errno', v_mysql_errno,
                'ingredient_name', COALESCE(p_name, 'NULL'),
                'operation', 'CREATE_INGREDIENT'
            ),
            'sp_create_ingredient',
            p_created_by_user_id
        );

        -- Re-raise the error to propagate it to the calling code
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    IF EXISTS (SELECT 1 FROM ingredients WHERE name = p_name) THEN
        SET p_error_message = 'Ingredient with this name already exists';
        SET p_ingredient_id = NULL;
        
        CALL sp_log_error(
            'DUPLICATE_INGREDIENT',
            p_error_message,
            JSON_OBJECT('ingredient_name', p_name, 'operation', 'CREATE_INGREDIENT'),
            'sp_create_ingredient',
            p_created_by_user_id
        );
        
        ROLLBACK;
    ELSE
        INSERT INTO ingredients (
            name, carbohydrates, proteins, fats, fibers, 
            calories, price, weight, measurement_unit
        ) VALUES (
            p_name, p_carbohydrates, p_proteins, p_fats, p_fibers,
            p_calories, p_price, p_weight, p_measurement_unit
        );
        
        SET p_ingredient_id = LAST_INSERT_ID();
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
END$$


-- Récupérer un ingrédient par ID
DROP PROCEDURE IF EXISTS sp_get_ingredient$$
CREATE PROCEDURE sp_get_ingredient(
    IN p_ingredient_id INT,
    OUT p_error_message VARCHAR(500)
)
BEGIN
    DECLARE v_sql_error TEXT;
    DECLARE v_sql_state CHAR(5) DEFAULT '00000';
    DECLARE v_mysql_errno INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_sql_state = RETURNED_SQLSTATE,
            v_mysql_errno = MYSQL_ERRNO,
            v_sql_error = MESSAGE_TEXT;
        
        SET p_error_message = COALESCE(v_sql_error, 'Unknown SQL error occurred');
        
        CALL sp_log_error(
            'SQL_EXCEPTION',
            p_error_message,
            JSON_OBJECT(
                'sql_state', v_sql_state,
                'mysql_errno', v_mysql_errno,
                'ingredient_id', p_ingredient_id,
                'operation', 'GET_INGREDIENT'
            ),
            'sp_get_ingredient',
            NULL
        );
        
        RESIGNAL;
    END;
    
    SET p_error_message = NULL;
    
    SELECT * FROM ingredients WHERE ingredient_id = p_ingredient_id;
END$$
DROP PROCEDURE IF EXISTS sp_get_all_ingredients$$
CREATE PROCEDURE sp_get_all_ingredients(
    IN p_page INT,
    IN p_page_size INT
)
BEGIN
    DECLARE v_sql_error TEXT;
    DECLARE v_sql_state CHAR(5) DEFAULT '00000';
    DECLARE v_mysql_errno INT DEFAULT 0;
    DECLARE v_offset INT;
    
    -- Error handler for SQL exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_sql_state = RETURNED_SQLSTATE,
            v_mysql_errno = MYSQL_ERRNO,
            v_sql_error = MESSAGE_TEXT;
        
        BEGIN
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;
            CALL sp_log_error(
                'SQL_EXCEPTION',
                COALESCE(v_sql_error, 'Unknown error in sp_get_all_ingredients'),
                JSON_OBJECT(
                    'sql_state', v_sql_state,
                    'mysql_errno', v_mysql_errno,
                    'operation', 'GET_ALL_INGREDIENTS',
                    'page', p_page,
                    'page_size', p_page_size
                ),
                'sp_get_all_ingredients',
                NULL
            );
        END;
        
        RESIGNAL;
    END;

    -- Calculer l'offset
    SET v_offset = (p_page - 1) * p_page_size;
    
    -- Requête pour obtenir le nombre total d'ingrédients
    SELECT COUNT(*) as total_count
    FROM ingredients;
    
    -- Requête principale avec pagination
    SELECT 
        ingredient_id,
        name,
        carbohydrates,
        proteins,
        fats,
        fibers,
        calories,
        price,
        weight,
        measurement_unit
    FROM ingredients
    ORDER BY name ASC
    LIMIT p_page_size OFFSET v_offset;
END$$

-- Modifier un ingrédient
DROP PROCEDURE IF EXISTS sp_update_ingredient$$
CREATE PROCEDURE sp_update_ingredient(
    IN p_ingredient_id INT,
    IN p_name VARCHAR(200),
    IN p_carbohydrates DECIMAL(8,2),
    IN p_proteins DECIMAL(8,2),
    IN p_fats DECIMAL(8,2),
    IN p_fibers DECIMAL(8,2),
    IN p_calories DECIMAL(8,2),
    IN p_price DECIMAL(10,2),
    IN p_weight DECIMAL(10,2),
    IN p_measurement_unit VARCHAR(20),
    IN p_updated_by_user_id INT,
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
        
        CALL sp_log_error(
            'SQL_EXCEPTION',
            p_error_message,
            JSON_OBJECT(
                'sql_state', v_sql_state,
                'mysql_errno', v_mysql_errno,
                'ingredient_id', p_ingredient_id,
                'ingredient_name', COALESCE(p_name, 'NULL'),
                'operation', 'UPDATE_INGREDIENT'
            ),
            'sp_update_ingredient',
            p_updated_by_user_id
        );
        
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Vérifier si l'ingrédient existe
    IF NOT EXISTS (SELECT 1 FROM ingredients WHERE ingredient_id = p_ingredient_id) THEN
        SET p_error_message = 'Ingredient not found';
        
        CALL sp_log_error(
            'INGREDIENT_NOT_FOUND',
            p_error_message,
            JSON_OBJECT('ingredient_id', p_ingredient_id, 'operation', 'UPDATE_INGREDIENT'),
            'sp_update_ingredient',
            p_updated_by_user_id
        );
        
        ROLLBACK;
    -- Vérifier si le nouveau nom existe déjà (pour un autre ingrédient)
    ELSEIF EXISTS (SELECT 1 FROM ingredients WHERE name = p_name AND ingredient_id != p_ingredient_id) THEN
        SET p_error_message = 'Ingredient with this name already exists';
        
        CALL sp_log_error(
            'DUPLICATE_INGREDIENT',
            p_error_message,
            JSON_OBJECT('ingredient_name', p_name, 'operation', 'UPDATE_INGREDIENT'),
            'sp_update_ingredient',
            p_updated_by_user_id
        );
        
        ROLLBACK;
    ELSE
        UPDATE ingredients SET
            name = p_name,
            carbohydrates = p_carbohydrates,
            proteins = p_proteins,
            fats = p_fats,
            fibers = p_fibers,
            calories = p_calories,
            price = p_price,
            weight = p_weight,
            measurement_unit = p_measurement_unit
        WHERE ingredient_id = p_ingredient_id;
        
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
END$$

-- Supprimer un ingrédient
DROP PROCEDURE IF EXISTS sp_delete_ingredient$$
CREATE PROCEDURE sp_delete_ingredient(
    IN p_ingredient_id INT,
    IN p_deleted_by_user_id INT,
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
        
        CALL sp_log_error(
            'SQL_EXCEPTION',
            p_error_message,
            JSON_OBJECT(
                'sql_state', v_sql_state,
                'mysql_errno', v_mysql_errno,
                'ingredient_id', p_ingredient_id,
                'operation', 'DELETE_INGREDIENT'
            ),
            'sp_delete_ingredient',
            p_deleted_by_user_id
        );
        
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Vérifier si l'ingrédient existe
    IF NOT EXISTS (SELECT 1 FROM ingredients WHERE ingredient_id = p_ingredient_id) THEN
        SET p_error_message = 'Ingredient not found';
        
        CALL sp_log_error(
            'INGREDIENT_NOT_FOUND',
            p_error_message,
            JSON_OBJECT('ingredient_id', p_ingredient_id, 'operation', 'DELETE_INGREDIENT'),
            'sp_delete_ingredient',
            p_deleted_by_user_id
        );
        
        ROLLBACK;
    ELSE
        DELETE FROM ingredients WHERE ingredient_id = p_ingredient_id;
        
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
END$$


DELIMITER ;