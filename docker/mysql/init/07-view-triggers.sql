-- =============================================
-- VIEWS
-- =============================================

-- View: Recipes with all their information
CREATE OR REPLACE VIEW v_complete_recipes AS
SELECT 
    r.*,
    u.last_name AS creator_last_name,
    u.first_name AS creator_first_name,
    COUNT(DISTINCT ri.ingredient_id) AS ingredient_count,
    COUNT(DISTINCT c.id) AS comment_count,
    COUNT(DISTINCT fr.user_id) AS favorite_count,
    fn_calculate_recipe_cost(r.id) AS calculated_cost
FROM recipes r
LEFT JOIN users u ON r.created_by = u.id
LEFT JOIN recipe_ingredients ri ON r.id = ri.recipe_id
LEFT JOIN comments c ON r.id = c.recipe_id AND c.visible = TRUE
LEFT JOIN favorite_recipes fr ON r.id = fr.recipe_id
GROUP BY r.id;

-- View: Stock close to expiration
CREATE OR REPLACE VIEW v_stock_to_consume AS
SELECT 
    us.user_id,
    u.last_name,
    u.first_name,
    i.name AS ingredient,
    us.quantity,
    us.unit_of_measure,
    us.expiration_date,
    DATEDIFF(us.expiration_date, CURDATE()) AS days_remaining,
    i.category_id,
    ic.name AS category
FROM user_stock us
INNER JOIN users u ON us.user_id = u.id
INNER JOIN ingredients i ON us.ingredient_id = i.id
INNER JOIN ingredient_categories ic ON i.category_id = ic.id
WHERE us.expiration_date IS NOT NULL
    AND us.expiration_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
    AND us.quantity > 0
ORDER BY us.expiration_date ASC;

-- View: Popular recipes of the month
CREATE OR REPLACE VIEW v_popular_recipes_month AS
SELECT 
    r.id,
    r.title,
    r.description,
    r.average_rating,
    COUNT(DISTINCT rh.id) AS month_completions,
    COUNT(DISTINCT rh.user_id) AS unique_users
FROM recipes r
INNER JOIN recipe_history rh ON r.id = rh.recipe_id
WHERE rh.completion_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    AND r.published = TRUE
GROUP BY r.id
ORDER BY month_completions DESC, r.average_rating DESC
LIMIT 10;

-- View: Recipe/diet compatibility
CREATE OR REPLACE VIEW v_vegetarian_recipes AS
SELECT DISTINCT r.*
FROM recipes r
WHERE NOT EXISTS (
    SELECT 1 
    FROM recipe_ingredients ri
    INNER JOIN ingredients i ON ri.ingredient_id = i.id
    WHERE ri.recipe_id = r.id 
        AND i.category_id IN (3, 4) -- Meats and Fish
)
AND r.published = TRUE;

-- View: Statistics by user
CREATE OR REPLACE VIEW v_user_stats AS
SELECT 
    u.id,
    u.last_name,
    u.first_name,
    COUNT(DISTINCT r.id) AS created_recipes_count,
    COUNT(DISTINCT rh.recipe_id) AS completed_recipes_count,
    COUNT(DISTINCT rh.id) AS total_completions_count,
    AVG(rh.rating) AS average_rating_given,
    COUNT(DISTINCT c.id) AS comment_count,
    COUNT(DISTINCT fr.recipe_id) AS favorite_count
FROM users u
LEFT JOIN recipes r ON u.id = r.created_by
LEFT JOIN recipe_history rh ON u.id = rh.user_id
LEFT JOIN comments c ON u.id = c.user_id
LEFT JOIN favorite_recipes fr ON u.id = fr.user_id
GROUP BY u.id;

-- View: Most used ingredients
CREATE OR REPLACE VIEW v_popular_ingredients AS
SELECT 
    i.id,
    i.name,
    ic.name AS category,
    COUNT(DISTINCT ri.recipe_id) AS recipe_count,
    AVG(r.average_rating) AS average_recipe_rating
FROM ingredients i
INNER JOIN ingredient_categories ic ON i.category_id = ic.id
INNER JOIN recipe_ingredients ri ON i.id = ri.ingredient_id
INNER JOIN recipes r ON ri.recipe_id = r.id
WHERE r.published = TRUE
GROUP BY i.id
ORDER BY recipe_count DESC;

-- =============================================
-- ADDITIONAL TRIGGERS
-- =============================================

DELIMITER //

-- Trigger: Validate ingredient quantities
CREATE TRIGGER trg_validate_ingredient_quantity
BEFORE INSERT ON recipe_ingredients
FOR EACH ROW
BEGIN
    IF NEW.quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Quantity must be greater than 0';
    END IF;
END//

-- Trigger: Automatic update of recipe estimated cost
CREATE TRIGGER trg_update_recipe_cost_insert
AFTER INSERT ON recipe_ingredients
FOR EACH ROW
BEGIN
    UPDATE recipes
    SET estimated_cost = fn_calculate_recipe_cost(NEW.recipe_id)
    WHERE id = NEW.recipe_id;
END//

CREATE TRIGGER trg_update_recipe_cost_update
AFTER UPDATE ON recipe_ingredients
FOR EACH ROW
BEGIN
    UPDATE recipes
    SET estimated_cost = fn_calculate_recipe_cost(NEW.recipe_id)
    WHERE id = NEW.recipe_id;
END//

CREATE TRIGGER trg_update_recipe_cost_delete
AFTER DELETE ON recipe_ingredients
FOR EACH ROW
BEGIN
    UPDATE recipes
    SET estimated_cost = fn_calculate_recipe_cost(OLD.recipe_id)
    WHERE id = OLD.recipe_id;
END//

-- Trigger: Automatic archiving of old shopping lists
CREATE TRIGGER trg_archive_shopping_list
BEFORE UPDATE ON shopping_lists
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' 
       AND OLD.status = 'in_progress' 
       AND DATEDIFF(CURDATE(), NEW.creation_date) > 30 THEN
        SET NEW.status = 'archived';
    END IF;
END//

-- Trigger: Prevent deletion of used ingredients
CREATE TRIGGER trg_prevent_ingredient_delete
BEFORE DELETE ON ingredients
FOR EACH ROW
BEGIN
    DECLARE nb_uses INT;
    
    SELECT COUNT(*) INTO nb_uses
    FROM recipe_ingredients
    WHERE ingredient_id = OLD.id;
    
    IF nb_uses > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot delete an ingredient used in recipes';
    END IF;
END//

-- Trigger: Log recipe modifications
CREATE TRIGGER trg_log_recipe_modification
BEFORE UPDATE ON recipes
FOR EACH ROW
BEGIN
    IF OLD.title != NEW.title OR OLD.description != NEW.description THEN
        SET NEW.updated_at = CURRENT_TIMESTAMP;
    END IF;
END//

-- Trigger: Validate dietary regimen consistency
CREATE TRIGGER trg_validate_user_diet
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    -- If switching to vegetarian, check preferences
    IF NEW.dietary_regimen_id = 2 AND OLD.dietary_regimen_id != 2 THEN
        -- Could automatically add meat exclusions
        -- but for now we just let it pass
        SET NEW.updated_at = CURRENT_TIMESTAMP;
    END IF;
END//

DELIMITER ;

-- =============================================
-- ADDITIONAL FUNCTIONS
-- =============================================

DELIMITER //

-- Function: Check if a recipe is achievable with stock
CREATE FUNCTION fn_recipe_achievable(
    p_recipe_id INT,
    p_user_id INT
)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE required_ingredients INT;
    DECLARE available_ingredients INT;
    
    -- Count required ingredients (non-optional)
    SELECT COUNT(DISTINCT ingredient_id) INTO required_ingredients
    FROM recipe_ingredients
    WHERE recipe_id = p_recipe_id AND optional = FALSE;
    
    -- Count available ingredients in stock
    SELECT COUNT(DISTINCT ri.ingredient_id) INTO available_ingredients
    FROM recipe_ingredients ri
    INNER JOIN user_stock us ON ri.ingredient_id = us.ingredient_id
    WHERE ri.recipe_id = p_recipe_id 
        AND ri.optional = FALSE
        AND us.user_id = p_user_id
        AND us.quantity >= ri.quantity
        AND (us.expiration_date IS NULL OR us.expiration_date > CURDATE());
    
    RETURN (available_ingredients = required_ingredients);
END//

-- Function: Calculate recipe compatibility score
CREATE FUNCTION fn_compatibility_score(
    p_recipe_id INT,
    p_user_id INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE score INT DEFAULT 100;
    DECLARE nb_excluded_ingredients INT;
    DECLARE nb_allergens INT;
    
    -- Check excluded ingredients
    SELECT COUNT(*) INTO nb_excluded_ingredients
    FROM recipe_ingredients ri
    INNER JOIN ingredient_preferences ip ON ri.ingredient_id = ip.ingredient_id
    WHERE ri.recipe_id = p_recipe_id 
        AND ip.user_id = p_user_id
        AND ip.preference_type IN ('excluded', 'avoided');
    
    -- Check allergens
    SELECT COUNT(*) INTO nb_allergens
    FROM recipe_ingredients ri
    INNER JOIN ingredient_allergens ia ON ri.ingredient_id = ia.ingredient_id
    INNER JOIN dietary_preferences dp ON ia.allergen_id = dp.allergen_id
    WHERE ri.recipe_id = p_recipe_id 
        AND dp.user_id = p_user_id;
    
    -- Calculate score
    SET score = score - (nb_excluded_ingredients * 50) - (nb_allergens * 100);
    
    IF score < 0 THEN
        SET score = 0;
    END IF;
    
    RETURN score;
END//

-- Function: Get next suggested meal
CREATE FUNCTION fn_next_suggested_meal(
    p_user_id INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE recipe_id INT;
    
    -- Select a recipe not recently completed and compatible
    SELECT r.id INTO recipe_id
    FROM recipes r
    WHERE r.published = TRUE
        AND fn_compatibility_score(r.id, p_user_id) > 50
        AND NOT EXISTS (
            SELECT 1 
            FROM recipe_history rh
            WHERE rh.recipe_id = r.id 
                AND rh.user_id = p_user_id
                AND rh.completion_date > DATE_SUB(CURDATE(), INTERVAL 14 DAY)
        )
    ORDER BY r.average_rating DESC, RAND()
    LIMIT 1;
    
    RETURN recipe_id;
END//

DELIMITER ;

-- =============================================
-- MAINTENANCE PROCEDURES
-- =============================================

DELIMITER //

-- Procedure: Clean old data
CREATE PROCEDURE sp_maintenance_cleanup()
BEGIN
    DECLARE nb_deleted_rows INT DEFAULT 0;
    
    -- Delete archived shopping lists older than 6 months
    DELETE FROM shopping_lists
    WHERE status = 'archived' 
        AND created_at < DATE_SUB(CURDATE(), INTERVAL 6 MONTH);
    SET nb_deleted_rows = nb_deleted_rows + ROW_COUNT();
    
    -- Delete empty and expired stock older than 30 days
    DELETE FROM user_stock
    WHERE quantity = 0 
        AND expiration_date < DATE_SUB(CURDATE(), INTERVAL 30 DAY);
    SET nb_deleted_rows = nb_deleted_rows + ROW_COUNT();
    
    -- Deactivate accounts inactive for more than a year
    UPDATE users
    SET active = FALSE
    WHERE active = TRUE
        AND id NOT IN (
            SELECT DISTINCT user_id 
            FROM recipe_history 
            WHERE completion_date > DATE_SUB(CURDATE(), INTERVAL 365 DAY)
        )
        AND updated_at < DATE_SUB(CURDATE(), INTERVAL 365 DAY);
    
    SELECT nb_deleted_rows AS total_deleted_rows;
END//

-- Procedure: Recalculate all statistics
CREATE PROCEDURE sp_recalculate_stats()
BEGIN
    -- Recalculate average ratings
    UPDATE recipes r
    SET 
        average_rating = (
            SELECT AVG(rating)
            FROM comments
            WHERE recipe_id = r.id AND rating IS NOT NULL AND visible = TRUE
        ),
        rating_count = (
            SELECT COUNT(*)
            FROM comments
            WHERE recipe_id = r.id AND rating IS NOT NULL AND visible = TRUE
        ),
        completion_count = (
            SELECT COUNT(*)
            FROM recipe_history
            WHERE recipe_id = r.id
        );
    
    -- Update stats table if it exists
    TRUNCATE TABLE recipe_stats;
    
    INSERT INTO recipe_stats (recipe_id, average_rating, rating_count, completion_count, last_completion, average_cost)
    SELECT 
        r.id,
        r.average_rating,
        r.rating_count,
        r.completion_count,
        MAX(rh.completion_date),
        fn_calculate_recipe_cost(r.id)
    FROM recipes r
    LEFT JOIN recipe_history rh ON r.id = rh.recipe_id
    GROUP BY r.id;
    
    SELECT 'Statistics successfully recalculated' AS message;
END//

-- Procedure: Weekly report
CREATE PROCEDURE sp_weekly_report()
BEGIN
    -- New recipes of the week
    SELECT 'New recipes' AS category, COUNT(*) AS count
    FROM recipes
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
    
    -- New users
    SELECT 'New users' AS category, COUNT(*) AS count
    FROM users
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
    
    -- Most completed recipes
    SELECT 
        r.title,
        COUNT(*) AS week_completions
    FROM recipe_history rh
    INNER JOIN recipes r ON rh.recipe_id = r.id
    WHERE rh.completion_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY r.id
    ORDER BY week_completions DESC
    LIMIT 5;
    
    -- Most active users
    SELECT 
        u.last_name,
        u.first_name,
        COUNT(*) AS activities
    FROM users u
    INNER JOIN recipe_history rh ON u.id = rh.user_id
    WHERE rh.completion_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY u.id
    ORDER BY activities DESC
    LIMIT 5;
END//

DELIMITER ;