-- =============================================
-- Régimes alimentaires
-- =============================================
INSERT INTO regimes_alimentaires (nom, description) VALUES
('Omnivore', 'Aucune restriction alimentaire'),
('Végétarien', 'Pas de viande ni de poisson'),
('Végétalien', 'Aucun produit d\'origine animale'),
('Sans gluten', 'Exclusion du gluten'),
('Sans lactose', 'Exclusion des produits laitiers'),
('Halal', 'Conforme aux prescriptions musulmanes'),
('Casher', 'Conforme aux prescriptions juives'),
('Pescétarien', 'Végétarien + poisson'),
('Flexitarien', 'Principalement végétarien avec viande occasionnelle'),
('Cétogène', 'Très faible en glucides, riche en graisses'),
('Paléo', 'Alimentation inspirée du paléolithique');

-- =============================================
-- Catégories d'ingrédients
-- =============================================
INSERT INTO categories_ingredients (nom, description, icone) VALUES
('Légumes', 'Légumes frais et surgelés', '🥬'),
('Fruits', 'Fruits frais et secs', '🍎'),
('Viandes', 'Viandes rouges et blanches', '🥩'),
('Poissons', 'Poissons et fruits de mer', '🐟'),
('Produits laitiers', 'Lait, fromages, yaourts', '🧀'),
('Céréales', 'Pâtes, riz, blé, avoine', '🌾'),
('Légumineuses', 'Haricots, lentilles, pois', '🫘'),
('Épices', 'Épices et aromates', '🌶️'),
('Condiments', 'Sauces et assaisonnements', '🧂'),
('Huiles', 'Huiles et matières grasses', '🫒'),
('Sucres', 'Sucres et édulcorants', '🍯'),
('Boissons', 'Boissons non alcoolisées', '🥤'),
('Alcools', 'Vins, bières et spiritueux', '🍷'),
('Oeufs', 'Oeufs et ovoproduits', '🥚'),
('Noix', 'Fruits à coque et graines', '🥜'),
('Herbes', 'Herbes fraîches et séchées', '🌿');

-- =============================================
-- Allergènes
-- =============================================
INSERT INTO allergenes (nom, description, niveau_risque) VALUES
('Gluten', 'Présent dans le blé, seigle, orge', 'eleve'),
('Lactose', 'Sucre du lait', 'moyen'),
('Arachides', 'Cacahuètes', 'eleve'),
('Fruits à coque', 'Noix, amandes, noisettes, etc.', 'eleve'),
('Oeufs', 'Oeufs et ovoproduits', 'moyen'),
('Soja', 'Soja et dérivés', 'moyen'),
('Poisson', 'Tous types de poissons', 'eleve'),
('Crustacés', 'Crevettes, crabes, homards', 'eleve'),
('Mollusques', 'Huîtres, moules, escargots', 'moyen'),
('Céleri', 'Céleri et dérivés', 'faible'),
('Moutarde', 'Graines de moutarde', 'faible'),
('Sésame', 'Graines de sésame', 'moyen'),
('Sulfites', 'Conservateurs E220-E228', 'faible'),
('Lupin', 'Farine de lupin', 'faible');

-- =============================================
-- Utilisateurs de test (mot de passe: password123 hashé)
-- =============================================
INSERT INTO utilisateurs (email, mot_de_passe, nom, prenom, date_naissance, sexe, ville, code_postal, pays, role, regime_alimentaire_id) VALUES
('admin@recettes.fr', SHA2('password123', 256), 'Admin', 'Système', '1980-01-01', 'M', 'Paris', '75001', 'France', 'administrateur', 1),
('marie.dubois@email.fr', SHA2('password123', 256), 'Dubois', 'Marie', '1990-05-15', 'F', 'Lyon', '69000', 'France', 'utilisateur', 2),
('jean.martin@email.fr', SHA2('password123', 256), 'Martin', 'Jean', '1985-08-22', 'M', 'Marseille', '13000', 'France', 'utilisateur', 1),
('sophie.bernard@email.fr', SHA2('password123', 256), 'Bernard', 'Sophie', '1995-03-10', 'F', 'Toulouse', '31000', 'France', 'utilisateur', 3),
('pierre.durand@email.fr', SHA2('password123', 256), 'Durand', 'Pierre', '1988-11-30', 'M', 'Nice', '06000', 'France', 'utilisateur', 4);

-- =============================================
-- Ingrédients de base
-- =============================================
INSERT INTO ingredients (nom, categorie_id, unite_mesure, calories_par_100g, proteines_par_100g, glucides_par_100g, lipides_par_100g, fibres_par_100g, prix_estime, duree_conservation_jours, cree_par, approuve) VALUES
-- Légumes
('Tomate', 1, 'g', 18, 0.9, 3.9, 0.2, 1.2, 2.50, 7, 1, TRUE),
('Carotte', 1, 'g', 41, 0.9, 10, 0.2, 2.8, 1.50, 14, 1, TRUE),
('Oignon', 1, 'g', 40, 1.1, 9.3, 0.1, 1.7, 1.20, 30, 1, TRUE),
('Pomme de terre', 1, 'g', 77, 2, 17, 0.1, 2.2, 1.00, 21, 1, TRUE),
('Courgette', 1, 'g', 17, 1.2, 3.1, 0.3, 1, 2.80, 7, 1, TRUE),
('Poivron rouge', 1, 'g', 31, 1, 6, 0.3, 2.1, 3.50, 10, 1, TRUE),
('Aubergine', 1, 'g', 25, 1, 6, 0.2, 3, 2.90, 7, 1, TRUE),
('Brocoli', 1, 'g', 34, 2.8, 7, 0.4, 2.6, 3.20, 7, 1, TRUE),
('Épinards', 1, 'g', 23, 2.9, 3.6, 0.4, 2.2, 2.50, 3, 1, TRUE),
('Ail', 1, 'g', 149, 6.4, 33, 0.5, 2.1, 4.00, 60, 1, TRUE),

-- Fruits
('Pomme', 2, 'g', 52, 0.3, 14, 0.2, 2.4, 2.00, 30, 1, TRUE),
('Banane', 2, 'g', 89, 1.1, 23, 0.3, 2.6, 1.50, 7, 1, TRUE),
('Orange', 2, 'g', 47, 0.9, 12, 0.1, 2.4, 2.20, 14, 1, TRUE),
('Citron', 2, 'g', 29, 1.1, 9, 0.3, 2.8, 2.50, 21, 1, TRUE),
('Fraise', 2, 'g', 32, 0.7, 7.7, 0.3, 2, 5.00, 3, 1, TRUE),

-- Viandes
('Boeuf haché', 3, 'g', 250, 26, 0, 17, 0, 8.50, 2, 1, TRUE),
('Poulet', 3, 'g', 165, 31, 0, 3.6, 0, 6.50, 2, 1, TRUE),
('Porc', 3, 'g', 242, 27, 0, 14, 0, 7.00, 3, 1, TRUE),
('Agneau', 3, 'g', 294, 25, 0, 21, 0, 12.00, 2, 1, TRUE),
('Jambon blanc', 3, 'g', 145, 21, 1, 6, 0, 9.00, 7, 1, TRUE),

-- Poissons
('Saumon', 4, 'g', 208, 20, 0, 13, 0, 15.00, 2, 1, TRUE),
('Cabillaud', 4, 'g', 82, 18, 0, 0.7, 0, 12.00, 2, 1, TRUE),
('Thon en conserve', 4, 'g', 116, 26, 0, 1, 0, 8.00, 365, 1, TRUE),
('Crevettes', 4, 'g', 85, 20, 0, 0.5, 0, 18.00, 2, 1, TRUE),

-- Produits laitiers
('Lait entier', 5, 'ml', 61, 3.2, 4.8, 3.3, 0, 1.10, 7, 1, TRUE),
('Fromage emmental', 5, 'g', 380, 29, 1.5, 29, 0, 12.00, 30, 1, TRUE),
('Yaourt nature', 5, 'g', 61, 3.5, 4.7, 3.3, 0, 2.50, 14, 1, TRUE),
('Crème fraîche', 5, 'ml', 292, 2.4, 3, 30, 0, 3.50, 7, 1, TRUE),
('Beurre', 5, 'g', 717, 0.9, 0.1, 81, 0, 8.00, 30, 1, TRUE),
('Mozzarella', 5, 'g', 280, 28, 3, 17, 0, 6.50, 7, 1, TRUE),

-- Céréales
('Pâtes', 6, 'g', 371, 13, 75, 1.5, 3, 1.50, 365, 1, TRUE),
('Riz blanc', 6, 'g', 365, 7, 80, 0.7, 1.3, 2.00, 365, 1, TRUE),
('Pain', 6, 'g', 265, 9, 49, 3.2, 2.7, 1.20, 3, 1, TRUE),
('Farine de blé', 6, 'g', 364, 10, 76, 1, 2.7, 0.80, 365, 1, TRUE),
('Quinoa', 6, 'g', 368, 14, 64, 6, 7, 5.00, 365, 1, TRUE),

-- Légumineuses
('Lentilles', 7, 'g', 353, 26, 60, 1, 11, 3.00, 365, 1, TRUE),
('Haricots rouges', 7, 'g', 333, 24, 60, 0.9, 25, 3.50, 365, 1, TRUE),
('Pois chiches', 7, 'g', 364, 19, 61, 6, 17, 3.20, 365, 1, TRUE),

-- Épices et condiments
('Sel', 9, 'g', 0, 0, 0, 0, 0, 0.50, 9999, 1, TRUE),
('Poivre noir', 8, 'g', 251, 11, 64, 3.3, 25, 8.00, 999, 1, TRUE),
('Paprika', 8, 'g', 282, 14, 54, 13, 35, 6.00, 999, 1, TRUE),
('Cumin', 8, 'g', 375, 18, 44, 22, 11, 7.00, 999, 1, TRUE),
('Curry', 8, 'g', 325, 13, 56, 14, 53, 5.00, 999, 1, TRUE),
('Basilic frais', 16, 'g', 23, 3.2, 2.7, 0.6, 1.6, 3.00, 3, 1, TRUE),
('Persil frais', 16, 'g', 36, 3, 6.3, 0.8, 3.3, 2.50, 3, 1, TRUE),
('Thym séché', 8, 'g', 276, 9, 64, 7.4, 37, 4.50, 365, 1, TRUE),

-- Huiles
('Huile d\'olive', 10, 'ml', 884, 0, 0, 100, 0, 8.00, 365, 1, TRUE),
('Huile de tournesol', 10, 'ml', 884, 0, 0, 100, 0, 3.50, 365, 1, TRUE),

-- Sucres
('Sucre blanc', 11, 'g', 387, 0, 100, 0, 0, 1.20, 9999, 1, TRUE),
('Miel', 11, 'g', 304, 0.3, 82, 0, 0.2, 10.00, 730, 1, TRUE),

-- Oeufs
('Oeuf', 14, 'piece', 155, 13, 1.1, 11, 0, 0.35, 28, 1, TRUE),

-- Autres
('Eau', 12, 'ml', 0, 0, 0, 0, 0, 0.001, 9999, 1, TRUE),
('Vin rouge', 13, 'ml', 85, 0.1, 2.6, 0, 0, 5.00, 730, 1, TRUE),
('Chocolat noir', 11, 'g', 546, 5, 61, 31, 7, 12.00, 365, 1, TRUE);

-- =============================================
-- Associations ingrédients-allergènes
-- =============================================
INSERT INTO ingredients_allergenes (ingredient_id, allergene_id) VALUES
-- Gluten
(33, 1), (34, 1), (35, 1), -- Pâtes, Pain, Farine
-- Lactose
(25, 2), (26, 2), (27, 2), (28, 2), (29, 2), (30, 2), -- Produits laitiers
-- Oeufs
(54, 5), -- Oeuf
-- Poisson
(21, 7), (22, 7), (23, 7), -- Poissons
-- Crustacés
(24, 8); -- Crevettes