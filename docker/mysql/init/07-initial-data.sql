USE food_advisor_db;

-- Disable foreign key checks temporarily for easier insertion
SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================
-- USERS DATA
-- =====================================================

INSERT INTO users (user_id, first_name, last_name, gender, password_hash, email, role, country, city, is_active, birth_date) VALUES
(1, 'John', 'Doe', 'Male', '', 'john.doe@email.com', 'Administrator', 'USA', 'New York', TRUE, '1985-03-15'),
(2, 'Marie', 'Dubois', 'Female', '', 'marie.dubois@email.com', 'Regular', 'France', 'Paris', TRUE, '1990-07-22'),
(3, 'Carlos', 'Garcia', 'Male', '', 'carlos.garcia@email.com', 'Regular', 'Spain', 'Madrid', TRUE, '1988-11-30'),
(4, 'Emma', 'Wilson', 'Female', '', 'emma.wilson@email.com', 'Regular', 'UK', 'London', TRUE, '1992-05-18'),
(5, 'Luigi', 'Rossi', 'Male', '', 'luigi.rossi@email.com', 'Regular', 'Italy', 'Rome', TRUE, '1987-09-10'),
(6, 'Sophie', 'Martin', 'Female', '', 'sophie.martin@email.com', 'Administrator', 'France', 'Lyon', TRUE, '1991-12-25'),
(7, 'James', 'Smith', 'Male', '', 'james.smith@email.com', 'Regular', 'USA', 'Los Angeles', TRUE, '1989-04-08'),
(8, 'Anna', 'Schmidt', 'Female', '', 'anna.schmidt@email.com', 'Regular', 'Germany', 'Berlin', TRUE, '1993-08-14'),
(9, 'Pierre', 'Laurent', 'Male', '', 'pierre.laurent@email.com', 'Regular', 'France', 'Marseille', TRUE, '1986-02-28'),
(10, 'Maria', 'Silva', 'Female', '', 'maria.silva@email.com', 'Regular', 'Brazil', 'São Paulo', TRUE, '1994-06-20');

-- =====================================================
-- ALLERGIES DATA
-- =====================================================

INSERT INTO allergies (allergy_id, name, description) VALUES
(1, 'Peanuts', 'Allergy to peanuts and peanut products'),
(2, 'Tree Nuts', 'Allergy to tree nuts including almonds, cashews, walnuts'),
(3, 'Dairy', 'Lactose intolerance or milk protein allergy'),
(4, 'Eggs', 'Allergy to eggs and egg products'),
(5, 'Wheat', 'Wheat allergy including gluten sensitivity'),
(6, 'Soy', 'Allergy to soy and soy products'),
(7, 'Fish', 'Allergy to fish'),
(8, 'Shellfish', 'Allergy to shellfish including shrimp, lobster, crab'),
(9, 'Sesame', 'Allergy to sesame seeds and sesame oil'),
(10, 'Mustard', 'Allergy to mustard seeds and mustard products');

-- =====================================================
-- USER ALLERGIES DATA
-- =====================================================

INSERT INTO user_allergies (user_id, allergy_id, severity) VALUES
(2, 3, 'Moderate'), -- Marie has dairy allergy
(2, 5, 'Mild'),      -- Marie has wheat allergy
(3, 1, 'Severe'),    -- Carlos has peanut allergy
(4, 8, 'Life-threatening'), -- Emma has shellfish allergy
(5, 3, 'Moderate'),  -- Luigi has dairy allergy
(7, 4, 'Mild'),      -- James has egg allergy
(8, 5, 'Severe'),    -- Anna has wheat allergy
(10, 6, 'Moderate'); -- Maria has soy allergy

-- =====================================================
-- INGREDIENT CATEGORIES DATA
-- =====================================================

INSERT INTO ingredient_categories (category_id, name, description) VALUES
(1, 'Vegetables', 'Fresh and frozen vegetables'),
(2, 'Fruits', 'Fresh and dried fruits'),
(3, 'Meat', 'All types of meat including beef, pork, chicken'),
(4, 'Fish & Seafood', 'Fish, shellfish, and other seafood'),
(5, 'Dairy', 'Milk, cheese, yogurt, and dairy products'),
(6, 'Grains', 'Rice, wheat, oats, and grain products'),
(7, 'Legumes', 'Beans, lentils, peas'),
(8, 'Nuts & Seeds', 'Tree nuts, peanuts, and seeds'),
(9, 'Herbs & Spices', 'Fresh and dried herbs and spices'),
(10, 'Oils & Fats', 'Cooking oils, butter, and fats'),
(11, 'Sweeteners', 'Sugar, honey, syrups'),
(12, 'Condiments', 'Sauces, vinegars, and condiments'),
(13, 'Baking', 'Flour, baking powder, and baking ingredients'),
(14, 'Beverages', 'Non-alcoholic drinks and ingredients'),
(15, 'Pasta', 'All types of pasta and noodles');

-- =====================================================
-- INGREDIENTS DATA
-- =====================================================

INSERT INTO ingredients (ingredient_id, name, carbohydrates, proteins, fats, fibers, calories, price, weight, measurement_unit) VALUES
-- Vegetables
(1, 'Tomato', 3.89, 0.88, 0.20, 1.20, 18.00, 2.50, 100, 'grams'),
(2, 'Onion', 9.34, 1.10, 0.10, 1.70, 40.00, 1.50, 100, 'grams'),
(3, 'Garlic', 33.06, 6.36, 0.50, 2.10, 149.00, 3.00, 100, 'grams'),
(4, 'Carrot', 9.58, 0.93, 0.24, 2.80, 41.00, 1.80, 100, 'grams'),
(5, 'Potato', 17.49, 2.05, 0.09, 2.10, 77.00, 1.20, 100, 'grams'),
(6, 'Bell Pepper', 6.03, 0.99, 0.30, 2.10, 31.00, 3.50, 100, 'grams'),
(7, 'Spinach', 3.63, 2.86, 0.39, 2.20, 23.00, 2.80, 100, 'grams'),
(8, 'Broccoli', 6.64, 2.82, 0.37, 2.60, 34.00, 3.20, 100, 'grams'),
(9, 'Mushrooms', 3.26, 3.09, 0.34, 1.00, 22.00, 4.00, 100, 'grams'),
(10, 'Zucchini', 3.11, 1.21, 0.32, 1.00, 17.00, 2.50, 100, 'grams'),

-- Fruits
(11, 'Apple', 13.81, 0.26, 0.17, 2.40, 52.00, 2.00, 100, 'grams'),
(12, 'Banana', 22.84, 1.09, 0.33, 2.60, 89.00, 1.50, 100, 'grams'),
(13, 'Orange', 11.75, 0.94, 0.12, 2.40, 47.00, 2.20, 100, 'grams'),
(14, 'Lemon', 9.32, 1.10, 0.30, 2.80, 29.00, 3.00, 100, 'grams'),
(15, 'Strawberries', 7.68, 0.67, 0.30, 2.00, 32.00, 4.50, 100, 'grams'),

-- Meat
(16, 'Chicken Breast', 0.00, 31.02, 3.57, 0.00, 165.00, 8.00, 100, 'grams'),
(17, 'Ground Beef', 0.00, 26.11, 11.83, 0.00, 217.00, 9.50, 100, 'grams'),
(18, 'Pork Chop', 0.00, 27.32, 6.88, 0.00, 178.00, 10.00, 100, 'grams'),
(19, 'Bacon', 1.43, 37.04, 41.78, 0.00, 541.00, 12.00, 100, 'grams'),
(20, 'Turkey Breast', 0.00, 29.81, 1.03, 0.00, 135.00, 7.50, 100, 'grams'),

-- Fish & Seafood
(21, 'Salmon', 0.00, 25.40, 13.40, 0.00, 208.00, 15.00, 100, 'grams'),
(22, 'Tuna', 0.00, 29.91, 1.31, 0.00, 132.00, 12.00, 100, 'grams'),
(23, 'Shrimp', 0.91, 20.10, 1.73, 0.00, 99.00, 18.00, 100, 'grams'),
(24, 'Cod', 0.00, 17.81, 0.67, 0.00, 82.00, 14.00, 100, 'grams'),

-- Dairy
(25, 'Milk', 4.99, 3.37, 3.25, 0.00, 61.00, 3.50, 1000, 'milliliters'),
(26, 'Cheddar Cheese', 1.28, 24.90, 33.14, 0.00, 402.00, 12.00, 100, 'grams'),
(27, 'Greek Yogurt', 3.60, 10.00, 0.40, 0.00, 59.00, 5.00, 100, 'grams'),
(28, 'Butter', 0.06, 0.85, 81.11, 0.00, 717.00, 8.00, 100, 'grams'),
(29, 'Cream', 2.96, 2.05, 36.08, 0.00, 345.00, 6.00, 100, 'milliliters'),
(30, 'Mozzarella', 2.20, 22.17, 22.35, 0.00, 300.00, 10.00, 100, 'grams'),

-- Grains & Pasta
(31, 'White Rice', 79.95, 7.13, 0.66, 1.30, 365.00, 3.00, 100, 'grams'),
(32, 'Brown Rice', 77.24, 7.94, 2.92, 3.50, 370.00, 4.00, 100, 'grams'),
(33, 'Pasta', 74.67, 13.04, 1.51, 3.20, 371.00, 2.50, 100, 'grams'),
(34, 'Bread', 49.42, 9.00, 3.20, 2.70, 265.00, 3.50, 100, 'grams'),
(35, 'Oats', 66.27, 16.89, 6.90, 10.60, 389.00, 4.50, 100, 'grams'),
(36, 'Quinoa', 64.16, 14.12, 6.07, 7.00, 368.00, 7.00, 100, 'grams'),

-- Legumes
(37, 'Black Beans', 62.36, 21.60, 0.90, 15.50, 339.00, 3.00, 100, 'grams'),
(38, 'Lentils', 60.08, 25.80, 1.06, 10.70, 352.00, 3.50, 100, 'grams'),
(39, 'Chickpeas', 60.65, 19.30, 6.04, 17.40, 364.00, 3.20, 100, 'grams'),

-- Nuts & Seeds
(40, 'Almonds', 21.55, 21.15, 49.93, 12.50, 579.00, 15.00, 100, 'grams'),
(41, 'Walnuts', 13.71, 15.23, 65.21, 6.70, 654.00, 18.00, 100, 'grams'),
(42, 'Peanut Butter', 20.00, 25.00, 50.00, 6.00, 588.00, 8.00, 100, 'grams'),

-- Herbs & Spices
(43, 'Salt', 0.00, 0.00, 0.00, 0.00, 0.00, 0.50, 100, 'grams'),
(44, 'Black Pepper', 63.95, 10.39, 3.26, 25.30, 251.00, 8.00, 100, 'grams'),
(45, 'Basil', 2.65, 3.15, 0.64, 1.60, 23.00, 5.00, 100, 'grams'),
(46, 'Oregano', 68.92, 9.00, 4.28, 42.50, 265.00, 6.00, 100, 'grams'),
(47, 'Paprika', 53.99, 14.14, 12.89, 34.90, 282.00, 7.00, 100, 'grams'),
(48, 'Cinnamon', 80.59, 3.99, 1.24, 53.10, 247.00, 6.50, 100, 'grams'),
(49, 'Thyme', 63.94, 9.11, 7.43, 37.00, 276.00, 8.00, 100, 'grams'),
(50, 'Rosemary', 64.06, 3.31, 15.22, 42.60, 331.00, 7.50, 100, 'grams'),

-- Oils & Fats
(51, 'Olive Oil', 0.00, 0.00, 100.00, 0.00, 884.00, 10.00, 1000, 'milliliters'),
(52, 'Vegetable Oil', 0.00, 0.00, 100.00, 0.00, 884.00, 6.00, 1000, 'milliliters'),
(53, 'Coconut Oil', 0.00, 0.00, 99.06, 0.00, 862.00, 12.00, 100, 'grams'),

-- Sweeteners
(54, 'Sugar', 99.98, 0.00, 0.00, 0.00, 387.00, 2.00, 100, 'grams'),
(55, 'Honey', 82.40, 0.30, 0.00, 0.20, 304.00, 8.00, 100, 'grams'),
(56, 'Maple Syrup', 67.04, 0.04, 0.06, 0.00, 260.00, 15.00, 100, 'milliliters'),

-- Condiments
(57, 'Soy Sauce', 8.14, 10.51, 0.63, 0.80, 60.00, 3.00, 100, 'milliliters'),
(58, 'Vinegar', 0.93, 0.00, 0.00, 0.00, 21.00, 2.00, 100, 'milliliters'),
(59, 'Mustard', 5.83, 3.74, 3.34, 3.30, 66.00, 3.50, 100, 'grams'),
(60, 'Ketchup', 27.40, 1.04, 0.31, 0.30, 112.00, 3.00, 100, 'grams'),

-- Baking
(61, 'All-Purpose Flour', 76.31, 10.33, 0.98, 2.70, 364.00, 2.50, 100, 'grams'),
(62, 'Baking Powder', 27.70, 0.00, 0.00, 0.10, 53.00, 4.00, 100, 'grams'),
(63, 'Baking Soda', 0.00, 0.00, 0.00, 0.00, 0.00, 2.00, 100, 'grams'),
(64, 'Vanilla Extract', 12.65, 0.06, 0.06, 0.00, 288.00, 12.00, 100, 'milliliters'),

-- Eggs
(65, 'Eggs', 0.72, 12.56, 9.51, 0.00, 143.00, 4.00, 100, 'grams');

-- =====================================================
-- INGREDIENT CATEGORY ASSIGNMENTS
-- =====================================================

INSERT INTO ingredient_category_assignments (ingredient_id, category_id) VALUES
-- Vegetables
(1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1), (8, 1), (9, 1), (10, 1),
-- Fruits
(11, 2), (12, 2), (13, 2), (14, 2), (15, 2),
-- Meat
(16, 3), (17, 3), (18, 3), (19, 3), (20, 3),
-- Fish & Seafood
(21, 4), (22, 4), (23, 4), (24, 4),
-- Dairy
(25, 5), (26, 5), (27, 5), (28, 5), (29, 5), (30, 5),
-- Grains
(31, 6), (32, 6), (34, 6), (35, 6), (36, 6),
-- Pasta
(33, 15),
-- Legumes
(37, 7), (38, 7), (39, 7),
-- Nuts & Seeds
(40, 8), (41, 8), (42, 8),
-- Herbs & Spices
(43, 9), (44, 9), (45, 9), (46, 9), (47, 9), (48, 9), (49, 9), (50, 9),
-- Oils & Fats
(51, 10), (52, 10), (53, 10), (28, 10),
-- Sweeteners
(54, 11), (55, 11), (56, 11),
-- Condiments
(57, 12), (58, 12), (59, 12), (60, 12),
-- Baking
(61, 13), (62, 13), (63, 13), (64, 13);

-- =====================================================
-- INGREDIENT ALLERGIES
-- =====================================================

INSERT INTO ingredient_allergies (ingredient_id, allergy_id) VALUES
-- Dairy allergy
(25, 3), (26, 3), (27, 3), (28, 3), (29, 3), (30, 3),
-- Egg allergy
(65, 4),
-- Wheat allergy
(33, 5), (34, 5), (61, 5),
-- Soy allergy
(57, 6),
-- Fish allergy
(21, 7), (22, 7), (24, 7),
-- Shellfish allergy
(23, 8),
-- Nut allergy
(40, 2), (41, 2),
-- Peanut allergy
(42, 1);

-- =====================================================
-- USER PREFERENCES
-- =====================================================

INSERT INTO user_ingredient_preferences (user_id, ingredient_id, preference_type) VALUES
-- Marie prefers vegetables, excludes meat
(2, 1, 'preferred'), (2, 7, 'preferred'), (2, 16, 'excluded'), (2, 17, 'excluded'),
-- Carlos loves meat, excludes peanuts
(3, 16, 'preferred'), (3, 17, 'preferred'), (3, 42, 'excluded'),
-- Emma prefers fish, excludes shellfish
(4, 21, 'preferred'), (4, 22, 'preferred'), (4, 23, 'excluded'),
-- Luigi loves pasta, excludes dairy
(5, 33, 'preferred'), (5, 25, 'excluded'), (5, 26, 'excluded');

INSERT INTO user_ingredient_category_preferences (user_id, category_id, preference_type) VALUES
-- Marie is vegetarian
(2, 3, 'excluded'), (2, 4, 'excluded'),
-- Anna excludes gluten
(8, 6, 'excluded'), (8, 15, 'excluded'),
-- Pierre prefers French cooking
(9, 5, 'preferred'), (9, 10, 'preferred');

-- =====================================================
-- RECIPES DATA
-- =====================================================

INSERT INTO recipes (recipe_id, title, description, servings, is_published, difficulty, image_url, author_user_id) VALUES
(1, 'Classic Spaghetti Carbonara', 'Traditional Italian pasta with eggs, cheese, and bacon', 4, TRUE, 'Medium', 'https://images.example.com/carbonara.jpg', 5),
(2, 'Grilled Chicken Salad', 'Healthy salad with grilled chicken breast and fresh vegetables', 2, TRUE, 'Easy', 'https://images.example.com/chicken-salad.jpg', 1),
(3, 'Vegetable Stir-Fry', 'Quick and healthy Asian-inspired vegetable dish', 4, TRUE, 'Easy', 'https://images.example.com/stir-fry.jpg', 2),
(4, 'Beef Tacos', 'Mexican-style tacos with seasoned ground beef', 6, TRUE, 'Medium', 'https://images.example.com/tacos.jpg', 3),
(5, 'Salmon Teriyaki', 'Japanese-style glazed salmon with vegetables', 2, TRUE, 'Medium', 'https://images.example.com/salmon.jpg', 4),
(6, 'French Onion Soup', 'Classic French soup with caramelized onions and cheese', 4, TRUE, 'Hard', 'https://images.example.com/onion-soup.jpg', 6),
(7, 'Margherita Pizza', 'Traditional Italian pizza with tomato, mozzarella, and basil', 4, TRUE, 'Medium', 'https://images.example.com/pizza.jpg', 5),
(8, 'Thai Green Curry', 'Spicy Thai curry with vegetables and coconut milk', 4, TRUE, 'Hard', 'https://images.example.com/curry.jpg', 8),
(9, 'Greek Salad', 'Fresh Mediterranean salad with feta cheese and olives', 4, TRUE, 'Easy', 'https://images.example.com/greek-salad.jpg', 1),
(10, 'Chicken Tikka Masala', 'Indian curry with marinated chicken in spiced sauce', 4, TRUE, 'Hard', 'https://images.example.com/tikka.jpg', 7),
(11, 'Mushroom Risotto', 'Creamy Italian rice dish with mushrooms', 4, TRUE, 'Hard', 'https://images.example.com/risotto.jpg', 5),
(12, 'Fish and Chips', 'British classic with battered cod and fries', 2, TRUE, 'Medium', 'https://images.example.com/fish-chips.jpg', 4),
(13, 'Ratatouille', 'French vegetable stew from Provence', 6, TRUE, 'Medium', 'https://images.example.com/ratatouille.jpg', 6),
(14, 'Beef Bourguignon', 'French beef stew with red wine', 6, FALSE, 'Expert', 'https://images.example.com/bourguignon.jpg', 9),
(15, 'Pad Thai', 'Thai stir-fried noodles with shrimp', 2, TRUE, 'Medium', 'https://images.example.com/pad-thai.jpg', 8);

-- =====================================================
-- RECIPE INGREDIENTS DATA
-- =====================================================

-- Recipe 1: Spaghetti Carbonara
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(1, 33, 400, FALSE), -- Pasta
(1, 19, 200, FALSE), -- Bacon
(1, 65, 200, FALSE), -- Eggs (2 eggs)
(1, 26, 100, FALSE), -- Cheddar (or Parmesan)
(1, 44, 5, FALSE),   -- Black Pepper
(1, 43, 2, FALSE);   -- Salt

-- Recipe 2: Grilled Chicken Salad
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(2, 16, 300, FALSE), -- Chicken Breast
(2, 7, 100, FALSE),  -- Spinach
(2, 1, 200, FALSE),  -- Tomato
(2, 6, 100, FALSE),  -- Bell Pepper
(2, 51, 30, FALSE),  -- Olive Oil
(2, 14, 20, FALSE),  -- Lemon
(2, 43, 3, FALSE),   -- Salt
(2, 44, 2, FALSE);   -- Pepper

-- Recipe 3: Vegetable Stir-Fry
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(3, 6, 200, FALSE),  -- Bell Pepper
(3, 8, 200, FALSE),  -- Broccoli
(3, 4, 150, FALSE),  -- Carrot
(3, 9, 150, FALSE),  -- Mushrooms
(3, 3, 15, FALSE),   -- Garlic
(3, 57, 30, FALSE),  -- Soy Sauce
(3, 52, 30, FALSE),  -- Vegetable Oil
(3, 31, 300, TRUE);  -- Rice (optional)

-- Recipe 4: Beef Tacos
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(4, 17, 500, FALSE), -- Ground Beef
(4, 2, 150, FALSE),  -- Onion
(4, 1, 200, FALSE),  -- Tomato
(4, 26, 150, FALSE), -- Cheese
(4, 47, 10, FALSE),  -- Paprika
(4, 43, 5, FALSE),   -- Salt
(4, 44, 3, FALSE);   -- Pepper

-- Recipe 5: Salmon Teriyaki
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(5, 21, 400, FALSE), -- Salmon
(5, 57, 60, FALSE),  -- Soy Sauce
(5, 55, 30, FALSE),  -- Honey
(5, 3, 10, FALSE),   -- Garlic
(5, 8, 200, FALSE),  -- Broccoli
(5, 31, 200, FALSE), -- Rice
(5, 51, 20, FALSE);  -- Olive Oil

-- Recipe 6: French Onion Soup
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(6, 2, 800, FALSE),  -- Onion
(6, 28, 50, FALSE),  -- Butter
(6, 26, 200, FALSE), -- Cheese
(6, 34, 200, FALSE), -- Bread
(6, 49, 5, FALSE),   -- Thyme
(6, 43, 5, FALSE),   -- Salt
(6, 44, 3, FALSE);   -- Pepper

-- Recipe 7: Margherita Pizza
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(7, 61, 300, FALSE), -- Flour
(7, 1, 200, FALSE),  -- Tomato
(7, 30, 200, FALSE), -- Mozzarella
(7, 45, 20, FALSE),  -- Basil
(7, 51, 30, FALSE),  -- Olive Oil
(7, 43, 5, FALSE),   -- Salt
(7, 46, 5, TRUE);    -- Oregano (optional)

-- Recipe 8: Thai Green Curry
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(8, 16, 400, FALSE), -- Chicken
(8, 53, 200, FALSE), -- Coconut Oil/Milk
(8, 6, 200, FALSE),  -- Bell Pepper
(8, 10, 150, FALSE), -- Zucchini
(8, 3, 20, FALSE),   -- Garlic
(8, 45, 30, FALSE),  -- Basil
(8, 31, 300, TRUE);  -- Rice

-- Recipe 9: Greek Salad
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(9, 1, 400, FALSE),  -- Tomato
(9, 6, 200, FALSE),  -- Bell Pepper
(9, 2, 100, FALSE),  -- Onion
(9, 26, 200, FALSE), -- Feta Cheese
(9, 51, 50, FALSE),  -- Olive Oil
(9, 58, 20, FALSE),  -- Vinegar
(9, 46, 5, FALSE),   -- Oregano
(9, 43, 3, FALSE);   -- Salt

-- Recipe 10: Chicken Tikka Masala
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(10, 16, 600, FALSE), -- Chicken
(10, 27, 200, FALSE), -- Yogurt
(10, 1, 400, FALSE),  -- Tomato
(10, 29, 200, FALSE), -- Cream
(10, 3, 20, FALSE),   -- Garlic
(10, 47, 15, FALSE),  -- Paprika
(10, 31, 300, TRUE);  -- Rice

-- Recipe 11: Mushroom Risotto
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(11, 31, 300, FALSE), -- Rice (Arborio)
(11, 9, 300, FALSE),  -- Mushrooms
(11, 2, 100, FALSE),  -- Onion
(11, 28, 50, FALSE),  -- Butter
(11, 26, 100, FALSE), -- Parmesan
(11, 49, 5, FALSE),   -- Thyme
(11, 43, 3, FALSE);   -- Salt

-- Recipe 12: Fish and Chips
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(12, 24, 400, FALSE), -- Cod
(12, 5, 600, FALSE),  -- Potato
(12, 61, 200, FALSE), -- Flour
(12, 52, 500, FALSE), -- Oil for frying
(12, 43, 5, FALSE),   -- Salt
(12, 14, 50, TRUE);   -- Lemon

-- Recipe 13: Ratatouille
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(13, 1, 400, FALSE),  -- Tomato
(13, 10, 300, FALSE), -- Zucchini
(13, 6, 200, FALSE),  -- Bell Pepper
(13, 2, 200, FALSE),  -- Onion
(13, 3, 15, FALSE),   -- Garlic
(13, 51, 50, FALSE),  -- Olive Oil
(13, 49, 10, FALSE),  -- Thyme
(13, 45, 20, FALSE);  -- Basil

-- Recipe 15: Pad Thai
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, is_optional) VALUES
(15, 33, 200, FALSE), -- Rice noodles
(15, 23, 200, FALSE), -- Shrimp
(15, 65, 100, FALSE), -- Eggs
(15, 57, 50, FALSE),  -- Soy Sauce
(15, 14, 30, FALSE),  -- Lime/Lemon
(15, 54, 20, FALSE),  -- Sugar
(15, 42, 30, TRUE);   -- Peanut butter

-- =====================================================
-- RECIPE STEPS DATA
-- =====================================================

-- Recipe 1: Spaghetti Carbonara Steps
INSERT INTO recipe_steps (recipe_id, step_order, description, duration_minutes, step_type) VALUES
(1, 1, 'Boil water in a large pot with salt', 5, 'cooking'),
(1, 2, 'Cook pasta according to package directions', 10, 'cooking'),
(1, 3, 'Meanwhile, cook bacon until crispy', 8, 'cooking'),
(1, 4, 'Beat eggs with grated cheese and pepper', 3, 'action'),
(1, 5, 'Drain pasta, reserving 1 cup pasta water', 1, 'action'),
(1, 6, 'Mix hot pasta with bacon, then add egg mixture', 2, 'action'),
(1, 7, 'Toss quickly, adding pasta water if needed', 2, 'action'),
(1, 8, 'Serve immediately with extra cheese', 1, 'action');

-- Recipe 2: Grilled Chicken Salad Steps
INSERT INTO recipe_steps (recipe_id, step_order, description, duration_minutes, step_type) VALUES
(2, 1, 'Season chicken with salt and pepper', 2, 'action'),
(2, 2, 'Grill chicken for 6-7 minutes each side', 15, 'cooking'),
(2, 3, 'Let chicken rest, then slice', 5, 'action'),
(2, 4, 'Wash and prepare salad vegetables', 5, 'action'),
(2, 5, 'Mix olive oil with lemon juice for dressing', 2, 'action'),
(2, 6, 'Combine vegetables, add chicken on top', 2, 'action'),
(2, 7, 'Drizzle with dressing and serve', 1, 'action');

-- Recipe 3: Vegetable Stir-Fry Steps
INSERT INTO recipe_steps (recipe_id, step_order, description, duration_minutes, step_type) VALUES
(3, 1, 'Prepare all vegetables by cutting into uniform pieces', 10, 'action'),
(3, 2, 'Heat oil in wok or large pan over high heat', 2, 'cooking'),
(3, 3, 'Add garlic and stir for 30 seconds', 1, 'cooking'),
(3, 4, 'Add harder vegetables first (carrots, broccoli)', 3, 'cooking'),
(3, 5, 'Add remaining vegetables and stir-fry', 5, 'cooking'),
(3, 6, 'Add soy sauce and toss everything', 2, 'action'),
(3, 7, 'Serve hot over rice if desired', 1, 'action');

-- Recipe 5: Salmon Teriyaki Steps
INSERT INTO recipe_steps (recipe_id, step_order, description, duration_minutes, step_type) VALUES
(5, 1, 'Mix soy sauce, honey, and garlic for marinade', 3, 'action'),
(5, 2, 'Marinate salmon for 30 minutes', 30, 'action'),
(5, 3, 'Steam broccoli until tender', 8, 'cooking'),
(5, 4, 'Cook rice according to package directions', 20, 'cooking'),
(5, 5, 'Heat oil in pan over medium-high heat', 2, 'cooking'),
(5, 6, 'Cook salmon 4-5 minutes each side', 10, 'cooking'),
(5, 7, 'Brush with remaining marinade while cooking', 2, 'action'),
(5, 8, 'Serve salmon over rice with broccoli', 2, 'action');

-- Recipe 9: Greek Salad Steps
INSERT INTO recipe_steps (recipe_id, step_order, description, duration_minutes, step_type) VALUES
(9, 1, 'Cut tomatoes into wedges', 3, 'action'),
(9, 2, 'Slice bell peppers and onions', 3, 'action'),
(9, 3, 'Cube the feta cheese', 2, 'action'),
(9, 4, 'Combine all vegetables in a bowl', 1, 'action'),
(9, 5, 'Mix olive oil, vinegar, and oregano for dressing', 2, 'action'),
(9, 6, 'Pour dressing over salad', 1, 'action'),
(9, 7, 'Top with feta cheese and serve', 1, 'action');

-- =====================================================
-- USER INGREDIENT STOCK DATA
-- =====================================================

INSERT INTO user_ingredient_stock (user_id, ingredient_id, quantity, expiration_date, storage_location) VALUES
-- John's stock
(1, 16, 500, DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'Refrigerator'),
(1, 1, 1000, DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'Refrigerator'),
(1, 33, 500, DATE_ADD(CURDATE(), INTERVAL 180 DAY), 'Pantry'),
(1, 51, 750, DATE_ADD(CURDATE(), INTERVAL 365 DAY), 'Pantry'),

-- Marie's stock (vegetarian)
(2, 7, 300, DATE_ADD(CURDATE(), INTERVAL 3 DAY), 'Refrigerator'),
(2, 8, 400, DATE_ADD(CURDATE(), INTERVAL 4 DAY), 'Refrigerator'),
(2, 9, 250, DATE_ADD(CURDATE(), INTERVAL 2 DAY), 'Refrigerator'),
(2, 31, 1000, DATE_ADD(CURDATE(), INTERVAL 365 DAY), 'Pantry'),
(2, 51, 500, DATE_ADD(CURDATE(), INTERVAL 365 DAY), 'Pantry'),

-- Carlos's stock
(3, 17, 1000, DATE_ADD(CURDATE(), INTERVAL 3 DAY), 'Freezer'),
(3, 16, 800, DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'Freezer'),
(3, 1, 500, DATE_ADD(CURDATE(), INTERVAL 6 DAY), 'Refrigerator'),
(3, 2, 300, DATE_ADD(CURDATE(), INTERVAL 10 DAY), 'Pantry'),

-- Emma's stock
(4, 21, 600, DATE_ADD(CURDATE(), INTERVAL 2 DAY), 'Refrigerator'),
(4, 22, 400, DATE_ADD(CURDATE(), INTERVAL 60 DAY), 'Pantry'),
(4, 31, 2000, DATE_ADD(CURDATE(), INTERVAL 365 DAY), 'Pantry'),

-- Luigi's stock
(5, 33, 2000, DATE_ADD(CURDATE(), INTERVAL 365 DAY), 'Pantry'),
(5, 1, 1000, DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'Refrigerator'),
(5, 3, 100, DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'Pantry'),
(5, 51, 1000, DATE_ADD(CURDATE(), INTERVAL 365 DAY), 'Pantry'),
(5, 45, 50, DATE_ADD(CURDATE(), INTERVAL 180 DAY), 'Pantry'),

-- Some expired items for testing
(6, 25, 500, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'Refrigerator'),
(7, 27, 200, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'Refrigerator');

-- =====================================================
-- COMPLETED RECIPES DATA
-- =====================================================

INSERT INTO completed_recipes (user_id, recipe_id, rating, comment, completion_date) VALUES
-- John's completions
(1, 2, 5, 'Perfect lunch option, very healthy!', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(1, 9, 4, 'Great flavors, will make again', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(1, 3, 4, 'Quick and easy weeknight dinner', DATE_SUB(NOW(), INTERVAL 10 DAY)),

-- Marie's completions
(2, 3, 5, 'Delicious vegetarian option!', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(2, 13, 5, 'Authentic French taste, magnifique!', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(2, 9, 4, 'Fresh and light, perfect for summer', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(2, 11, 5, 'Creamy and rich, restaurant quality', DATE_SUB(NOW(), INTERVAL 12 DAY)),

-- Carlos's completions
(3, 4, 5, 'Best tacos ever! Family loved them', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(3, 1, 4, 'Classic Italian, very satisfying', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(3, 10, 5, 'Spicy and flavorful, amazing!', DATE_SUB(NOW(), INTERVAL 8 DAY)),

-- Emma's completions
(4, 5, 5, 'Salmon was perfectly cooked', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(4, 12, 4, 'Crispy and delicious', DATE_SUB(NOW(), INTERVAL 6 DAY)),
(4, 2, 4, 'Healthy and filling', DATE_SUB(NOW(), INTERVAL 11 DAY)),

-- Luigi's completions
(5, 1, 5, 'Just like nonna used to make!', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(5, 7, 5, 'Perfect pizza dough recipe', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(5, 11, 4, 'Good but needs more mushrooms', DATE_SUB(NOW(), INTERVAL 9 DAY)),
(5, 1, 5, 'Made it again, still perfect!', DATE_SUB(NOW(), INTERVAL 15 DAY)),

-- Sophie's completions
(6, 6, 5, 'Classic French comfort food', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(6, 13, 5, 'Beautiful presentation and taste', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(6, 3, 3, 'Good but needs more seasoning', DATE_SUB(NOW(), INTERVAL 10 DAY)),

-- James's completions
(7, 10, 5, 'Restaurant quality at home!', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(7, 2, 4, 'Great for meal prep', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(7, 4, 5, 'Kids loved these tacos', DATE_SUB(NOW(), INTERVAL 7 DAY)),

-- Anna's completions
(8, 8, 4, 'Very authentic Thai flavors', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(8, 15, 5, 'Better than takeout!', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(8, 3, 4, 'Quick and healthy', DATE_SUB(NOW(), INTERVAL 8 DAY)),

-- Pierre's completions
(9, 6, 5, 'Parfait! Truly French', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(9, 13, 5, 'Reminds me of Provence', DATE_SUB(NOW(), INTERVAL 6 DAY)),

-- Maria's completions
(10, 3, 4, 'Great vegetable dish', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(10, 9, 4, 'Fresh and tasty', DATE_SUB(NOW(), INTERVAL 4 DAY)),
(10, 5, 3, 'Good but salmon was a bit dry', DATE_SUB(NOW(), INTERVAL 10 DAY));


-- =====================================================
-- SAMPLE HISTORY DATA (for testing triggers)
-- =====================================================

INSERT INTO history_users (user_id, first_name, last_name, gender, email, role, country, city, is_active, birth_date, change_type, changed_at) VALUES
(1, 'John', 'Doe', 'Male', 'john.doe@email.com', 'Regular', 'USA', 'New York', TRUE, '1985-03-15', 'INSERT', DATE_SUB(NOW(), INTERVAL 30 DAY)),
(1, 'John', 'Doe', 'Male', 'john.doe@email.com', 'Administrator', 'USA', 'New York', TRUE, '1985-03-15', 'UPDATE', DATE_SUB(NOW(), INTERVAL 15 DAY));

INSERT INTO history_recipes (recipe_id, title, description, servings, difficulty, is_published, author_user_id, change_type, changed_at) VALUES
(1, 'Spaghetti Carbonara', 'Italian pasta with eggs and bacon', 4, 'Medium', FALSE, 5, 'INSERT', DATE_SUB(NOW(), INTERVAL 20 DAY)),
(1, 'Classic Spaghetti Carbonara', 'Traditional Italian pasta with eggs, cheese, and bacon', 4, 'Medium', TRUE, 5, 'UPDATE', DATE_SUB(NOW(), INTERVAL 10 DAY));

-- =====================================================
-- SAMPLE ERROR LOGS (for monitoring)
-- =====================================================

INSERT INTO error_logs (error_type, error_message, procedure_name, user_id, occurred_at, resolved) VALUES
('LOGIN_FAILED', 'Invalid password attempt', NULL, 1, DATE_SUB(NOW(), INTERVAL 5 DAY), TRUE),
('LOW_STOCK_WARNING', 'Low stock alert for ingredient #25', NULL, 6, DATE_SUB(NOW(), INTERVAL 1 DAY), FALSE),
('EXPIRATION_WARNING', 'Item expiring soon: ingredient #27', NULL, 7, NOW(), FALSE);

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- DATA VERIFICATION QUERIES
-- =====================================================

-- Show summary of inserted data
SELECT 'Users' as Table_Name, COUNT(*) as Record_Count FROM users
UNION SELECT 'Recipes', COUNT(*) FROM recipes
UNION SELECT 'Ingredients', COUNT(*) FROM ingredients
UNION SELECT 'Recipe Ingredients', COUNT(*) FROM recipe_ingredients
UNION SELECT 'Completed Recipes', COUNT(*) FROM completed_recipes
UNION SELECT 'User Stock Items', COUNT(*) FROM user_ingredient_stock
UNION SELECT 'User Allergies', COUNT(*) FROM user_allergies
UNION SELECT 'Categories', COUNT(*) FROM ingredient_categories;

-- Show some recipe statistics
SELECT 
    'Published Recipes' as Metric, 
    COUNT(*) as Value 
FROM recipes 
WHERE is_published = TRUE
UNION SELECT 
    'Average Rating', 
    ROUND(AVG(rating), 2) 
FROM completed_recipes
UNION SELECT 
    'Total Completions', 
    COUNT(*) 
FROM completed_recipes
UNION SELECT 
    'Active Users', 
    COUNT(*) 
FROM users 
WHERE is_active = TRUE;