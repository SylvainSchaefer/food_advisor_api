USE food_advisor_db;

DELIMITER $$

-- =====================================================
-- GESTION DES CATÉGORIES D'INGRÉDIENTS
-- =====================================================

-- Récupérer toutes les catégories
DROP PROCEDURE IF EXISTS sp_get_all_categories$$
CREATE PROCEDURE sp_get_all_categories(
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
                'operation', 'GET_ALL_CATEGORIES'
            ),
            'sp_get_all_categories',
            NULL
        );
        
        RESIGNAL;
    END;
    
    SET p_error_message = NULL;
    
    SELECT 
        category_id,
        name,
        description,
        created_at,
        updated_at
    FROM ingredient_categories
    ORDER BY name;
END$$

-- Récupérer une catégorie par ID avec ses ingrédients
DROP PROCEDURE IF EXISTS sp_get_category_by_id$$
CREATE PROCEDURE sp_get_category_by_id(
    IN p_category_id INT,
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
                'category_id', p_category_id,
                'operation', 'GET_CATEGORY_BY_ID'
            ),
            'sp_get_category_by_id',
            NULL
        );
        
        RESIGNAL;
    END;
    
    SET p_error_message = NULL;
    
    -- Récupérer la catégorie
    SELECT 
        category_id,
        name,
        description,
        created_at,
        updated_at
    FROM ingredient_categories
    WHERE category_id = p_category_id;
    
    -- Récupérer les ingrédients de cette catégorie
    SELECT 
        i.ingredient_id,
        i.name as ingredient_name,
        i.carbohydrates,
        i.proteins,
        i.fats,
        i.fibers,
        i.calories,
        i.price,
        i.weight,
        i.measurement_unit
    FROM ingredients i
    INNER JOIN ingredient_category_assignments ica ON i.ingredient_id = ica.ingredient_id
    WHERE ica.category_id = p_category_id
    ORDER BY i.name;
END$$

-- Créer une catégorie
DROP PROCEDURE IF EXISTS sp_create_category$$
CREATE PROCEDURE sp_create_category(
    IN p_name VARCHAR(100),
    IN p_description TEXT,
    IN p_created_by_user_id INT,
    OUT p_category_id INT,
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
        SET p_category_id = NULL;
        
        CALL sp_log_error(
            'SQL_EXCEPTION',
            p_error_message,
            JSON_OBJECT(
                'sql_state', v_sql_state,
                'mysql_errno', v_mysql_errno,
                'category_name', COALESCE(p_name, 'NULL'),
                'operation', 'CREATE_CATEGORY'
            ),
            'sp_create_category',
            p_created_by_user_id
        );
        
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Vérifier si la catégorie existe déjà
    IF EXISTS (SELECT 1 FROM ingredient_categories WHERE name = p_name) THEN
        SET p_error_message = 'Category with this name already exists';
        SET p_category_id = NULL;
        
        CALL sp_log_error(
            'DUPLICATE_CATEGORY',
            p_error_message,
            JSON_OBJECT('category_name', p_name, 'operation', 'CREATE_CATEGORY'),
            'sp_create_category',
            p_created_by_user_id
        );
        
        ROLLBACK;
    ELSE
        INSERT INTO ingredient_categories (name, description)
        VALUES (p_name, p_description);
        
        SET p_category_id = LAST_INSERT_ID();
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
END$$

-- Modifier une catégorie
DROP PROCEDURE IF EXISTS sp_update_category$$
CREATE PROCEDURE sp_update_category(
    IN p_category_id INT,
    IN p_name VARCHAR(100),
    IN p_description TEXT,
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
                'category_id', p_category_id,
                'operation', 'UPDATE_CATEGORY'
            ),
            'sp_update_category',
            p_updated_by_user_id
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
            JSON_OBJECT('category_id', p_category_id, 'operation', 'UPDATE_CATEGORY'),
            'sp_update_category',
            p_updated_by_user_id
        );
        
        ROLLBACK;
    -- Vérifier si le nouveau nom existe déjà (pour une autre catégorie)
    ELSEIF EXISTS (SELECT 1 FROM ingredient_categories WHERE name = p_name AND category_id != p_category_id) THEN
        SET p_error_message = 'Category with this name already exists';
        
        CALL sp_log_error(
            'DUPLICATE_CATEGORY',
            p_error_message,
            JSON_OBJECT('category_name', p_name, 'operation', 'UPDATE_CATEGORY'),
            'sp_update_category',
            p_updated_by_user_id
        );
        
        ROLLBACK;
    ELSE
        UPDATE ingredient_categories SET
            name = p_name,
            description = p_description,
            updated_at = NOW()
        WHERE category_id = p_category_id;
        
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
END$$

-- Supprimer une catégorie
DROP PROCEDURE IF EXISTS sp_delete_category$$
CREATE PROCEDURE sp_delete_category(
    IN p_category_id INT,
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
                'category_id', p_category_id,
                'operation', 'DELETE_CATEGORY'
            ),
            'sp_delete_category',
            p_deleted_by_user_id
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
            JSON_OBJECT('category_id', p_category_id, 'operation', 'DELETE_CATEGORY'),
            'sp_delete_category',
            p_deleted_by_user_id
        );
        
        ROLLBACK;
    ELSE
        -- Les assignations seront supprimées automatiquement grâce à ON DELETE CASCADE
        DELETE FROM ingredient_categories WHERE category_id = p_category_id;
        
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
END$$

-- =====================================================
-- GESTION DES ASSIGNATIONS INGRÉDIENT-CATÉGORIE
-- =====================================================

-- Ajouter un ingrédient à une catégorie
DROP PROCEDURE IF EXISTS sp_add_ingredient_to_category$$
CREATE PROCEDURE sp_add_ingredient_to_category(
    IN p_category_id INT,
    IN p_ingredient_id INT,
    IN p_user_id INT,
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
                'category_id', p_category_id,
                'ingredient_id', p_ingredient_id,
                'operation', 'ADD_INGREDIENT_TO_CATEGORY'
            ),
            'sp_add_ingredient_to_category',
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
            JSON_OBJECT('category_id', p_category_id, 'operation', 'ADD_INGREDIENT_TO_CATEGORY'),
            'sp_add_ingredient_to_category',
            p_user_id
        );
        
        ROLLBACK;
    -- Vérifier si l'ingrédient existe
    ELSEIF NOT EXISTS (SELECT 1 FROM ingredients WHERE ingredient_id = p_ingredient_id) THEN
        SET p_error_message = 'Ingredient not found';
        
        CALL sp_log_error(
            'INGREDIENT_NOT_FOUND',
            p_error_message,
            JSON_OBJECT('ingredient_id', p_ingredient_id, 'operation', 'ADD_INGREDIENT_TO_CATEGORY'),
            'sp_add_ingredient_to_category',
            p_user_id
        );
        
        ROLLBACK;
    -- Vérifier si l'assignation existe déjà
    ELSEIF EXISTS (
        SELECT 1 FROM ingredient_category_assignments 
        WHERE category_id = p_category_id AND ingredient_id = p_ingredient_id
    ) THEN
        SET p_error_message = 'Ingredient already assigned to this category';
        
        CALL sp_log_error(
            'DUPLICATE_ASSIGNMENT',
            p_error_message,
            JSON_OBJECT(
                'category_id', p_category_id,
                'ingredient_id', p_ingredient_id,
                'operation', 'ADD_INGREDIENT_TO_CATEGORY'
            ),
            'sp_add_ingredient_to_category',
            p_user_id
        );
        
        ROLLBACK;
    ELSE
        INSERT INTO ingredient_category_assignments (ingredient_id, category_id)
        VALUES (p_ingredient_id, p_category_id);
        
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
END$$

-- Supprimer un ingrédient d'une catégorie
DROP PROCEDURE IF EXISTS sp_remove_ingredient_from_category$$
CREATE PROCEDURE sp_remove_ingredient_from_category(
    IN p_category_id INT,
    IN p_ingredient_id INT,
    IN p_user_id INT,
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
                'category_id', p_category_id,
                'ingredient_id', p_ingredient_id,
                'operation', 'REMOVE_INGREDIENT_FROM_CATEGORY'
            ),
            'sp_remove_ingredient_from_category',
            p_user_id
        );
        
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Vérifier si l'assignation existe
    IF NOT EXISTS (
        SELECT 1 FROM ingredient_category_assignments 
        WHERE category_id = p_category_id AND ingredient_id = p_ingredient_id
    ) THEN
        SET p_error_message = 'Assignment not found';
        
        CALL sp_log_error(
            'ASSIGNMENT_NOT_FOUND',
            p_error_message,
            JSON_OBJECT(
                'category_id', p_category_id,
                'ingredient_id', p_ingredient_id,
                'operation', 'REMOVE_INGREDIENT_FROM_CATEGORY'
            ),
            'sp_remove_ingredient_from_category',
            p_user_id
        );
        
        ROLLBACK;
    ELSE
        DELETE FROM ingredient_category_assignments 
        WHERE category_id = p_category_id AND ingredient_id = p_ingredient_id;
        
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
END$$

-- Récupérer tous les ingrédients d'une catégorie
DROP PROCEDURE IF EXISTS sp_get_category_ingredients$$
CREATE PROCEDURE sp_get_category_ingredients(
    IN p_category_id INT,
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
                'category_id', p_category_id,
                'operation', 'GET_CATEGORY_INGREDIENTS'
            ),
            'sp_get_category_ingredients',
            NULL
        );
        
        RESIGNAL;
    END;
    
    SET p_error_message = NULL;
    
    SELECT 
        i.ingredient_id,
        i.name,
        i.carbohydrates,
        i.proteins,
        i.fats,
        i.fibers,
        i.calories,
        i.price,
        i.weight,
        i.measurement_unit
    FROM ingredients i
    INNER JOIN ingredient_category_assignments ica ON i.ingredient_id = ica.ingredient_id
    WHERE ica.category_id = p_category_id
    ORDER BY i.name;
END$$

DELIMITER ;