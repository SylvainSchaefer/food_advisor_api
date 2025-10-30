USE food_advisor_db;

DELIMITER $$

-- =====================================================
-- USER PROCEDURES WITH ENHANCED ERROR LOGGING
-- =====================================================


DROP PROCEDURE IF EXISTS sp_get_user_by_email$$
CREATE PROCEDURE sp_get_user_by_email(
    IN p_email VARCHAR(255)
)
BEGIN
    DECLARE v_sql_error TEXT;
    DECLARE v_sql_state CHAR(5) DEFAULT '00000';
    DECLARE v_mysql_errno INT DEFAULT 0;
    
    -- Error handler for SQL exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Capture error details
        GET DIAGNOSTICS CONDITION 1
            v_sql_state = RETURNED_SQLSTATE,
            v_mysql_errno = MYSQL_ERRNO,
            v_sql_error = MESSAGE_TEXT;
        
        -- Log the error (with CONTINUE handler to prevent recursion)
        BEGIN
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;
            
            CALL sp_log_error(
                'SQL_EXCEPTION',
                COALESCE(v_sql_error, 'Unknown error in sp_get_user_by_email'),
                JSON_OBJECT(
                    'sql_state', v_sql_state,
                    'mysql_errno', v_mysql_errno,
                    'email', COALESCE(p_email, 'NULL'),
                    'operation', 'GET_USER_BY_EMAIL'
                ),
                'sp_get_user_by_email',
                NULL
            );
        END;
        
        -- Re-raise the error to propagate it to the calling code
        RESIGNAL;
    END;
    
    -- Validate input
    IF p_email IS NULL OR LENGTH(TRIM(p_email)) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email parameter is required';
    END IF;
    
    -- Main query
    SELECT 
        user_id,
        first_name,
        last_name,
        gender,
        password_hash,
        email,
        role,
        country,
        city,
        is_active,
        birth_date,
        created_at,
        updated_at
    FROM users 
    WHERE email = p_email
    LIMIT 1;
    
END$$




DROP PROCEDURE IF EXISTS sp_get_user_by_id$$
CREATE PROCEDURE sp_get_user_by_id(
    IN p_id VARCHAR(255)
)
BEGIN
    DECLARE v_sql_error TEXT;
    DECLARE v_sql_state CHAR(5) DEFAULT '00000';
    DECLARE v_mysql_errno INT DEFAULT 0;
    
    -- Error handler for SQL exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Capture error details
        GET DIAGNOSTICS CONDITION 1
            v_sql_state = RETURNED_SQLSTATE,
            v_mysql_errno = MYSQL_ERRNO,
            v_sql_error = MESSAGE_TEXT;
        
        -- Log the error (with CONTINUE handler to prevent recursion)
        BEGIN
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;
            
            CALL sp_log_error(
                'SQL_EXCEPTION',
                COALESCE(v_sql_error, 'Unknown error in sp_get_user_by_id'),
                JSON_OBJECT(
                    'sql_state', v_sql_state,
                    'mysql_errno', v_mysql_errno,
                    'user_id', COALESCE(p_id, 'NULL'),
                    'operation', 'GET_USER_BY_ID'
                ),
                'sp_get_user_by_id',
                NULL
            );
        END;
        
        -- Re-raise the error to propagate it to the calling code
        RESIGNAL;
    END;
    
    -- Validate input
    IF p_id IS NULL OR LENGTH(TRIM(p_id)) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User_id parameter is required';
    END IF;
    
    -- Main query
    SELECT 
        user_id,
        first_name,
        last_name,
        gender,
        password_hash,
        email,
        role,
        country,
        city,
        is_active,
        birth_date,
        created_at,
        updated_at
    FROM users 
    WHERE user_id = p_id
    LIMIT 1;
    
END$$

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
    DECLARE v_sql_error TEXT;
    DECLARE v_sql_state CHAR(5) DEFAULT '00000';
    DECLARE v_mysql_errno INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        
        -- Capture error details
        GET DIAGNOSTICS CONDITION 1
            v_sql_state = RETURNED_SQLSTATE,
            v_mysql_errno = MYSQL_ERRNO,
            v_sql_error = MESSAGE_TEXT;
        
        SET p_error_message = COALESCE(v_sql_error, 'Unknown SQL error occurred');
        SET p_user_id = NULL;
        
        -- Log the error using helper procedure
        CALL sp_log_error(
            'SQL_EXCEPTION',
            p_error_message,
            JSON_OBJECT(
                'sql_state', v_sql_state,
                'mysql_errno', v_mysql_errno,
                'email', COALESCE(p_email, 'NULL'),
                'first_name', COALESCE(p_first_name, 'NULL'),
                'last_name', COALESCE(p_last_name, 'NULL'),
                'operation', 'CREATE_USER'
            ),
            'sp_create_user',
            NULL
        );
        -- Re-raise the error to propagate it to the calling code
        RESIGNAL;
    END;
    
    SET p_user_id = NULL;
    SET p_error_message = NULL;
    
    START TRANSACTION;
    
    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        SET p_error_message = 'Email already exists';
        SET p_user_id = NULL;
        
        -- Log business logic error
        CALL sp_log_error(
            'DUPLICATE_EMAIL',
            p_error_message,
            JSON_OBJECT('email', p_email, 'operation', 'CREATE_USER'),
            'sp_create_user',
            NULL
        );
        
        ROLLBACK;
    ELSE
        -- Insert new user (trigger will handle validation)
        INSERT INTO users (
            first_name, last_name, gender, password_hash, email, 
            role, country, city, birth_date, is_active
        ) VALUES (
            p_first_name, p_last_name, p_gender, p_password, p_email,
            COALESCE(p_role, 'Regular'), p_country, p_city, p_birth_date, TRUE
        );
        
        SET p_user_id = LAST_INSERT_ID();
        SET p_error_message = NULL;
        
        COMMIT;
    END IF;
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
                'user_id', p_user_id,
                'changed_by', p_changed_by_user_id,
                'operation', 'UPDATE_USER'
            ),
            'sp_update_user',
            p_changed_by_user_id
        );

        -- Re-raise the error to propagate it to the calling code
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = p_user_id AND is_active = TRUE) THEN
        SET p_error_message = 'User not found or inactive';
        SET p_success = FALSE;
        
        CALL sp_log_error(
            'USER_NOT_FOUND',
            p_error_message,
            JSON_OBJECT('user_id', p_user_id, 'operation', 'UPDATE_USER'),
            'sp_update_user',
            p_changed_by_user_id
        );
        
        ROLLBACK;
    ELSE
        UPDATE users
        SET 
            first_name = COALESCE(p_first_name, first_name),
            last_name = COALESCE(p_last_name, last_name),
            country = COALESCE(p_country, country),
            city = COALESCE(p_city, city)
        WHERE user_id = p_user_id;
        
        SET p_success = TRUE;
        SET p_error_message = NULL;
        COMMIT;
    END IF;
END$$






DROP PROCEDURE IF EXISTS sp_get_all_user$$
CREATE PROCEDURE sp_get_all_user(
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
                COALESCE(v_sql_error, 'Unknown error in sp_get_all_user'),
                JSON_OBJECT(
                    'sql_state', v_sql_state,
                    'mysql_errno', v_mysql_errno,
                    'operation', 'GET_ALL_USER',
                    'page', p_page,
                    'page_size', p_page_size
                ),
                'sp_get_all_user',
                NULL
            );
        END;
        
        RESIGNAL;
    END;


    -- Calculer l'offset
    SET v_offset = (p_page - 1) * p_page_size;
    
    -- Requête pour obtenir le nombre total d'utilisateurs
    SELECT COUNT(*) as total_count
    FROM users;
    
    -- Requête principale avec pagination
    SELECT 
        user_id,
        first_name,
        last_name,
        gender,
        password_hash,
        email,
        role,
        country,
        city,
        is_active,
        birth_date,
        created_at,
        updated_at
    FROM users
    ORDER BY created_at DESC
    LIMIT p_page_size OFFSET v_offset;
END$$



DELIMITER ;

