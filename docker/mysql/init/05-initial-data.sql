-- =============================================
-- Dietary regimens
-- =============================================
INSERT INTO dietary_regimens (name, description) VALUES
('Omnivore', 'No dietary restrictions'),
('Vegetarian', 'No meat or fish'),
('Vegan', 'No animal products'),
('Gluten-free', 'Gluten exclusion'),
('Lactose-free', 'Dairy products exclusion'),
('Halal', 'Compliant with Muslim prescriptions'),
('Kosher', 'Compliant with Jewish prescriptions'),
('Pescatarian', 'Vegetarian + fish'),
('Flexitarian', 'Mainly vegetarian with occasional meat'),
('Ketogenic', 'Very low carb, high fat'),
('Paleo', 'Paleolithic-inspired diet');

-- =============================================
-- Ingredient categories
-- =============================================
INSERT INTO ingredient_categories (name, description, icon) VALUES
('Vegetables', 'Fresh and frozen vegetables', '🥬'),
('Fruits', 'Fresh and dried fruits', '🍎'),
('Meats', 'Red and white meats', '🥩'),
('Fish', 'Fish and seafood', '🐟'),
('Dairy products', 'Milk, cheeses, yogurts', '🧀'),
('Grains', 'Pasta, rice, wheat, oats', '🌾'),
('Legumes', 'Beans, lentils, peas', '🫘'),
('Spices', 'Spices and aromatics', '🌶️'),
('Condiments', 'Sauces and seasonings', '🧂'),
('Oils', 'Oils and fats', '🫒'),
('Sugars', 'Sugars and sweeteners', '🍯'),
('Beverages', 'Non-alcoholic beverages', '🥤'),
('Alcohols', 'Wines, beers and spirits', '🍷'),
('Eggs', 'Eggs and egg products', '🥚'),
('Nuts', 'Tree nuts and seeds', '🥜'),
('Herbs', 'Fresh and dried herbs', '🌿');

-- =============================================
-- Allergens
-- =============================================
INSERT INTO allergens (name, description, risk_level) VALUES
('Gluten', 'Present in wheat, rye, barley', 'high'),
('Lactose', 'Milk sugar', 'medium'),
('Peanuts', 'Peanuts', 'high'),
('Tree nuts', 'Walnuts, almonds, hazelnuts, etc.', 'high'),
('Eggs', 'Eggs and egg products', 'medium'),
('Soy', 'Soy and derivatives', 'medium'),
('Fish', 'All types of fish', 'high'),
('Crustaceans', 'Shrimp, crabs, lobsters', 'high'),
('Mollusks', 'Oysters, mussels, snails', 'medium'),
('Celery', 'Celery and derivatives', 'low'),
('Mustard', 'Mustard seeds', 'low'),
('Sesame', 'Sesame seeds', 'medium'),
('Sulfites', 'Preservatives E220-E228', 'low'),
('Lupin', 'Lupin flour', 'low');

-- =============================================
-- Test users (connexion sans mot de passe)
-- =============================================
INSERT INTO users (email, password_hash, last_name, first_name, date_of_birth, gender, city, postal_code, country, role, dietary_regimen_id) VALUES
('admin@recipes.com', '', 'Admin', 'System', '1980-01-01', 'M', 'Paris', '75001', 'France', 'administrator', 1),
('marie.dubois@email.fr', '', 'Dubois', 'Marie', '1990-05-15', 'F', 'Lyon', '69000', 'France', 'user', 2),
('jean.martin@email.fr', '', 'Martin', 'Jean', '1985-08-22', 'M', 'Marseille', '13000', 'France', 'user', 1),
('sophie.bernard@email.fr', '', 'Bernard', 'Sophie', '1995-03-10', 'F', 'Toulouse', '31000', 'France', 'user', 3),
('pierre.durand@email.fr', '', 'Durand', 'Pierre', '1988-11-30', 'M', 'Nice', '06000', 'France', 'user', 4);

-- =============================================
-- Basic ingredients
-- =============================================
INSERT INTO ingredients (name, category_id, unit_of_measure, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, estimated_price, shelf_life_days, created_by, approved) VALUES
-- Vegetables
('Tomato', 1, 'g', 18, 0.9, 3.9, 0.2, 1.2, 2.50, 7, 1, TRUE),
('Carrot', 1, 'g', 41, 0.9, 10, 0.2, 2.8, 1.50, 14, 1, TRUE),
('Onion', 1, 'g', 40, 1.1, 9.3, 0.1, 1.7, 1.20, 30, 1, TRUE),
('Potato', 1, 'g', 77, 2, 17, 0.1, 2.2, 1.00, 21, 1, TRUE),
('Zucchini', 1, 'g', 17, 1.2, 3.1, 0.3, 1, 2.80, 7, 1, TRUE),
('Red bell pepper', 1, 'g', 31, 1, 6, 0.3, 2.1, 3.50, 10, 1, TRUE),
('Eggplant', 1, 'g', 25, 1, 6, 0.2, 3, 2.90, 7, 1, TRUE),
('Broccoli', 1, 'g', 34, 2.8, 7, 0.4, 2.6, 3.20, 7, 1, TRUE),
('Spinach', 1, 'g', 23, 2.9, 3.6, 0.4, 2.2, 2.50, 3, 1, TRUE),
('Garlic', 1, 'g', 149, 6.4, 33, 0.5, 2.1, 4.00, 60, 1, TRUE),

-- Fruits
('Apple', 2, 'g', 52, 0.3, 14, 0.2, 2.4, 2.00, 30, 1, TRUE),
('Banana', 2, 'g', 89, 1.1, 23, 0.3, 2.6, 1.50, 7, 1, TRUE),
('Orange', 2, 'g', 47, 0.9, 12, 0.1, 2.4, 2.20, 14, 1, TRUE),
('Lemon', 2, 'g', 29, 1.1, 9, 0.3, 2.8, 2.50, 21, 1, TRUE),
('Strawberry', 2, 'g', 32, 0.7, 7.7, 0.3, 2, 5.00, 3, 1, TRUE),

-- Meats
('Ground beef', 3, 'g', 250, 26, 0, 17, 0, 8.50, 2, 1, TRUE),
('Chicken', 3, 'g', 165, 31, 0, 3.6, 0, 6.50, 2, 1, TRUE),
('Pork', 3, 'g', 242, 27, 0, 14, 0, 7.00, 3, 1, TRUE),
('Lamb', 3, 'g', 294, 25, 0, 21, 0, 12.00, 2, 1, TRUE),
('Ham', 3, 'g', 145, 21, 1, 6, 0, 9.00, 7, 1, TRUE),

-- Fish
('Salmon', 4, 'g', 208, 20, 0, 13, 0, 15.00, 2, 1, TRUE),
('Cod', 4, 'g', 82, 18, 0, 0.7, 0, 12.00, 2, 1, TRUE),
('Canned tuna', 4, 'g', 116, 26, 0, 1, 0, 8.00, 365, 1, TRUE),
('Shrimp', 4, 'g', 85, 20, 0, 0.5, 0, 18.00, 2, 1, TRUE),

-- Dairy products
('Whole milk', 5, 'ml', 61, 3.2, 4.8, 3.3, 0, 1.10, 7, 1, TRUE),
('Emmental cheese', 5, 'g', 380, 29, 1.5, 29, 0, 12.00, 30, 1, TRUE),
('Plain yogurt', 5, 'g', 61, 3.5, 4.7, 3.3, 0, 2.50, 14, 1, TRUE),
('Heavy cream', 5, 'ml', 292, 2.4, 3, 30, 0, 3.50, 7, 1, TRUE),
('Butter', 5, 'g', 717, 0.9, 0.1, 81, 0, 8.00, 30, 1, TRUE),
('Mozzarella', 5, 'g', 280, 28, 3, 17, 0, 6.50, 7, 1, TRUE),

-- Grains
('Pasta', 6, 'g', 371, 13, 75, 1.5, 3, 1.50, 365, 1, TRUE),
('White rice', 6, 'g', 365, 7, 80, 0.7, 1.3, 2.00, 365, 1, TRUE),
('Bread', 6, 'g', 265, 9, 49, 3.2, 2.7, 1.20, 3, 1, TRUE),
('Wheat flour', 6, 'g', 364, 10, 76, 1, 2.7, 0.80, 365, 1, TRUE),
('Quinoa', 6, 'g', 368, 14, 64, 6, 7, 5.00, 365, 1, TRUE),

-- Legumes
('Lentils', 7, 'g', 353, 26, 60, 1, 11, 3.00, 365, 1, TRUE),
('Red kidney beans', 7, 'g', 333, 24, 60, 0.9, 25, 3.50, 365, 1, TRUE),
('Chickpeas', 7, 'g', 364, 19, 61, 6, 17, 3.20, 365, 1, TRUE),

-- Spices and condiments
('Salt', 9, 'g', 0, 0, 0, 0, 0, 0.50, 9999, 1, TRUE),
('Black pepper', 8, 'g', 251, 11, 64, 3.3, 25, 8.00, 999, 1, TRUE),
('Paprika', 8, 'g', 282, 14, 54, 13, 35, 6.00, 999, 1, TRUE),
('Cumin', 8, 'g', 375, 18, 44, 22, 11, 7.00, 999, 1, TRUE),
('Curry', 8, 'g', 325, 13, 56, 14, 53, 5.00, 999, 1, TRUE),
('Fresh basil', 16, 'g', 23, 3.2, 2.7, 0.6, 1.6, 3.00, 3, 1, TRUE),
('Fresh parsley', 16, 'g', 36, 3, 6.3, 0.8, 3.3, 2.50, 3, 1, TRUE),
('Dried thyme', 8, 'g', 276, 9, 64, 7.4, 37, 4.50, 365, 1, TRUE),

-- Oils
('Olive oil', 10, 'ml', 884, 0, 0, 100, 0, 8.00, 365, 1, TRUE),
('Sunflower oil', 10, 'ml', 884, 0, 0, 100, 0, 3.50, 365, 1, TRUE),

-- Sugars
('White sugar', 11, 'g', 387, 0, 100, 0, 0, 1.20, 9999, 1, TRUE),
('Honey', 11, 'g', 304, 0.3, 82, 0, 0.2, 10.00, 730, 1, TRUE),

-- Eggs
('Egg', 14, 'piece', 155, 13, 1.1, 11, 0, 0.35, 28, 1, TRUE),

-- Others
('Water', 12, 'ml', 0, 0, 0, 0, 0, 0.001, 9999, 1, TRUE),
('Red wine', 13, 'ml', 85, 0.1, 2.6, 0, 0, 5.00, 730, 1, TRUE),
('Dark chocolate', 11, 'g', 546, 5, 61, 31, 7, 12.00, 365, 1, TRUE);

-- =============================================
-- Ingredient-allergen associations
-- =============================================
INSERT INTO ingredient_allergens (ingredient_id, allergen_id) VALUES
-- Gluten
(33, 1), (34, 1), (35, 1), -- Pasta, Bread, Flour
-- Lactose
(25, 2), (26, 2), (27, 2), (28, 2), (29, 2), (30, 2), -- Dairy products
-- Eggs
(54, 5), -- Egg
-- Fish
(21, 7), (22, 7), (23, 7), -- Fish
-- Crustaceans
(24, 8); -- Shrimp