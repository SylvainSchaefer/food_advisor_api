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


-- Ajouter un ingrédient à une recette (auteur ou administrateur)
DROP PROCEDURE IF EXISTS sp_add_recipe_ingredient$$
CREATE PROCEDURE sp_add_recipe_ingredient(
    IN p_recipe_id INT,
    IN p_ingredient_id INT,
    IN p_quantity DECIMAL(10,2),
    IN p_is_optional BOOLEAN,
    IN p_user_id INT,
    IN p_user_role VARCHAR(20),
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

        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Vérifier si la recette existe et si l'utilisateur est autorisé
    IF NOT EXISTS (
        SELECT 1 FROM recipes 
        WHERE recipe_id = p_recipe_id 
        AND (author_user_id = p_user_id OR p_user_role = 'Administrator')
    ) THEN
        SET p_error_message = 'Recipe not found or you are not authorized';
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



-- Récupérer toutes les recettes avec pagination
DROP PROCEDURE IF EXISTS sp_get_all_recipes$$
CREATE PROCEDURE sp_get_all_recipes(
    IN p_page INT,
    IN p_page_size INT
)
BEGIN
    DECLARE v_sql_error TEXT;
    DECLARE v_sql_state CHAR(5) DEFAULT '00000';
    DECLARE v_mysql_errno INT DEFAULT 0;
    DECLARE v_offset INT;
    
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
                COALESCE(v_sql_error, 'Unknown error in sp_get_all_recipes'),
                JSON_OBJECT(
                    'sql_state', v_sql_state,
                    'mysql_errno', v_mysql_errno,
                    'operation', 'GET_ALL_RECIPES',
                    'page', p_page,
                    'page_size', p_page_size
                ),
                'sp_get_all_recipes',
                NULL
            );
        END;
        
        RESIGNAL;
    END;

    SET v_offset = (p_page - 1) * p_page_size;
    
    -- Nombre total de recettes publiées
    SELECT COUNT(*) as total_count
    FROM recipes
    WHERE is_published = TRUE;
    
    -- Requête principale avec pagination
    SELECT 
        r.recipe_id,
        r.title,
        r.description,
        r.servings,
        r.difficulty,
        r.image_url,
        r.author_user_id,
        r.is_published,
        r.created_at,
        r.updated_at,
        u.first_name as author_first_name,
        u.last_name as author_last_name
    FROM recipes r
    LEFT JOIN users u ON r.author_user_id = u.user_id
    WHERE r.is_published = TRUE
    ORDER BY r.created_at DESC
    LIMIT p_page_size OFFSET v_offset;
END$$

-- Récupérer une recette par ID avec ses ingrédients
DROP PROCEDURE IF EXISTS sp_get_recipe_by_id$$
CREATE PROCEDURE sp_get_recipe_by_id(
    IN p_recipe_id INT,
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
                'recipe_id', p_recipe_id,
                'operation', 'GET_RECIPE_BY_ID'
            ),
            'sp_get_recipe_by_id',
            NULL
        );
        
        RESIGNAL;
    END;
    
    SET p_error_message = NULL;
    
    -- Récupérer la recette
    SELECT 
        r.recipe_id,
        r.title,
        r.description,
        r.servings,
        r.difficulty,
        r.image_url,
        r.author_user_id,
        r.is_published,
        r.created_at,
        r.updated_at,
        u.first_name as author_first_name,
        u.last_name as author_last_name
    FROM recipes r
    LEFT JOIN users u ON r.author_user_id = u.user_id
    WHERE r.recipe_id = p_recipe_id;
    
    -- Récupérer les ingrédients de la recette
    SELECT 
        ri.recipe_id,
        ri.ingredient_id,
        i.name as ingredient_name,
        ri.quantity,
        i.measurement_unit,
        ri.is_optional,
        i.carbohydrates,
        i.proteins,
        i.fats,
        i.fibers,
        i.calories,
        i.price,
        i.weight
    FROM recipe_ingredients ri
    INNER JOIN ingredients i ON ri.ingredient_id = i.ingredient_id
    WHERE ri.recipe_id = p_recipe_id
    ORDER BY ri.recipe_id;
END$$

-- Récupérer les recettes d'un utilisateur
DROP PROCEDURE IF EXISTS sp_get_user_recipes$$
CREATE PROCEDURE sp_get_user_recipes(
    IN p_user_id INT,
    IN p_page INT,
    IN p_page_size INT
)
BEGIN
    DECLARE v_sql_error TEXT;
    DECLARE v_sql_state CHAR(5) DEFAULT '00000';
    DECLARE v_mysql_errno INT DEFAULT 0;
    DECLARE v_offset INT;
    
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
                COALESCE(v_sql_error, 'Unknown error in sp_get_user_recipes'),
                JSON_OBJECT(
                    'sql_state', v_sql_state,
                    'mysql_errno', v_mysql_errno,
                    'operation', 'GET_USER_RECIPES',
                    'user_id', p_user_id,
                    'page', p_page,
                    'page_size', p_page_size
                ),
                'sp_get_user_recipes',
                p_user_id
            );
        END;
        
        RESIGNAL;
    END;

    SET v_offset = (p_page - 1) * p_page_size;
    
    -- Nombre total de recettes de l'utilisateur
    SELECT COUNT(*) as total_count
    FROM recipes
    WHERE author_user_id = p_user_id;
    
    -- Requête principale avec pagination
    SELECT 
        r.recipe_id,
        r.title,
        r.description,
        r.servings,
        r.difficulty,
        r.image_url,
        r.author_user_id,
        r.is_published,
        r.created_at,
        r.updated_at
    FROM recipes r
    WHERE r.author_user_id = p_user_id
    ORDER BY r.created_at DESC
    LIMIT p_page_size OFFSET v_offset;
END$$


-- Modifier une recette (auteur ou administrateur)
DROP PROCEDURE IF EXISTS sp_update_recipe$$
CREATE PROCEDURE sp_update_recipe(
    IN p_recipe_id INT,
    IN p_title VARCHAR(255),
    IN p_description TEXT,
    IN p_servings INT,
    IN p_difficulty VARCHAR(20),
    IN p_image_url VARCHAR(500),
    IN p_is_published BOOLEAN,
    IN p_user_id INT,
    IN p_user_role VARCHAR(20),
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
                'recipe_id', p_recipe_id,
                'operation', 'UPDATE_RECIPE'
            ),
            'sp_update_recipe',
            p_user_id
        );
        
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Vérifier si la recette existe
    IF NOT EXISTS (SELECT 1 FROM recipes WHERE recipe_id = p_recipe_id) THEN
        SET p_error_message = 'Recipe not found';
        
        CALL sp_log_error(
            'RECIPE_NOT_FOUND',
            p_error_message,
            JSON_OBJECT('recipe_id', p_recipe_id, 'operation', 'UPDATE_RECIPE'),
            'sp_update_recipe',
            p_user_id
        );
        
        ROLLBACK;
    -- Vérifier si l'utilisateur est l'auteur OU un administrateur
    ELSEIF NOT EXISTS (
        SELECT 1 FROM recipes 
        WHERE recipe_id = p_recipe_id 
        AND (author_user_id = p_user_id OR p_user_role = 'Administrator')
    ) THEN
        SET p_error_message = 'You are not authorized to update this recipe';
        
        CALL sp_log_error(
            'RECIPE_AUTHORIZATION_ERROR',
            p_error_message,
            JSON_OBJECT('recipe_id', p_recipe_id, 'user_id', p_user_id, 'operation', 'UPDATE_RECIPE'),
            'sp_update_recipe',
            p_user_id
        );
        
        ROLLBACK;
    ELSE
        UPDATE recipes SET
            title = p_title,
            description = p_description,
            servings = p_servings,
            difficulty = p_difficulty,
            image_url = p_image_url,
            is_published = p_is_published,
            updated_at = NOW()
        WHERE recipe_id = p_recipe_id;
        
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
END$$



-- Supprimer une recette (auteur ou administrateur)
DROP PROCEDURE IF EXISTS sp_delete_recipe$$
CREATE PROCEDURE sp_delete_recipe(
    IN p_recipe_id INT,
    IN p_user_id INT,
    IN p_user_role VARCHAR(20),
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
                'recipe_id', p_recipe_id,
                'operation', 'DELETE_RECIPE'
            ),
            'sp_delete_recipe',
            p_user_id
        );
        
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Vérifier si la recette existe
    IF NOT EXISTS (SELECT 1 FROM recipes WHERE recipe_id = p_recipe_id) THEN
        SET p_error_message = 'Recipe not found';
        
        CALL sp_log_error(
            'RECIPE_NOT_FOUND',
            p_error_message,
            JSON_OBJECT('recipe_id', p_recipe_id, 'operation', 'DELETE_RECIPE'),
            'sp_delete_recipe',
            p_user_id
        );
        
        ROLLBACK;
    -- Vérifier si l'utilisateur est l'auteur OU un administrateur
    ELSEIF NOT EXISTS (
        SELECT 1 FROM recipes 
        WHERE recipe_id = p_recipe_id 
        AND (author_user_id = p_user_id OR p_user_role = 'Administrator')
    ) THEN
        SET p_error_message = 'You are not authorized to delete this recipe';
        
        CALL sp_log_error(
            'RECIPE_AUTHORIZATION_ERROR',
            p_error_message,
            JSON_OBJECT('recipe_id', p_recipe_id, 'user_id', p_user_id, 'operation', 'DELETE_RECIPE'),
            'sp_delete_recipe',
            p_user_id
        );
        
        ROLLBACK;
    ELSE
        -- Supprimer d'abord les ingrédients liés
        DELETE FROM recipe_ingredients WHERE recipe_id = p_recipe_id;
        
        -- Supprimer la recette
        DELETE FROM recipes WHERE recipe_id = p_recipe_id;
        
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
END$$

-- Supprimer un ingrédient d'une recette (auteur ou administrateur)
DROP PROCEDURE IF EXISTS sp_remove_recipe_ingredient$$
CREATE PROCEDURE sp_remove_recipe_ingredient(
    IN p_recipe_id INT,
    IN p_ingredient_id INT,
    IN p_user_id INT,
    IN p_user_role VARCHAR(20),
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
                'recipe_id', p_recipe_id,
                'ingredient_id', p_ingredient_id,
                'operation', 'REMOVE_RECIPE_INGREDIENT'
            ),
            'sp_remove_recipe_ingredient',
            p_user_id
        );
        
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Vérifier si la recette existe et si l'utilisateur est autorisé
    IF NOT EXISTS (
        SELECT 1 FROM recipes 
        WHERE recipe_id = p_recipe_id 
        AND (author_user_id = p_user_id OR p_user_role = 'Administrator')
    ) THEN
        SET p_error_message = 'Recipe not found or you are not authorized';
        
        CALL sp_log_error(
            'RECIPE_AUTHORIZATION_ERROR',
            p_error_message,
            JSON_OBJECT(
                'recipe_id', p_recipe_id,
                'user_id', p_user_id,
                'operation', 'REMOVE_RECIPE_INGREDIENT'
            ),
            'sp_remove_recipe_ingredient',
            p_user_id
        );
        
        ROLLBACK;
    ELSE
        DELETE FROM recipe_ingredients 
        WHERE recipe_id = p_recipe_id AND ingredient_id = p_ingredient_id;
        
        SET p_error_message = NULL;
        COMMIT;
    END IF;
END$$

DELIMITER ;