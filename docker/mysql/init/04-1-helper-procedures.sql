USE food_advisor_db;

DELIMITER $$

-- =====================================================
-- CENTRALIZED ERROR LOGGING PROCEDURE
-- =====================================================

-- Helper procedure to log errors (can be called from any procedure)
DROP PROCEDURE IF EXISTS sp_log_error$$
CREATE PROCEDURE sp_log_error(
    IN p_error_type VARCHAR(100),
    IN p_error_message TEXT,
    IN p_error_details JSON,
    IN p_procedure_name VARCHAR(100),
    IN p_user_id INT
)
BEGIN
    -- Use CONTINUE handler to prevent recursion if logging fails
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        -- If error logging fails, silently continue
        -- This prevents infinite loops
    END;
    
    INSERT INTO error_logs (
        error_type,
        error_message,
        error_details,
        procedure_name,
        user_id,
        occurred_at,
        resolved
    ) VALUES (
        COALESCE(p_error_type, 'UNKNOWN_ERROR'),
        COALESCE(p_error_message, 'No error message provided'),
        p_error_details,
        p_procedure_name,
        p_user_id,
        NOW(),
        FALSE
    );
END$$

DELIMITER ;

