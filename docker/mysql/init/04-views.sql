USE food_advisor_db;

-- =====================================================
-- USER-RELATED VIEWS
-- =====================================================

-- View: Active users with basic information
CREATE OR REPLACE VIEW v_active_users AS
SELECT 
    user_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    email,
    role,
    country,
    city,
    birth_date,
    TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS age,
    created_at,
    updated_at
FROM users
WHERE is_active = TRUE;

-- View: User statistics
CREATE OR REPLACE VIEW v_user_statistics AS
SELECT 
    u.user_id,
    u.email,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    COUNT(DISTINCT r.recipe_id) AS recipes_created,
    COUNT(DISTINCT cr.completion_id) AS recipes_completed,
    AVG(cr.rating) AS average_rating_given,
    COUNT(DISTINCT ua.allergy_id) AS allergy_count,
    COUNT(DISTINCT uis.stock_id) AS stock_items_count
FROM users u
LEFT JOIN recipes r ON u.user_id = r.author_user_id
LEFT JOIN completed_recipes cr ON u.user_id = cr.user_id
LEFT JOIN user_allergies ua ON u.user_id = ua.user_id
LEFT JOIN user_ingredient_stock uis ON u.user_id = uis.user_id
WHERE u.is_active = TRUE
GROUP BY u.user_id;

-- View: Users with their allergies
CREATE OR REPLACE VIEW v_user_allergies_detail AS
SELECT 
    u.user_id,
    u.email,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    a.allergy_id,
    a.name AS allergy_name,
    ua.severity,
    ua.created_at AS allergy_added_date
FROM users u
INNER JOIN user_allergies ua ON u.user_id = ua.user_id
INNER JOIN allergies a ON ua.allergy_id = a.allergy_id
WHERE u.is_active = TRUE
ORDER BY u.user_id, ua.severity DESC;

-- =====================================================
-- RECIPE-RELATED VIEWS
-- =====================================================

-- View: Published recipes with author information
CREATE OR REPLACE VIEW v_published_recipes AS
SELECT 
    r.recipe_id,
    r.title,
    r.description,
    r.servings,
    r.difficulty,
    r.image_url,
    r.created_at,
    r.updated_at,
    u.user_id AS author_id,
    CONCAT(u.first_name, ' ', u.last_name) AS author_name,
    u.email AS author_email,
    COUNT(DISTINCT cr.completion_id) AS times_completed,
    AVG(cr.rating) AS average_rating,
    COUNT(DISTINCT ri.ingredient_id) AS ingredient_count,
    SUM(rs.duration_minutes) AS total_duration_minutes
FROM recipes r
INNER JOIN users u ON r.author_user_id = u.user_id
LEFT JOIN completed_recipes cr ON r.recipe_id = cr.recipe_id
LEFT JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id
LEFT JOIN recipe_steps rs ON r.recipe_id = rs.recipe_id
WHERE r.is_published = TRUE
GROUP BY r.recipe_id;

-- View: Recipe ingredients with nutritional information
CREATE OR REPLACE VIEW v_recipe_nutrition AS
SELECT 
    r.recipe_id,
    r.title,
    r.servings,
    COUNT(ri.ingredient_id) AS ingredient_count,
    SUM(i.calories * ri.quantity / 100) AS total_calories,
    SUM(i.proteins * ri.quantity / 100) AS total_proteins,
    SUM(i.carbohydrates * ri.quantity / 100) AS total_carbohydrates,
    SUM(i.fats * ri.quantity / 100) AS total_fats,
    SUM(i.fibers * ri.quantity / 100) AS total_fibers,
    SUM(i.price * ri.quantity / i.weight) AS estimated_cost,
    SUM(i.calories * ri.quantity / 100) / r.servings AS calories_per_serving,
    SUM(i.proteins * ri.quantity / 100) / r.servings AS proteins_per_serving,
    SUM(i.carbohydrates * ri.quantity / 100) / r.servings AS carbs_per_serving,
    SUM(i.fats * ri.quantity / 100) / r.servings AS fats_per_serving
FROM recipes r
INNER JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id
INNER JOIN ingredients i ON ri.ingredient_id = i.ingredient_id
WHERE ri.is_optional = FALSE
GROUP BY r.recipe_id;

-- View: Recipe complexity analysis
CREATE OR REPLACE VIEW v_recipe_complexity AS
SELECT 
    r.recipe_id,
    r.title,
    r.difficulty,
    COUNT(DISTINCT ri.ingredient_id) AS ingredient_count,
    COUNT(DISTINCT rs.step_order) AS step_count,
    SUM(rs.duration_minutes) AS total_minutes,
    COUNT(DISTINCT CASE WHEN ri.is_optional = TRUE THEN ri.ingredient_id END) AS optional_ingredients,
    COUNT(DISTINCT CASE WHEN rs.step_type = 'cooking' THEN rs.step_order END) AS cooking_steps,
    COUNT(DISTINCT CASE WHEN rs.step_type = 'action' THEN rs.step_order END) AS action_steps,
    MAX(rs.duration_minutes) AS longest_step_minutes
FROM recipes r
LEFT JOIN recipe_ingredients ri ON r.recipe_id = ri.recipe_id
LEFT JOIN recipe_steps rs ON r.recipe_id = rs.recipe_id
GROUP BY r.recipe_id;

-- View: Popular recipes (based on completions and ratings)
CREATE OR REPLACE VIEW v_popular_recipes AS
SELECT 
    r.recipe_id,
    r.title,
    r.description,
    r.difficulty,
    COUNT(DISTINCT cr.completion_id) AS completion_count,
    AVG(cr.rating) AS average_rating,
    COUNT(DISTINCT cr.user_id) AS unique_users,
    MAX(cr.completion_date) AS last_completed,
    COUNT(CASE WHEN cr.rating = 5 THEN 1 END) AS five_star_count,
    COUNT(CASE WHEN cr.rating >= 4 THEN 1 END) AS four_plus_star_count
FROM recipes r
INNER JOIN completed_recipes cr ON r.recipe_id = cr.recipe_id
WHERE r.is_published = TRUE
GROUP BY r.recipe_id
HAVING completion_count >= 5 AND average_rating >= 3.5
ORDER BY average_rating DESC, completion_count DESC;

-- =====================================================
-- INGREDIENT-RELATED VIEWS
-- =====================================================

-- View: Ingredients with categories
CREATE OR REPLACE VIEW v_ingredients_with_categories AS
SELECT 
    i.ingredient_id,
    i.name AS ingredient_name,
    i.calories,
    i.proteins,
    i.carbohydrates,
    i.fats,
    i.fibers,
    i.price,
    i.measurement_unit,
    GROUP_CONCAT(ic.name ORDER BY ic.name SEPARATOR ', ') AS categories
FROM ingredients i
LEFT JOIN ingredient_category_assignments ica ON i.ingredient_id = ica.ingredient_id
LEFT JOIN ingredient_categories ic ON ica.category_id = ic.category_id
GROUP BY i.ingredient_id;

-- View: Ingredient usage statistics
CREATE OR REPLACE VIEW v_ingredient_usage_stats AS
SELECT 
    i.ingredient_id,
    i.name AS ingredient_name,
    COUNT(DISTINCT ri.recipe_id) AS used_in_recipes,
    COUNT(DISTINCT r.author_user_id) AS used_by_authors,
    AVG(ri.quantity) AS average_quantity,
    COUNT(CASE WHEN ri.is_optional = TRUE THEN 1 END) AS optional_uses,
    COUNT(CASE WHEN ri.is_optional = FALSE THEN 1 END) AS required_uses
FROM ingredients i
LEFT JOIN recipe_ingredients ri ON i.ingredient_id = ri.ingredient_id
LEFT JOIN recipes r ON ri.recipe_id = r.recipe_id
GROUP BY i.ingredient_id
ORDER BY used_in_recipes DESC;

-- View: Ingredients with allergen information
CREATE OR REPLACE VIEW v_ingredient_allergens AS
SELECT 
    i.ingredient_id,
    i.name AS ingredient_name,
    GROUP_CONCAT(a.name ORDER BY a.name SEPARATOR ', ') AS allergens,
    COUNT(a.allergy_id) AS allergen_count
FROM ingredients i
LEFT JOIN ingredient_allergies ia ON i.ingredient_id = ia.ingredient_id
LEFT JOIN allergies a ON ia.allergy_id = a.allergy_id
GROUP BY i.ingredient_id;

-- =====================================================
-- STOCK MANAGEMENT VIEWS
-- =====================================================

-- View: User stock with expiration alerts
CREATE OR REPLACE VIEW v_user_stock_expiration AS
SELECT 
    uis.stock_id,
    uis.user_id,
    u.email AS user_email,
    CONCAT(u.first_name, ' ', u.last_name) AS user_name,
    i.ingredient_id,
    i.name AS ingredient_name,
    uis.quantity,
    uis.expiration_date,
    uis.storage_location,
    DATEDIFF(uis.expiration_date, CURDATE()) AS days_until_expiration,
    CASE
        WHEN DATEDIFF(uis.expiration_date, CURDATE()) < 0 THEN 'Expired'
        WHEN DATEDIFF(uis.expiration_date, CURDATE()) <= 3 THEN 'Critical'
        WHEN DATEDIFF(uis.expiration_date, CURDATE()) <= 7 THEN 'Warning'
        WHEN DATEDIFF(uis.expiration_date, CURDATE()) <= 14 THEN 'Notice'
        ELSE 'Good'
    END AS expiration_status
FROM user_ingredient_stock uis
INNER JOIN users u ON uis.user_id = u.user_id
INNER JOIN ingredients i ON uis.ingredient_id = i.ingredient_id
WHERE uis.expiration_date IS NOT NULL
ORDER BY days_until_expiration ASC;

-- View: User stock summary
CREATE OR REPLACE VIEW v_user_stock_summary AS
SELECT 
    uis.user_id,
    COUNT(DISTINCT uis.ingredient_id) AS unique_ingredients,
    COUNT(uis.stock_id) AS total_items,
    COUNT(CASE WHEN DATEDIFF(uis.expiration_date, CURDATE()) < 0 THEN 1 END) AS expired_items,
    COUNT(CASE WHEN DATEDIFF(uis.expiration_date, CURDATE()) BETWEEN 0 AND 7 THEN 1 END) AS expiring_soon,
    SUM(i.price * uis.quantity / i.weight) AS total_stock_value,
    COUNT(DISTINCT uis.storage_location) AS storage_locations
FROM user_ingredient_stock uis
INNER JOIN ingredients i ON uis.ingredient_id = i.ingredient_id
GROUP BY uis.user_id;

-- =====================================================
-- PREFERENCE AND RECOMMENDATION VIEWS
-- =====================================================

-- View: User preferences summary
CREATE OR REPLACE VIEW v_user_preferences_summary AS
SELECT 
    u.user_id,
    u.email,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    COUNT(DISTINCT uip.ingredient_id) AS ingredient_preferences,
    COUNT(DISTINCT uicp.category_id) AS category_preferences,
    COUNT(DISTINCT CASE WHEN uip.preference_type = 'excluded' THEN uip.ingredient_id END) AS excluded_ingredients,
    COUNT(DISTINCT CASE WHEN uip.preference_type = 'preferred' THEN uip.ingredient_id END) AS preferred_ingredients,
    COUNT(DISTINCT CASE WHEN uicp.preference_type = 'excluded' THEN uicp.category_id END) AS excluded_categories,
    COUNT(DISTINCT CASE WHEN uicp.preference_type = 'preferred' THEN uicp.category_id END) AS preferred_categories
FROM users u
LEFT JOIN user_ingredient_preferences uip ON u.user_id = uip.user_id
LEFT JOIN user_ingredient_category_preferences uicp ON u.user_id = uicp.user_id
WHERE u.is_active = TRUE
GROUP BY u.user_id;

-- View: Recipes available for user (considering allergies and preferences)
CREATE OR REPLACE VIEW v_user_compatible_recipes AS
SELECT DISTINCT
    u.user_id,
    r.recipe_id,
    r.title,
    r.difficulty,
    r.servings,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM recipe_ingredients ri2
            INNER JOIN ingredient_allergies ia ON ri2.ingredient_id = ia.ingredient_id
            INNER JOIN user_allergies ua ON ia.allergy_id = ua.allergy_id
            WHERE ri2.recipe_id = r.recipe_id 
            AND ua.user_id = u.user_id 
            AND ri2.is_optional = FALSE
        ) THEN FALSE
        ELSE TRUE
    END AS is_allergy_safe,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM recipe_ingredients ri3
            INNER JOIN user_ingredient_preferences uip ON ri3.ingredient_id = uip.ingredient_id
            WHERE ri3.recipe_id = r.recipe_id 
            AND uip.user_id = u.user_id 
            AND uip.preference_type = 'excluded'
            AND ri3.is_optional = FALSE
        ) THEN FALSE
        ELSE TRUE
    END AS respects_preferences
FROM users u
CROSS JOIN recipes r
WHERE u.is_active = TRUE 
AND r.is_published = TRUE;

-- =====================================================
-- AUDIT AND MONITORING VIEWS
-- =====================================================

-- View: Recent user activity
CREATE OR REPLACE VIEW v_recent_user_activity AS
SELECT 
    'Recipe Created' AS activity_type,
    r.author_user_id AS user_id,
    r.recipe_id AS entity_id,
    r.title AS entity_name,
    r.created_at AS activity_date
FROM recipes r
WHERE r.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT 
    'Recipe Completed' AS activity_type,
    cr.user_id,
    cr.recipe_id AS entity_id,
    r.title AS entity_name,
    cr.completion_date AS activity_date
FROM completed_recipes cr
INNER JOIN recipes r ON cr.recipe_id = r.recipe_id
WHERE cr.completion_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT 
    'Stock Added' AS activity_type,
    uis.user_id,
    uis.ingredient_id AS entity_id,
    i.name AS entity_name,
    uis.created_at AS activity_date
FROM user_ingredient_stock uis
INNER JOIN ingredients i ON uis.ingredient_id = i.ingredient_id
WHERE uis.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

ORDER BY activity_date DESC;

-- View: System health monitoring
CREATE OR REPLACE VIEW v_system_health AS
SELECT 
    'Total Users' AS metric,
    COUNT(*) AS value,
    COUNT(CASE WHEN is_active = TRUE THEN 1 END) AS active_count
FROM users

UNION ALL

SELECT 
    'Total Recipes' AS metric,
    COUNT(*) AS value,
    COUNT(CASE WHEN is_published = TRUE THEN 1 END) AS active_count
FROM recipes

UNION ALL

SELECT 
    'Total Ingredients' AS metric,
    COUNT(*) AS value,
    COUNT(*) AS active_count
FROM ingredients

UNION ALL

SELECT 
    'Completed Recipes (Last 30 Days)' AS metric,
    COUNT(*) AS value,
    COUNT(DISTINCT user_id) AS active_count
FROM completed_recipes
WHERE completion_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT 
    'Active Sessions' AS metric,
    COUNT(*) AS value,
    COUNT(DISTINCT user_id) AS active_count
FROM user_sessions
WHERE is_active = TRUE

UNION ALL

SELECT 
    'Unresolved Errors' AS metric,
    COUNT(*) AS value,
    COUNT(DISTINCT user_id) AS active_count
FROM error_logs
WHERE resolved = FALSE;

-- View: Error summary for monitoring
CREATE OR REPLACE VIEW v_error_summary AS
SELECT 
    DATE(occurred_at) AS error_date,
    error_type,
    procedure_name,
    COUNT(*) AS error_count,
    COUNT(DISTINCT user_id) AS affected_users,
    COUNT(CASE WHEN resolved = FALSE THEN 1 END) AS unresolved_count,
    MIN(occurred_at) AS first_occurrence,
    MAX(occurred_at) AS last_occurrence
FROM error_logs
WHERE occurred_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY DATE(occurred_at), error_type, procedure_name
ORDER BY error_date DESC, error_count DESC;