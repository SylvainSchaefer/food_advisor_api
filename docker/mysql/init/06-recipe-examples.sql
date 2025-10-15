-- =============================================
-- Example recipes
-- =============================================
INSERT INTO recipes (title, description, instructions, prep_time, cook_time, servings, difficulty, estimated_cost, created_by, average_rating, rating_count, completion_count) VALUES
('Spaghetti Bolognese', 'An Italian classic revisited with homemade simmered bolognese sauce', 'Traditional pasta bolognese recipe', 20, 120, 4, 'easy', 12.50, 2, 4.5, 15, 25),
('Caesar Salad', 'Fresh and crispy salad with creamy dressing and golden croutons', 'Classic American salad with grilled chicken', 15, 10, 2, 'easy', 8.00, 2, 4.2, 8, 12),
('Ratatouille', 'Savory blend of sun-kissed vegetables simmered together', 'Traditional vegetarian dish from southern France', 30, 45, 6, 'medium', 10.00, 3, 4.6, 20, 30),
('Quiche Lorraine', 'Savory tart filled with bacon and cream', 'Iconic Lorraine specialty', 20, 35, 6, 'medium', 9.00, 2, 4.3, 12, 18),
('Mushroom Risotto', 'Creamy rice flavored with seasonal mushrooms', 'Refined and comforting Italian dish', 10, 30, 4, 'hard', 15.00, 3, 4.7, 10, 15),
('Roasted Chicken with Vegetables', 'Golden chicken with oven-roasted vegetables', 'Simple and tasty family dish', 15, 60, 4, 'easy', 14.00, 2, 4.4, 22, 35),
('French Onion Soup', 'Traditional French gratinated soup', 'Comforting winter soup', 20, 40, 4, 'medium', 6.00, 3, 4.5, 18, 28),
('Apple Pie', 'Classic dessert with tender apples', 'Traditional French pastry', 30, 40, 8, 'medium', 7.00, 2, 4.8, 25, 40),
('Vegetable Curry', 'Spicy and fragrant vegetarian dish', 'Indian curry with assorted vegetables', 20, 30, 4, 'easy', 8.50, 4, 4.3, 15, 20),
('Sweet Crepes', 'Thin and light crepes for dessert', 'Traditional Breton recipe', 10, 20, 12, 'easy', 4.00, 2, 4.6, 30, 50);

-- =============================================
-- Recipe ingredients
-- =============================================

-- Spaghetti Bolognese (recipe_id = 1)
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, unit_of_measure, optional, order_position) VALUES
(1, 33, 400, 'g', FALSE, 1), -- Pasta
(1, 16, 500, 'g', FALSE, 2), -- Ground beef
(1, 1, 400, 'g', FALSE, 3), -- Tomato
(1, 3, 100, 'g', FALSE, 4), -- Onion
(1, 2, 100, 'g', FALSE, 5), -- Carrot
(1, 10, 20, 'g', FALSE, 6), -- Garlic
(1, 50, 30, 'ml', FALSE, 7), -- Olive oil
(1, 47, 5, 'g', TRUE, 8), -- Basil
(1, 40, 5, 'g', FALSE, 9), -- Salt
(1, 41, 2, 'g', FALSE, 10); -- Pepper

-- Caesar Salad (recipe_id = 2)
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, unit_of_measure, optional, order_position) VALUES
(2, 17, 300, 'g', FALSE, 1), -- Chicken
(2, 9, 200, 'g', FALSE, 2), -- Spinach (or lettuce)
(2, 26, 50, 'g', FALSE, 3), -- Cheese
(2, 35, 100, 'g', FALSE, 4), -- Bread (for croutons)
(2, 54, 1, 'piece', FALSE, 5), -- Egg
(2, 50, 50, 'ml', FALSE, 6), -- Olive oil
(2, 14, 30, 'ml', FALSE, 7), -- Lemon
(2, 10, 10, 'g', FALSE, 8), -- Garlic
(2, 40, 3, 'g', FALSE, 9); -- Salt

-- Ratatouille (recipe_id = 3)
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, unit_of_measure, optional, order_position) VALUES
(3, 7, 300, 'g', FALSE, 1), -- Eggplant
(3, 5, 300, 'g', FALSE, 2), -- Zucchini
(3, 6, 200, 'g', FALSE, 3), -- Red bell pepper
(3, 1, 400, 'g', FALSE, 4), -- Tomato
(3, 3, 100, 'g', FALSE, 5), -- Onion
(3, 10, 15, 'g', FALSE, 6), -- Garlic
(3, 50, 60, 'ml', FALSE, 7), -- Olive oil
(3, 49, 10, 'g', FALSE, 8), -- Thyme
(3, 47, 10, 'g', TRUE, 9), -- Basil
(3, 40, 5, 'g', FALSE, 10); -- Salt

-- Quiche Lorraine (recipe_id = 4)
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, unit_of_measure, optional, order_position) VALUES
(4, 36, 250, 'g', FALSE, 1), -- Flour
(4, 29, 125, 'g', FALSE, 2), -- Butter
(4, 54, 3, 'piece', FALSE, 3), -- Eggs
(4, 28, 200, 'ml', FALSE, 4), -- Heavy cream
(4, 20, 200, 'g', FALSE, 5), -- Ham (or bacon)
(4, 26, 100, 'g', TRUE, 6), -- Cheese
(4, 40, 3, 'g', FALSE, 7), -- Salt
(4, 41, 2, 'g', FALSE, 8); -- Pepper

-- Roasted Chicken with Vegetables (recipe_id = 6)
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, unit_of_measure, optional, order_position) VALUES
(6, 17, 1200, 'g', FALSE, 1), -- Whole chicken
(6, 4, 500, 'g', FALSE, 2), -- Potatoes
(6, 2, 300, 'g', FALSE, 3), -- Carrots
(6, 3, 200, 'g', FALSE, 4), -- Onion
(6, 10, 20, 'g', FALSE, 5), -- Garlic
(6, 50, 60, 'ml', FALSE, 6), -- Olive oil
(6, 49, 10, 'g', FALSE, 7), -- Thyme
(6, 14, 1, 'piece', TRUE, 8), -- Lemon
(6, 40, 5, 'g', FALSE, 9); -- Salt

-- Apple Pie (recipe_id = 8)
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, unit_of_measure, optional, order_position) VALUES
(8, 36, 250, 'g', FALSE, 1), -- Flour
(8, 29, 125, 'g', FALSE, 2), -- Butter
(8, 11, 800, 'g', FALSE, 3), -- Apples
(8, 52, 100, 'g', FALSE, 4), -- Sugar
(8, 54, 1, 'piece', TRUE, 5), -- Egg
(8, 25, 50, 'ml', TRUE, 6), -- Milk
(8, 40, 2, 'g', FALSE, 7); -- Salt (pinch)

-- Vegetable Curry (recipe_id = 9)
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, unit_of_measure, optional, order_position) VALUES
(9, 4, 300, 'g', FALSE, 1), -- Potatoes
(9, 2, 200, 'g', FALSE, 2), -- Carrots
(9, 5, 200, 'g', FALSE, 3), -- Zucchini
(9, 6, 150, 'g', FALSE, 4), -- Bell pepper
(9, 3, 100, 'g', FALSE, 5), -- Onion
(9, 1, 200, 'g', FALSE, 6), -- Tomatoes
(9, 45, 20, 'g', FALSE, 7), -- Curry
(9, 10, 15, 'g', FALSE, 8), -- Garlic
(9, 50, 30, 'ml', FALSE, 9), -- Oil
(9, 40, 5, 'g', FALSE, 10); -- Salt

-- Sweet Crepes (recipe_id = 10)
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, unit_of_measure, optional, order_position) VALUES
(10, 36, 250, 'g', FALSE, 1), -- Flour
(10, 54, 3, 'piece', FALSE, 2), -- Eggs
(10, 25, 500, 'ml', FALSE, 3), -- Milk
(10, 29, 50, 'g', FALSE, 4), -- Melted butter
(10, 52, 50, 'g', FALSE, 5), -- Sugar
(10, 40, 2, 'g', FALSE, 6); -- Salt (pinch)

-- =============================================
-- Recipe steps (examples for some recipes)
-- =============================================

-- Steps for Spaghetti Bolognese
INSERT INTO recipe_steps (recipe_id, step_number, description, duration_minutes) VALUES
(1, 1, 'Finely chop the onion and garlic. Cut the carrots into small dice.', 5),
(1, 2, 'Heat the olive oil in a large pot. Sauté the onion until translucent.', 5),
(1, 3, 'Add the ground meat and brown it while breaking it up with a spoon.', 10),
(1, 4, 'Add the carrots, garlic, and crushed tomatoes. Season with salt, pepper, and add basil.', 5),
(1, 5, 'Simmer over low heat for 1.5 to 2 hours, stirring regularly.', 120),
(1, 6, 'Meanwhile, cook the pasta according to package instructions.', 10),
(1, 7, 'Serve the pasta with the bolognese sauce and sprinkle with grated parmesan.', 2);

-- Steps for Caesar Salad
INSERT INTO recipe_steps (recipe_id, step_number, description, duration_minutes) VALUES
(2, 1, 'Grill the seasoned chicken in a pan with a little oil.', 10),
(2, 2, 'Cut the bread into cubes and toast them in the oven to make croutons.', 10),
(2, 3, 'Wash and dry the lettuce. Place it in a salad bowl.', 3),
(2, 4, 'Prepare the dressing: mix egg, oil, lemon, crushed garlic, and parmesan.', 5),
(2, 5, 'Slice the chicken and add it to the salad.', 2),
(2, 6, 'Add the croutons, pour the dressing, and toss gently.', 2);

-- Steps for Ratatouille
INSERT INTO recipe_steps (recipe_id, step_number, description, duration_minutes) VALUES
(3, 1, 'Wash and cut all vegetables into approximately 2cm dice.', 15),
(3, 2, 'Heat the olive oil in a large pot.', 2),
(3, 3, 'Sauté the onions until translucent.', 5),
(3, 4, 'Add the eggplant and lightly brown it.', 8),
(3, 5, 'Add the zucchini and bell peppers, sauté for 5 minutes.', 5),
(3, 6, 'Add the tomatoes, garlic, thyme, and basil. Season with salt and pepper.', 3),
(3, 7, 'Cover and simmer over low heat for 30 minutes.', 30),
(3, 8, 'Adjust seasoning and serve hot or cold.', 2);

-- =============================================
-- Favorite recipes (examples)
-- =============================================
INSERT INTO favorite_recipes (user_id, recipe_id) VALUES
(2, 1), (2, 3), (2, 5), (2, 8),
(3, 2), (3, 6), (3, 7),
(4, 3), (4, 9), (4, 10),
(5, 1), (5, 4), (5, 8);

-- =============================================
-- Completion history
-- =============================================
INSERT INTO recipe_history (user_id, recipe_id, completion_date, rating, servings_made, stock_updated) VALUES
(2, 1, DATE_SUB(NOW(), INTERVAL 5 DAY), 5, 4, TRUE),
(2, 3, DATE_SUB(NOW(), INTERVAL 10 DAY), 4, 6, FALSE),
(2, 1, DATE_SUB(NOW(), INTERVAL 15 DAY), 5, 4, TRUE),
(3, 2, DATE_SUB(NOW(), INTERVAL 3 DAY), 4, 2, TRUE),
(3, 6, DATE_SUB(NOW(), INTERVAL 7 DAY), 5, 4, TRUE),
(4, 3, DATE_SUB(NOW(), INTERVAL 2 DAY), 5, 6, FALSE),
(4, 9, DATE_SUB(NOW(), INTERVAL 8 DAY), 4, 4, TRUE),
(5, 8, DATE_SUB(NOW(), INTERVAL 1 DAY), 5, 8, FALSE);

-- =============================================
-- Comments and reviews
-- =============================================
INSERT INTO comments (recipe_id, user_id, comment, rating, history_id) VALUES
(1, 2, 'Excellent recipe! The sauce was perfect after 2 hours of cooking.', 5, 1),
(3, 2, 'Very good but I added a bit more garlic for extra flavor.', 4, 2),
(2, 3, 'Fresh and delicious salad. The homemade Caesar dressing makes all the difference!', 4, 4),
(6, 3, 'The chicken was juicy and the vegetables perfectly roasted. A delight!', 5, 5),
(3, 4, 'A classic that\'s always appreciated. I used herbs from my garden.', 5, 6),
(9, 4, 'Good curry but I had to add coconut milk to mellow it out.', 4, 7),
(8, 5, 'The best apple pie I\'ve made! Crispy crust and tender apples.', 5, 8);

-- =============================================
-- User stock (examples)
-- =============================================
INSERT INTO user_stock (user_id, ingredient_id, quantity, unit_of_measure, expiration_date, location) VALUES
-- Marie's stock (id=2)
(2, 1, 500, 'g', DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'fridge'),
(2, 3, 300, 'g', DATE_ADD(CURDATE(), INTERVAL 10 DAY), 'pantry'),
(2, 33, 1000, 'g', NULL, 'pantry'),
(2, 50, 500, 'ml', NULL, 'pantry'),
(2, 17, 500, 'g', DATE_ADD(CURDATE(), INTERVAL 2 DAY), 'fridge'),
-- Jean's stock (id=3)
(3, 4, 2000, 'g', DATE_ADD(CURDATE(), INTERVAL 20 DAY), 'pantry'),
(3, 25, 1000, 'ml', DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'fridge'),
(3, 54, 12, 'piece', DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'fridge'),
(3, 36, 2000, 'g', NULL, 'pantry'),
-- Sophie's stock (id=4)
(4, 5, 300, 'g', DATE_ADD(CURDATE(), INTERVAL 4 DAY), 'fridge'),
(4, 6, 250, 'g', DATE_ADD(CURDATE(), INTERVAL 6 DAY), 'fridge'),
(4, 7, 400, 'g', DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'fridge'),
(4, 34, 500, 'g', NULL, 'pantry'),
(4, 38, 200, 'g', NULL, 'pantry');

-- =============================================
-- User dietary preferences
-- =============================================
-- Marie is vegetarian
INSERT INTO ingredient_preferences (user_id, ingredient_id, preference_type) VALUES
(2, 16, 'excluded'), -- No beef
(2, 18, 'excluded'), -- No pork
(2, 19, 'excluded'), -- No lamb
(2, 21, 'excluded'), -- No salmon
(2, 22, 'excluded'), -- No cod
(2, 23, 'excluded'), -- No tuna
(2, 24, 'excluded'); -- No shrimp

-- Sophie is allergic to gluten
INSERT INTO dietary_preferences (user_id, allergen_id, preference_type, severity) VALUES
(4, 1, 'allergy', 'severe');

-- Pierre avoids dairy products
INSERT INTO dietary_preferences (user_id, allergen_id, preference_type, severity) VALUES
(5, 2, 'intolerance', 'moderate');

-- =============================================
-- Example shopping lists
-- =============================================
INSERT INTO shopping_lists (user_id, name, planned_shopping_date, status) VALUES
(2, 'Weekend shopping', DATE_ADD(CURDATE(), INTERVAL 2 DAY), 'in_progress'),
(3, 'Sunday family meal', DATE_ADD(CURDATE(), INTERVAL 4 DAY), 'in_progress');

INSERT INTO shopping_list_ingredients (list_id, ingredient_id, quantity, unit_of_measure, recipe_id, purchased) VALUES
-- Marie's list
(1, 16, 500, 'g', 1, FALSE), -- Beef for bolognese
(1, 2, 200, 'g', 1, FALSE), -- Carrots
(1, 29, 200, 'g', NULL, FALSE), -- Butter
-- Jean's list
(2, 17, 1500, 'g', 6, FALSE), -- Chicken for roast
(2, 4, 1000, 'g', 6, FALSE), -- Potatoes
(2, 14, 2, 'piece', 6, TRUE); -- Lemons (already purchased)