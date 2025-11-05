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



-- Récupérer l'image d'un ingrédient
DROP PROCEDURE IF EXISTS sp_get_ingredient_image$$
CREATE PROCEDURE sp_get_ingredient_image(
    IN p_ingredient_id INT UNSIGNED
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
        
        BEGIN
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;
            CALL sp_log_error(
                'SQL_EXCEPTION',
                COALESCE(v_sql_error, 'Unknown error in sp_get_ingredient_image'),
                JSON_OBJECT(
                    'sql_state', v_sql_state,
                    'mysql_errno', v_mysql_errno,
                    'operation', 'GET_INGREDIENT_IMAGE',
                    'ingredient_id', p_ingredient_id
                ),
                'sp_get_ingredient_image',
                NULL
            );
        END;
        RESIGNAL;
    END;
    
    -- Récupérer l'image primaire de l'ingrédient
    SELECT 
        i.image_id,
        i.entity_type,
        i.entity_id,
        i.image_data,
        i.image_name,
        i.image_type,
        i.image_size,
        i.width,
        i.height,
        i.is_primary,
        i.alt_text,
        i.uploaded_by_user_id,
        i.created_at,
        i.updated_at
    FROM images i
    WHERE i.entity_type = 'ingredient'
        AND i.entity_id = p_ingredient_id
        AND i.is_primary = TRUE
    LIMIT 1;
END$$




-- Ajouter une image pour un ingrédient (seuls les administrateurs)
DROP PROCEDURE IF EXISTS sp_add_ingredient_image$$
CREATE PROCEDURE sp_add_ingredient_image(
    IN p_ingredient_id INT UNSIGNED,
    IN p_image_data MEDIUMBLOB,
    IN p_image_name VARCHAR(255),
    IN p_image_type VARCHAR(50),
    IN p_image_size INT UNSIGNED,
    IN p_width INT UNSIGNED,
    IN p_height INT UNSIGNED,
    IN p_is_primary BOOLEAN,
    IN p_alt_text VARCHAR(500),
    IN p_uploaded_by_user_id INT UNSIGNED,
    IN p_user_role VARCHAR(20),
    OUT p_image_id INT UNSIGNED,
    OUT p_error_msg VARCHAR(500)
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
        
        SET p_error_msg = COALESCE(v_sql_error, 'Unknown error in sp_add_ingredient_image');
        SET p_image_id = NULL;
        
        BEGIN
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;
            CALL sp_log_error(
                'SQL_EXCEPTION',
                p_error_msg,
                JSON_OBJECT(
                    'sql_state', v_sql_state,
                    'mysql_errno', v_mysql_errno,
                    'operation', 'ADD_INGREDIENT_IMAGE',
                    'ingredient_id', p_ingredient_id,
                    'user_id', p_uploaded_by_user_id
                ),
                'sp_add_ingredient_image',
                p_uploaded_by_user_id
            );
        END;
    END;
    
    START TRANSACTION;
    
    -- Vérifier que l'utilisateur est administrateur
    IF p_user_role != 'Administrator' THEN
        SET p_error_msg = 'Only administrators can add ingredient images';
        SET p_image_id = NULL;
        
        BEGIN
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;
            CALL sp_log_error(
                'INGREDIENT_AUTHORIZATION_ERROR',
                p_error_msg,
                JSON_OBJECT(
                    'ingredient_id', p_ingredient_id,
                    'user_id', p_uploaded_by_user_id,
                    'user_role', p_user_role,
                    'operation', 'ADD_INGREDIENT_IMAGE'
                ),
                'sp_add_ingredient_image',
                p_uploaded_by_user_id
            );
        END;
        
        ROLLBACK;
    ELSE
        -- Vérifier que l'ingrédient existe
        IF NOT EXISTS (SELECT 1 FROM ingredients WHERE ingredient_id = p_ingredient_id) THEN
            SET p_error_msg = 'Ingredient not found';
            SET p_image_id = NULL;
            ROLLBACK;
        ELSE
            -- Si c'est une image primaire, retirer le statut primaire des autres images
            IF p_is_primary = TRUE THEN
                UPDATE images
                SET is_primary = FALSE
                WHERE entity_type = 'ingredient'
                    AND entity_id = p_ingredient_id;
            END IF;
            
            -- Insérer la nouvelle image
            INSERT INTO images (
                entity_type,
                entity_id,
                image_data,
                image_name,
                image_type,
                image_size,
                width,
                height,
                is_primary,
                alt_text,
                uploaded_by_user_id
            ) VALUES (
                'ingredient',
                p_ingredient_id,
                p_image_data,
                p_image_name,
                p_image_type,
                p_image_size,
                p_width,
                p_height,
                p_is_primary,
                p_alt_text,
                p_uploaded_by_user_id
            );
            
            SET p_image_id = LAST_INSERT_ID();
            SET p_error_msg = NULL;
            
            COMMIT;
        END IF;
    END IF;
END$$

DELIMITER ;