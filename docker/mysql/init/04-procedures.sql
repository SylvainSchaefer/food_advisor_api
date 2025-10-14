DELIMITER //



-- USERS
-- =============================================
-- Procedure: Find user by email
-- =============================================
CREATE PROCEDURE sp_get_user_by_email(
    IN p_email VARCHAR(255)
)
BEGIN
    SELECT 
        id,
        email,
        password_hash,
        last_name,
        first_name,
        date_of_birth,
        gender,
        city,
        postal_code,
        country,
        role,
        dietary_regimen_id,
        active,
        created_at,
        updated_at
    FROM users
    WHERE email = p_email;
END//


-- =============================================
-- Procedure: Find user by id
-- =============================================
CREATE PROCEDURE sp_get_user_by_id(
    IN p_id INT
)
BEGIN
    SELECT *
    FROM users
    WHERE id = p_id;
END//















-- =============================================
-- Procedure: User authentication
-- =============================================
CREATE PROCEDURE sp_authenticate_user(
    IN p_email VARCHAR(255),
    IN p_password VARCHAR(255)
)
BEGIN
    SELECT 
        id,
        email,
        last_name,
        first_name,
        role,
        active
    FROM users
    WHERE email = p_email 
        AND password_hash = p_password
        AND active = TRUE;
END//

-- =============================================
-- Procedure: Create new user
-- =============================================
CREATE PROCEDURE sp_create_user(
    IN p_email VARCHAR(255),
    IN p_password VARCHAR(255),
    IN p_last_name VARCHAR(100),
    IN p_first_name VARCHAR(100),
    IN p_date_of_birth DATE,
    IN p_city VARCHAR(100),
    OUT p_user_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error creating user';
    END;
    
    START TRANSACTION;
    
    INSERT INTO users (email, password_hash, last_name, first_name, date_of_birth, city)
    VALUES (p_email, p_password, p_last_name, p_first_name, p_date_of_birth, p_city);
    
    SET p_user_id = LAST_INSERT_ID();
    
    COMMIT;
END//

-- =============================================
-- Procedure: Recommend recipes
-- =============================================
CREATE PROCEDURE sp_recommend_recipes(
    IN p_user_id INT,
    IN p_stock_only BOOLEAN,
    IN p_limit INT,
    IN p_sort_order VARCHAR(20) -- 'rating', 'cost', 'time', 'recent'
)
BEGIN
    -- Temporary table to store scores
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_recipe_scores (
        recipe_id INT,
        score DECIMAL(10,2),
        compatible BOOLEAN DEFAULT TRUE,
        available_ingredients INT DEFAULT 0,
        total_ingredients INT DEFAULT 0,
        last_completion DATE
    );
    
    -- Reset temporary table
    TRUNCATE TABLE temp_recipe_scores;
    
    -- Calculate scores for each recipe
    INSERT INTO temp_recipe_scores (recipe_id, total_ingredients)
    SELECT 
        r.id,
        COUNT(DISTINCT ri.ingredient_id)
    FROM recipes r
    INNER JOIN recipe_ingredients ri ON r.id = ri.recipe_id
    WHERE r.published = TRUE
    GROUP BY r.id;
    
    -- Mark incompatible recipes (allergies, exclusions)
    UPDATE temp_recipe_scores trs
    SET compatible = FALSE
    WHERE EXISTS (
        SELECT 1 
        FROM recipe_ingredients ri
        INNER JOIN ingredient_preferences ip ON ri.ingredient_id = ip.ingredient_id
        WHERE ri.recipe_id = trs.recipe_id 
            AND ip.user_id = p_user_id
            AND ip.preference_type IN ('excluded', 'avoided')
    );
    
    -- Mark recipes with allergens
    UPDATE temp_recipe_scores trs
    SET compatible = FALSE
    WHERE EXISTS (
        SELECT 1 
        FROM recipe_ingredients ri
        INNER JOIN ingredient_allergens ia ON ri.ingredient_id = ia.ingredient_id
        INNER JOIN dietary_preferences dp ON ia.allergen_id = dp.allergen_id
        WHERE ri.recipe_id = trs.recipe_id 
            AND dp.user_id = p_user_id
    );
    
    -- If stock only, calculate available ingredients
    IF p_stock_only THEN
        UPDATE temp_recipe_scores trs
        SET available_ingredients = (
            SELECT COUNT(DISTINCT ri.ingredient_id)
            FROM recipe_ingredients ri
            INNER JOIN user_stock us ON ri.ingredient_id = us.ingredient_id
            WHERE ri.recipe_id = trs.recipe_id 
                AND us.user_id = p_user_id
                AND us.quantity >= ri.quantity
                AND (us.expiration_date IS NULL OR us.expiration_date > CURDATE())
        );
        
        -- Filter non-achievable recipes
        UPDATE temp_recipe_scores
        SET compatible = FALSE
        WHERE available_ingredients < total_ingredients;
    END IF;
    
    -- Get last completion date
    UPDATE temp_recipe_scores trs
    SET last_completion = (
        SELECT MAX(rh.completion_date)
        FROM recipe_history rh
        WHERE rh.recipe_id = trs.recipe_id 
            AND rh.user_id = p_user_id
    );
    
    -- Calculate final score
    UPDATE temp_recipe_scores trs
    INNER JOIN recipes r ON trs.recipe_id = r.id
    SET trs.score = 
        (r.average_rating * 20) +  -- Rating out of 100
        (CASE 
            WHEN trs.last_completion IS NULL THEN 50
            WHEN DATEDIFF(CURDATE(), trs.last_completion) > 30 THEN 40
            WHEN DATEDIFF(CURDATE(), trs.last_completion) > 14 THEN 20
            ELSE 0
        END) + -- Bonus if not recently completed
        (CASE 
            WHEN p_stock_only THEN (trs.available_ingredients / trs.total_ingredients * 30)
            ELSE 0
        END); -- Bonus if ingredients available
    
    -- Select recommended recipes
    SELECT 
        r.*,
        trs.score,
        trs.available_ingredients,
        trs.total_ingredients,
        trs.last_completion,
        CASE 
            WHEN fr.recipe_id IS NOT NULL THEN TRUE 
            ELSE FALSE 
        END AS is_favorite
    FROM temp_recipe_scores trs
    INNER JOIN recipes r ON trs.recipe_id = r.id
    LEFT JOIN favorite_recipes fr ON r.id = fr.recipe_id AND fr.user_id = p_user_id
    WHERE trs.compatible = TRUE
    ORDER BY 
        CASE 
            WHEN p_sort_order = 'rating' THEN r.average_rating
            WHEN p_sort_order = 'cost' THEN -r.estimated_cost
            WHEN p_sort_order = 'time' THEN -r.total_time
            ELSE trs.score
        END DESC
    LIMIT p_limit;
    
    DROP TEMPORARY TABLE IF EXISTS temp_recipe_scores;
END//

-- =============================================
-- Procedure: Complete a recipe
-- =============================================
CREATE PROCEDURE sp_complete_recipe(
    IN p_user_id INT,
    IN p_recipe_id INT,
    IN p_rating INT,
    IN p_update_stock BOOLEAN,
    IN p_servings INT
)
BEGIN
    DECLARE v_history_id INT;
    DECLARE v_serving_factor DECIMAL(5,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error completing recipe';
    END;
    
    START TRANSACTION;
    
    -- Calculate serving factor
    SELECT p_servings / servings INTO v_serving_factor
    FROM recipes 
    WHERE id = p_recipe_id;
    
    -- Add to history
    INSERT INTO recipe_history (
        user_id, 
        recipe_id, 
        rating, 
        servings_made, 
        stock_updated
    )
    VALUES (
        p_user_id, 
        p_recipe_id, 
        p_rating, 
        p_servings, 
        p_update_stock
    );
    
    SET v_history_id = LAST_INSERT_ID();
    
    -- Update stock if requested
    IF p_update_stock THEN
        UPDATE user_stock us
        INNER JOIN recipe_ingredients ri ON us.ingredient_id = ri.ingredient_id
        SET us.quantity = GREATEST(0, us.quantity - (ri.quantity * v_serving_factor))
        WHERE us.user_id = p_user_id 
            AND ri.recipe_id = p_recipe_id;
    END IF;
    
    -- Update recipe statistics
    UPDATE recipes
    SET 
        completion_count = completion_count + 1,
        average_rating = (
            SELECT AVG(rating)
            FROM recipe_history
            WHERE recipe_id = p_recipe_id AND rating IS NOT NULL
        ),
        rating_count = (
            SELECT COUNT(*)
            FROM recipe_history
            WHERE recipe_id = p_recipe_id AND rating IS NOT NULL
        )
    WHERE id = p_recipe_id;
    
    COMMIT;
    
    SELECT v_history_id AS history_id;
END//

-- =============================================
-- Procedure: Generate shopping list
-- =============================================
CREATE PROCEDURE sp_generate_shopping_list(
    IN p_user_id INT,
    IN p_recipe_ids TEXT, -- Comma-separated IDs
    IN p_servings_per_recipe TEXT, -- Comma-separated numbers
    IN p_list_name VARCHAR(100)
)
BEGIN
    DECLARE v_list_id INT;
    DECLARE v_recipe_id INT;
    DECLARE v_servings INT;
    DECLARE v_factor DECIMAL(5,2);
    DECLARE v_position INT DEFAULT 1;
    DECLARE v_recipe_count INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error generating shopping list';
    END;
    
    START TRANSACTION;
    
    -- Create shopping list
    INSERT INTO shopping_lists (user_id, name)
    VALUES (p_user_id, p_list_name);
    
    SET v_list_id = LAST_INSERT_ID();
    
    -- Temporary table for needed ingredients
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_ingredients_needed (
        ingredient_id INT,
        total_quantity DECIMAL(10,2),
        unit_of_measure VARCHAR(20),
        recipe_id INT
    );
    
    -- Calculate number of recipes
    SET v_recipe_count = (LENGTH(p_recipe_ids) - LENGTH(REPLACE(p_recipe_ids, ',', '')) + 1);
    
    -- Loop through each recipe
    WHILE v_position <= v_recipe_count DO
        -- Extract recipe ID and servings
        SET v_recipe_id = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(p_recipe_ids, ',', v_position), ',', -1) AS UNSIGNED);
        SET v_servings = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(p_servings_per_recipe, ',', v_position), ',', -1) AS UNSIGNED);
        
        -- Calculate serving factor
        SELECT v_servings / servings INTO v_factor
        FROM recipes 
        WHERE id = v_recipe_id;
        
        -- Add needed ingredients
        INSERT INTO temp_ingredients_needed (ingredient_id, total_quantity, unit_of_measure, recipe_id)
        SELECT 
            ri.ingredient_id,
            ri.quantity * v_factor,
            ri.unit_of_measure,
            v_recipe_id
        FROM recipe_ingredients ri
        WHERE ri.recipe_id = v_recipe_id AND ri.optional = FALSE
        ON DUPLICATE KEY UPDATE 
            total_quantity = total_quantity + (ri.quantity * v_factor);
        
        SET v_position = v_position + 1;
    END WHILE;
    
    -- Subtract available stock and add to list
    INSERT INTO shopping_list_ingredients (list_id, ingredient_id, quantity, unit_of_measure, recipe_id)
    SELECT 
        v_list_id,
        tin.ingredient_id,
        GREATEST(0, tin.total_quantity - COALESCE(
            (SELECT SUM(us.quantity)
             FROM user_stock us
             WHERE us.user_id = p_user_id 
                AND us.ingredient_id = tin.ingredient_id
                AND (us.expiration_date IS NULL OR us.expiration_date > CURDATE())
            ), 0
        )),
        tin.unit_of_measure,
        tin.recipe_id
    FROM temp_ingredients_needed tin
    WHERE tin.total_quantity > COALESCE(
        (SELECT SUM(us.quantity)
         FROM user_stock us
         WHERE us.user_id = p_user_id 
            AND us.ingredient_id = tin.ingredient_id
            AND (us.expiration_date IS NULL OR us.expiration_date > CURDATE())
        ), 0
    );
    
    DROP TEMPORARY TABLE IF EXISTS temp_ingredients_needed;
    
    COMMIT;
    
    SELECT v_list_id AS list_id;
END//

-- =============================================
-- Procedure: Check expired stock
-- =============================================
CREATE PROCEDURE sp_check_expired_stock(
    IN p_user_id INT,
    IN p_days_before_expiration INT
)
BEGIN
    SELECT 
        us.*,
        i.name AS ingredient_name,
        DATEDIFF(us.expiration_date, CURDATE()) AS days_remaining
    FROM user_stock us
    INNER JOIN ingredients i ON us.ingredient_id = i.id
    WHERE us.user_id = p_user_id
        AND us.expiration_date IS NOT NULL
        AND us.expiration_date <= DATE_ADD(CURDATE(), INTERVAL p_days_before_expiration DAY)
        AND us.quantity > 0
    ORDER BY us.expiration_date ASC;
END//

-- =============================================
-- Function: Calculate recipe cost
-- =============================================
CREATE FUNCTION fn_calculate_recipe_cost(p_recipe_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total_cost DECIMAL(10,2);
    
    SELECT COALESCE(SUM(ri.quantity * i.estimated_price / 
        CASE 
            WHEN ri.unit_of_measure = 'kg' AND i.unit_of_measure = 'g' THEN 1000
            WHEN ri.unit_of_measure = 'l' AND i.unit_of_measure = 'ml' THEN 1000
            ELSE 1
        END
    ), 0) INTO v_total_cost
    FROM recipe_ingredients ri
    INNER JOIN ingredients i ON ri.ingredient_id = i.id
    WHERE ri.recipe_id = p_recipe_id
        AND i.estimated_price IS NOT NULL
        AND ri.optional = FALSE;
    
    RETURN v_total_cost;
END//

-- =============================================
-- Procedure: Search recipes
-- =============================================
CREATE PROCEDURE sp_search_recipes(
    IN p_search_term VARCHAR(255),
    IN p_ingredient_category INT,
    IN p_max_time INT,
    IN p_difficulty VARCHAR(20),
    IN p_min_rating DECIMAL(3,2),
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    SELECT DISTINCT
        r.*,
        COUNT(DISTINCT c.id) AS comment_count,
        MAX(rh.completion_date) AS last_completion
    FROM recipes r
    LEFT JOIN recipe_ingredients ri ON r.id = ri.recipe_id
    LEFT JOIN ingredients i ON ri.ingredient_id = i.id
    LEFT JOIN comments c ON r.id = c.recipe_id AND c.visible = TRUE
    LEFT JOIN recipe_history rh ON r.id = rh.recipe_id
    WHERE r.published = TRUE
        AND (p_search_term IS NULL OR 
            (MATCH(r.title, r.description) AGAINST(p_search_term IN NATURAL LANGUAGE MODE)
            OR r.title LIKE CONCAT('%', p_search_term, '%')))
        AND (p_ingredient_category IS NULL OR i.category_id = p_ingredient_category)
        AND (p_max_time IS NULL OR r.total_time <= p_max_time)
        AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
        AND (p_min_rating IS NULL OR r.average_rating >= p_min_rating)
    GROUP BY r.id
    ORDER BY r.average_rating DESC, r.completion_count DESC
    LIMIT p_limit OFFSET p_offset;
END//

-- =============================================
-- Procedure: User statistics
-- =============================================
CREATE PROCEDURE sp_user_statistics(
    IN p_user_id INT
)
BEGIN
    -- General statistics
    SELECT 
        COUNT(DISTINCT rh.recipe_id) AS completed_recipes_count,
        COUNT(*) AS total_completions_count,
        AVG(rh.rating) AS average_rating_given,
        MAX(rh.completion_date) AS last_completion,
        COUNT(DISTINCT DATE(rh.completion_date)) AS cooking_days_count
    FROM recipe_history rh
    WHERE rh.user_id = p_user_id;
    
    -- Top 5 favorite recipes
    SELECT 
        r.id,
        r.title,
        COUNT(*) AS completion_count,
        AVG(rh.rating) AS average_rating
    FROM recipe_history rh
    INNER JOIN recipes r ON rh.recipe_id = r.id
    WHERE rh.user_id = p_user_id
    GROUP BY r.id
    ORDER BY AVG(rh.rating) DESC, COUNT(*) DESC
    LIMIT 5;
    
    -- Most used ingredient categories
    SELECT 
        ic.name AS category,
        COUNT(DISTINCT i.id) AS different_ingredients_count,
        COUNT(*) AS usage_count
    FROM recipe_history rh
    INNER JOIN recipe_ingredients ri ON rh.recipe_id = ri.recipe_id
    INNER JOIN ingredients i ON ri.ingredient_id = i.id
    INNER JOIN ingredient_categories ic ON i.category_id = ic.id
    WHERE rh.user_id = p_user_id
    GROUP BY ic.id
    ORDER BY COUNT(*) DESC
    LIMIT 5;
END//

-- =============================================
-- Procedure: Clean expired stock
-- =============================================
CREATE PROCEDURE sp_clean_expired_stock()
BEGIN
    DELETE FROM user_stock
    WHERE expiration_date < DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        AND quantity = 0;
    
    SELECT ROW_COUNT() AS deleted_stock_count;
END//

-- =============================================
-- Trigger: Update average rating after comment
-- =============================================
CREATE TRIGGER trg_update_average_rating
AFTER INSERT ON comments
FOR EACH ROW
BEGIN
    IF NEW.rating IS NOT NULL THEN
        UPDATE recipes
        SET 
            average_rating = (
                SELECT AVG(rating)
                FROM comments
                WHERE recipe_id = NEW.recipe_id 
                    AND rating IS NOT NULL 
                    AND visible = TRUE
            ),
            rating_count = (
                SELECT COUNT(*)
                FROM comments
                WHERE recipe_id = NEW.recipe_id 
                    AND rating IS NOT NULL 
                    AND visible = TRUE
            )
        WHERE id = NEW.recipe_id;
    END IF;
END//

-- =============================================
-- Trigger: Check stock coherence
-- =============================================
CREATE TRIGGER trg_check_stock_coherence
BEFORE UPDATE ON user_stock
FOR EACH ROW
BEGIN
    IF NEW.quantity < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Stock quantity cannot be negative';
    END IF;
    
    IF NEW.expiration_date IS NOT NULL AND NEW.expiration_date < CURDATE() THEN
        SET NEW.quantity = 0;
    END IF;
END//

DELIMITER ;