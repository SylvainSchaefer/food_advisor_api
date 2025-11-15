USE food_advisor_db;

DELIMITER $$

-- =====================================================
-- PRÉFÉRENCES DE CATÉGORIES D'INGRÉDIENTS
-- =====================================================

-- Ajouter ou mettre à jour une préférence de catégorie
DROP PROCEDURE IF EXISTS sp_set_category_preference$$
CREATE PROCEDURE sp_set_category_preference(
    IN p_user_id INT,
    IN p_category_id INT,
    IN p_preference_type VARCHAR(20),
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
                'user_id', p_user_id,
                'category_id', p_category_id,
                'operation', 'SET_CATEGORY_PREFERENCE'
            ),
            'sp_set_category_preference',
            p_user_id
        );
        
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Vérifier si la catégorie existe
    IF NOT EXISTS (SELECT 1 FROM ingredient_categories WHERE category_id = p_category_id) THEN
        SET p_error_message = 'Category not found';
        
        CALL sp_log_error(
            'CATEGORY_NOT_FOUND',
            p_error_message,
            JSON_OBJECT('category_id', p_category_id, 'operation', 'SET_CATEGORY_PREFERENCE'),
            'sp_set_category_preference',
            p_user_id
        );
        
        ROLLBACK;
    ELSEIF p_preference_type NOT IN ('excluded', 'preferred') THEN
        SET p_error_message = 'Invalid preference type. Must be excluded or preferred';
        
        CALL sp_log_error(
            'INVALID_PREFERENCE_TYPE',
            p_error_message,
            JSON_OBJECT('preference_type', p_preference_type, 'operation', 'SET_CATEGORY_PREFERENCE'),
            'sp_set_category_preference',
            p_user_id
        );
        
        ROLLBACK;
    ELSE
        -- Insérer ou mettre à jour la préférence
        INSERT INTO user_ingredient_category_preferences (user_id, category_id, preference_type)
        VALUES (p_user_id, p_category_id, p_preference_type)
        ON DUPLICATE KEY UPDATE preference_type = p_preference_type;
        
        SET p_error_message = NULL;
        COMMIT;
    END IF;
END$$

-- Supprimer une préférence de catégorie
DROP PROCEDURE IF EXISTS sp_remove_category_preference$$
CREATE PROCEDURE sp_remove_category_preference(
    IN p_user_id INT,
    IN p_category_id INT,
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
                'user_id', p_user_id,
                'category_id', p_category_id,
                'operation', 'REMOVE_CATEGORY_PREFERENCE'
            ),
            'sp_remove_category_preference',
            p_user_id
        );
        
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    DELETE FROM user_ingredient_category_preferences 
    WHERE user_id = p_user_id AND category_id = p_category_id;
    
    SET p_error_message = NULL;
    COMMIT;
END$$

-- Récupérer toutes les préférences de catégories d'un utilisateur
DROP PROCEDURE IF EXISTS sp_get_user_category_preferences$$
CREATE PROCEDURE sp_get_user_category_preferences(
    IN p_user_id INT,
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
                'user_id', p_user_id,
                'operation', 'GET_USER_CATEGORY_PREFERENCES'
            ),
            'sp_get_user_category_preferences',
            p_user_id
        );
        
        RESIGNAL;
    END;
    
    SET p_error_message = NULL;
    
    SELECT 
        ucp.user_id,
        ucp.category_id,
        ic.name as category_name,
        ic.description as category_description,
        ucp.preference_type,
        ucp.created_at
    FROM user_ingredient_category_preferences ucp
    INNER JOIN ingredient_categories ic ON ucp.category_id = ic.category_id
    WHERE ucp.user_id = p_user_id
    ORDER BY ic.name;
END$$

-- =====================================================
-- PRÉFÉRENCES D'INGRÉDIENTS
-- =====================================================

-- Ajouter ou mettre à jour une préférence d'ingrédient
DROP PROCEDURE IF EXISTS sp_set_ingredient_preference$$
CREATE PROCEDURE sp_set_ingredient_preference(
    IN p_user_id INT,
    IN p_ingredient_id INT,
    IN p_preference_type VARCHAR(20),
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
                'user_id', p_user_id,
                'ingredient_id', p_ingredient_id,
                'operation', 'SET_INGREDIENT_PREFERENCE'
            ),
            'sp_set_ingredient_preference',
            p_user_id
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
            JSON_OBJECT('ingredient_id', p_ingredient_id, 'operation', 'SET_INGREDIENT_PREFERENCE'),
            'sp_set_ingredient_preference',
            p_user_id
        );
        
        ROLLBACK;
    ELSEIF p_preference_type NOT IN ('excluded', 'preferred') THEN
        SET p_error_message = 'Invalid preference type. Must be excluded or preferred';
        
        CALL sp_log_error(
            'INVALID_PREFERENCE_TYPE',
            p_error_message,
            JSON_OBJECT('preference_type', p_preference_type, 'operation', 'SET_INGREDIENT_PREFERENCE'),
            'sp_set_ingredient_preference',
            p_user_id
        );
        
        ROLLBACK;
    ELSE
        -- Insérer ou mettre à jour la préférence
        INSERT INTO user_ingredient_preferences (user_id, ingredient_id, preference_type)
        VALUES (p_user_id, p_ingredient_id, p_preference_type)
        ON DUPLICATE KEY UPDATE preference_type = p_preference_type;
        
        SET p_error_message = NULL;
        COMMIT;
    END IF;
END$$

-- Supprimer une préférence d'ingrédient
DROP PROCEDURE IF EXISTS sp_remove_ingredient_preference$$
CREATE PROCEDURE sp_remove_ingredient_preference(
    IN p_user_id INT,
    IN p_ingredient_id INT,
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
                'user_id', p_user_id,
                'ingredient_id', p_ingredient_id,
                'operation', 'REMOVE_INGREDIENT_PREFERENCE'
            ),
            'sp_remove_ingredient_preference',
            p_user_id
        );
        
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    DELETE FROM user_ingredient_preferences 
    WHERE user_id = p_user_id AND ingredient_id = p_ingredient_id;
    
    SET p_error_message = NULL;
    COMMIT;
END$$

-- Récupérer toutes les préférences d'ingrédients d'un utilisateur
DROP PROCEDURE IF EXISTS sp_get_user_ingredient_preferences$$
CREATE PROCEDURE sp_get_user_ingredient_preferences(
    IN p_user_id INT,
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
                'user_id', p_user_id,
                'operation', 'GET_USER_INGREDIENT_PREFERENCES'
            ),
            'sp_get_user_ingredient_preferences',
            p_user_id
        );
        
        RESIGNAL;
    END;
    
    SET p_error_message = NULL;
    
    SELECT 
        uip.user_id,
        uip.ingredient_id,
        i.name as ingredient_name,
        uip.preference_type,
        uip.created_at
    FROM user_ingredient_preferences uip
    INNER JOIN ingredients i ON uip.ingredient_id = i.ingredient_id
    WHERE uip.user_id = p_user_id
    ORDER BY i.name;
END$$

-- Récupérer toutes les préférences d'un utilisateur (catégories + ingrédients)
DROP PROCEDURE IF EXISTS sp_get_all_user_preferences$$
CREATE PROCEDURE sp_get_all_user_preferences(
    IN p_user_id INT,
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
                'user_id', p_user_id,
                'operation', 'GET_ALL_USER_PREFERENCES'
            ),
            'sp_get_all_user_preferences',
            p_user_id
        );
        
        RESIGNAL;
    END;
    
    SET p_error_message = NULL;
    
    -- Préférences de catégories
    SELECT 
        ucp.user_id,
        ucp.category_id,
        ic.name as category_name,
        ic.description as category_description,
        ucp.preference_type,
        ucp.created_at
    FROM user_ingredient_category_preferences ucp
    INNER JOIN ingredient_categories ic ON ucp.category_id = ic.category_id
    WHERE ucp.user_id = p_user_id
    ORDER BY ic.name;
    
    -- Préférences d'ingrédients
    SELECT 
        uip.user_id,
        uip.ingredient_id,
        i.name as ingredient_name,
        uip.preference_type,
        uip.created_at
    FROM user_ingredient_preferences uip
    INNER JOIN ingredients i ON uip.ingredient_id = i.ingredient_id
    WHERE uip.user_id = p_user_id
    ORDER BY i.name;
END$$

DELIMITER ;