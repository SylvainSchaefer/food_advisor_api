-- =============================================
-- Recettes d'exemple
-- =============================================
INSERT INTO recettes (titre, description, instructions, temps_preparation, temps_cuisson, nb_portions, difficulte, cout_estime, cree_par, note_moyenne, nb_evaluations, nb_realisations) VALUES
('Spaghetti Bolognaise', 'Un classique italien revisité avec une sauce bolognaise maison mijotée', 'Recette traditionnelle de pâtes à la bolognaise', 20, 120, 4, 'facile', 12.50, 2, 4.5, 15, 25),
('Salade César', 'Salade fraîche et croquante avec sa sauce crémeuse et ses croûtons dorés', 'Salade américaine classique au poulet grillé', 15, 10, 2, 'facile', 8.00, 2, 4.2, 8, 12),
('Ratatouille', 'Mélange savoureux de légumes du soleil mijotés ensemble', 'Plat végétarien traditionnel du sud de la France', 30, 45, 6, 'moyen', 10.00, 3, 4.6, 20, 30),
('Quiche Lorraine', 'Tarte salée garnie de lardons et de crème', 'Spécialité lorraine incontournable', 20, 35, 6, 'moyen', 9.00, 2, 4.3, 12, 18),
('Risotto aux champignons', 'Riz crémeux parfumé aux champignons de saison', 'Plat italien raffiné et réconfortant', 10, 30, 4, 'difficile', 15.00, 3, 4.7, 10, 15),
('Poulet rôti aux légumes', 'Poulet doré accompagné de légumes rôtis au four', 'Plat familial simple et savoureux', 15, 60, 4, 'facile', 14.00, 2, 4.4, 22, 35),
('Soupe à l\'oignon', 'Soupe gratinée traditionnelle française', 'Réconfortante soupe d\'hiver', 20, 40, 4, 'moyen', 6.00, 3, 4.5, 18, 28),
('Tarte aux pommes', 'Dessert classique avec des pommes fondantes', 'Pâtisserie française traditionnelle', 30, 40, 8, 'moyen', 7.00, 2, 4.8, 25, 40),
('Curry de légumes', 'Plat végétarien épicé et parfumé', 'Curry indien aux légumes variés', 20, 30, 4, 'facile', 8.50, 4, 4.3, 15, 20),
('Crêpes sucrées', 'Crêpes fines et légères pour le dessert', 'Recette bretonne traditionnelle', 10, 20, 12, 'facile', 4.00, 2, 4.6, 30, 50);

-- =============================================
-- Ingrédients des recettes
-- =============================================

-- Spaghetti Bolognaise (recette_id = 1)
INSERT INTO ingredients_recette (recette_id, ingredient_id, quantite, unite_mesure, optionnel, ordre) VALUES
(1, 33, 400, 'g', FALSE, 1), -- Pâtes
(1, 16, 500, 'g', FALSE, 2), -- Boeuf haché
(1, 1, 400, 'g', FALSE, 3), -- Tomate
(1, 3, 100, 'g', FALSE, 4), -- Oignon
(1, 2, 100, 'g', FALSE, 5), -- Carotte
(1, 10, 20, 'g', FALSE, 6), -- Ail
(1, 50, 30, 'ml', FALSE, 7), -- Huile d'olive
(1, 47, 5, 'g', TRUE, 8), -- Basilic
(1, 40, 5, 'g', FALSE, 9), -- Sel
(1, 41, 2, 'g', FALSE, 10); -- Poivre

-- Salade César (recette_id = 2)
INSERT INTO ingredients_recette (recette_id, ingredient_id, quantite, unite_mesure, optionnel, ordre) VALUES
(2, 17, 300, 'g', FALSE, 1), -- Poulet
(2, 9, 200, 'g', FALSE, 2), -- Épinards (ou salade)
(2, 26, 50, 'g', FALSE, 3), -- Fromage
(2, 35, 100, 'g', FALSE, 4), -- Pain (pour croûtons)
(2, 54, 1, 'piece', FALSE, 5), -- Oeuf
(2, 50, 50, 'ml', FALSE, 6), -- Huile d'olive
(2, 14, 30, 'ml', FALSE, 7), -- Citron
(2, 10, 10, 'g', FALSE, 8), -- Ail
(2, 40, 3, 'g', FALSE, 9); -- Sel

-- Ratatouille (recette_id = 3)
INSERT INTO ingredients_recette (recette_id, ingredient_id, quantite, unite_mesure, optionnel, ordre) VALUES
(3, 7, 300, 'g', FALSE, 1), -- Aubergine
(3, 5, 300, 'g', FALSE, 2), -- Courgette
(3, 6, 200, 'g', FALSE, 3), -- Poivron rouge
(3, 1, 400, 'g', FALSE, 4), -- Tomate
(3, 3, 100, 'g', FALSE, 5), -- Oignon
(3, 10, 15, 'g', FALSE, 6), -- Ail
(3, 50, 60, 'ml', FALSE, 7), -- Huile d'olive
(3, 49, 10, 'g', FALSE, 8), -- Thym
(3, 47, 10, 'g', TRUE, 9), -- Basilic
(3, 40, 5, 'g', FALSE, 10); -- Sel

-- Quiche Lorraine (recette_id = 4)
INSERT INTO ingredients_recette (recette_id, ingredient_id, quantite, unite_mesure, optionnel, ordre) VALUES
(4, 36, 250, 'g', FALSE, 1), -- Farine
(4, 29, 125, 'g', FALSE, 2), -- Beurre
(4, 54, 3, 'piece', FALSE, 3), -- Oeufs
(4, 28, 200, 'ml', FALSE, 4), -- Crème fraîche
(4, 20, 200, 'g', FALSE, 5), -- Jambon (ou lardons)
(4, 26, 100, 'g', TRUE, 6), -- Fromage
(4, 40, 3, 'g', FALSE, 7), -- Sel
(4, 41, 2, 'g', FALSE, 8); -- Poivre


-- Poulet rôti aux légumes (recette_id = 6)
INSERT INTO ingredients_recette (recette_id, ingredient_id, quantite, unite_mesure, optionnel, ordre) VALUES
(6, 17, 1200, 'g', FALSE, 1), -- Poulet entier
(6, 4, 500, 'g', FALSE, 2), -- Pommes de terre
(6, 2, 300, 'g', FALSE, 3), -- Carottes
(6, 3, 200, 'g', FALSE, 4), -- Oignon
(6, 10, 20, 'g', FALSE, 5), -- Ail
(6, 50, 60, 'ml', FALSE, 6), -- Huile d'olive
(6, 49, 10, 'g', FALSE, 7), -- Thym
(6, 14, 1, 'piece', TRUE, 8), -- Citron
(6, 40, 5, 'g', FALSE, 9); -- Sel

-- Tarte aux pommes (recette_id = 8)
INSERT INTO ingredients_recette (recette_id, ingredient_id, quantite, unite_mesure, optionnel, ordre) VALUES
(8, 36, 250, 'g', FALSE, 1), -- Farine
(8, 29, 125, 'g', FALSE, 2), -- Beurre
(8, 11, 800, 'g', FALSE, 3), -- Pommes
(8, 52, 100, 'g', FALSE, 4), -- Sucre
(8, 54, 1, 'piece', TRUE, 5), -- Oeuf
(8, 25, 50, 'ml', TRUE, 6), -- Lait
(8, 40, 2, 'g', FALSE, 7); -- Sel (pincée)

-- Curry de légumes (recette_id = 9)
INSERT INTO ingredients_recette (recette_id, ingredient_id, quantite, unite_mesure, optionnel, ordre) VALUES
(9, 4, 300, 'g', FALSE, 1), -- Pommes de terre
(9, 2, 200, 'g', FALSE, 2), -- Carottes
(9, 5, 200, 'g', FALSE, 3), -- Courgettes
(9, 6, 150, 'g', FALSE, 4), -- Poivron
(9, 3, 100, 'g', FALSE, 5), -- Oignon
(9, 1, 200, 'g', FALSE, 6), -- Tomates
(9, 45, 20, 'g', FALSE, 7), -- Curry
(9, 10, 15, 'g', FALSE, 8), -- Ail
(9, 50, 30, 'ml', FALSE, 9), -- Huile
(9, 40, 5, 'g', FALSE, 10); -- Sel

-- Crêpes sucrées (recette_id = 10)
INSERT INTO ingredients_recette (recette_id, ingredient_id, quantite, unite_mesure, optionnel, ordre) VALUES
(10, 36, 250, 'g', FALSE, 1), -- Farine
(10, 54, 3, 'piece', FALSE, 2), -- Oeufs
(10, 25, 500, 'ml', FALSE, 3), -- Lait
(10, 29, 50, 'g', FALSE, 4), -- Beurre fondu
(10, 52, 50, 'g', FALSE, 5), -- Sucre
(10, 40, 2, 'g', FALSE, 6); -- Sel (pincée)

-- =============================================
-- Étapes des recettes (exemples pour quelques recettes)
-- =============================================

-- Étapes pour Spaghetti Bolognaise
INSERT INTO etapes_recette (recette_id, numero_etape, description, duree_minutes) VALUES
(1, 1, 'Émincer finement l\'oignon et l\'ail. Couper les carottes en petits dés.', 5),
(1, 2, 'Faire chauffer l\'huile d\'olive dans une grande casserole. Faire revenir l\'oignon jusqu\'à ce qu\'il soit translucide.', 5),
(1, 3, 'Ajouter la viande hachée et la faire brunir en la défaisant à la cuillère.', 10),
(1, 4, 'Ajouter les carottes, l\'ail, les tomates concassées. Saler, poivrer et ajouter le basilic.', 5),
(1, 5, 'Laisser mijoter à feu doux pendant 1h30 à 2h en remuant régulièrement.', 120),
(1, 6, 'Pendant ce temps, faire cuire les pâtes selon les instructions du paquet.', 10),
(1, 7, 'Servir les pâtes avec la sauce bolognaise et parsemer de parmesan râpé.', 2);

-- Étapes pour Salade César
INSERT INTO etapes_recette (recette_id, numero_etape, description, duree_minutes) VALUES
(2, 1, 'Faire griller le poulet assaisonné dans une poêle avec un peu d\'huile.', 10),
(2, 2, 'Couper le pain en cubes et les faire dorer au four pour faire des croûtons.', 10),
(2, 3, 'Laver et essorer la salade. La disposer dans un saladier.', 3),
(2, 4, 'Préparer la sauce : mélanger l\'oeuf, l\'huile, le citron, l\'ail écrasé et le parmesan.', 5),
(2, 5, 'Couper le poulet en tranches et l\'ajouter sur la salade.', 2),
(2, 6, 'Ajouter les croûtons, verser la sauce et mélanger délicatement.', 2);

-- Étapes pour Ratatouille
INSERT INTO etapes_recette (recette_id, numero_etape, description, duree_minutes) VALUES
(3, 1, 'Laver et couper tous les légumes en dés d\'environ 2 cm.', 15),
(3, 2, 'Faire chauffer l\'huile d\'olive dans une grande casserole.', 2),
(3, 3, 'Faire revenir les oignons jusqu\'à ce qu\'ils soient translucides.', 5),
(3, 4, 'Ajouter les aubergines et les faire dorer légèrement.', 8),
(3, 5, 'Ajouter les courgettes et les poivrons, faire revenir 5 minutes.', 5),
(3, 6, 'Ajouter les tomates, l\'ail, le thym et le basilic. Saler et poivrer.', 3),
(3, 7, 'Couvrir et laisser mijoter à feu doux pendant 30 minutes.', 30),
(3, 8, 'Rectifier l\'assaisonnement et servir chaud ou froid.', 2);

-- =============================================
-- Favoris de recettes (exemples)
-- =============================================
INSERT INTO recettes_favoris (utilisateur_id, recette_id) VALUES
(2, 1), (2, 3), (2, 5), (2, 8),
(3, 2), (3, 6), (3, 7),
(4, 3), (4, 9), (4, 10),
(5, 1), (5, 4), (5, 8);

-- =============================================
-- Historique de réalisations
-- =============================================
INSERT INTO historique_recettes (utilisateur_id, recette_id, date_realisation, note, nb_portions_realisees, stock_mis_a_jour) VALUES
(2, 1, DATE_SUB(NOW(), INTERVAL 5 DAY), 5, 4, TRUE),
(2, 3, DATE_SUB(NOW(), INTERVAL 10 DAY), 4, 6, FALSE),
(2, 1, DATE_SUB(NOW(), INTERVAL 15 DAY), 5, 4, TRUE),
(3, 2, DATE_SUB(NOW(), INTERVAL 3 DAY), 4, 2, TRUE),
(3, 6, DATE_SUB(NOW(), INTERVAL 7 DAY), 5, 4, TRUE),
(4, 3, DATE_SUB(NOW(), INTERVAL 2 DAY), 5, 6, FALSE),
(4, 9, DATE_SUB(NOW(), INTERVAL 8 DAY), 4, 4, TRUE),
(5, 8, DATE_SUB(NOW(), INTERVAL 1 DAY), 5, 8, FALSE);

-- =============================================
-- Commentaires et avis
-- =============================================
INSERT INTO commentaires (recette_id, utilisateur_id, commentaire, note, historique_id) VALUES
(1, 2, 'Excellente recette ! La sauce était parfaite après 2h de cuisson.', 5, 1),
(3, 2, 'Très bon mais j\'ai ajouté un peu plus d\'ail pour plus de goût.', 4, 2),
(2, 3, 'Salade fraîche et délicieuse. La sauce César maison fait toute la différence !', 4, 4),
(6, 3, 'Le poulet était juteux et les légumes parfaitement rôtis. Un régal !', 5, 5),
(3, 4, 'Un classique toujours apprécié. J\'ai utilisé des herbes de mon jardin.', 5, 6),
(9, 4, 'Bon curry mais j\'ai dû ajouter du lait de coco pour adoucir.', 4, 7),
(8, 5, 'La meilleure tarte aux pommes que j\'ai faite ! Pâte croustillante et pommes fondantes.', 5, 8);

-- =============================================
-- Stocks utilisateurs (exemples)
-- =============================================
INSERT INTO stocks_utilisateur (utilisateur_id, ingredient_id, quantite, unite_mesure, date_peremption, emplacement) VALUES
-- Stocks de Marie (id=2)
(2, 1, 500, 'g', DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'frigo'),
(2, 3, 300, 'g', DATE_ADD(CURDATE(), INTERVAL 10 DAY), 'garde-manger'),
(2, 33, 1000, 'g', NULL, 'garde-manger'),
(2, 50, 500, 'ml', NULL, 'garde-manger'),
(2, 17, 500, 'g', DATE_ADD(CURDATE(), INTERVAL 2 DAY), 'frigo'),
-- Stocks de Jean (id=3)
(3, 4, 2000, 'g', DATE_ADD(CURDATE(), INTERVAL 20 DAY), 'garde-manger'),
(3, 25, 1000, 'ml', DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'frigo'),
(3, 54, 12, 'piece', DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'frigo'),
(3, 36, 2000, 'g', NULL, 'garde-manger'),
-- Stocks de Sophie (id=4)
(4, 5, 300, 'g', DATE_ADD(CURDATE(), INTERVAL 4 DAY), 'frigo'),
(4, 6, 250, 'g', DATE_ADD(CURDATE(), INTERVAL 6 DAY), 'frigo'),
(4, 7, 400, 'g', DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'frigo'),
(4, 34, 500, 'g', NULL, 'garde-manger'),
(4, 38, 200, 'g', NULL, 'garde-manger');

-- =============================================
-- Préférences alimentaires utilisateurs
-- =============================================
-- Marie est végétarienne
INSERT INTO preferences_ingredients (utilisateur_id, ingredient_id, type_preference) VALUES
(2, 16, 'exclu'), -- Pas de boeuf
(2, 18, 'exclu'), -- Pas de porc
(2, 19, 'exclu'), -- Pas de agneau
(2, 21, 'exclu'), -- Pas de saumon
(2, 22, 'exclu'), -- Pas de cabillaud
(2, 23, 'exclu'), -- Pas de thon
(2, 24, 'exclu'); -- Pas de crevettes

-- Sophie est allergique au gluten
INSERT INTO preferences_alimentaires (utilisateur_id, allergene_id, type_preference, severite) VALUES
(4, 1, 'allergie', 'severe');

-- Pierre évite les produits laitiers
INSERT INTO preferences_alimentaires (utilisateur_id, allergene_id, type_preference, severite) VALUES
(5, 2, 'intolerance', 'moderee');

-- =============================================
-- Listes de courses exemples
-- =============================================
INSERT INTO liste_courses (utilisateur_id, nom, date_courses_prevue, statut) VALUES
(2, 'Courses weekend', DATE_ADD(CURDATE(), INTERVAL 2 DAY), 'en_cours'),
(3, 'Repas famille dimanche', DATE_ADD(CURDATE(), INTERVAL 4 DAY), 'en_cours');

INSERT INTO liste_courses_ingredients (liste_id, ingredient_id, quantite, unite_mesure, recette_id, achete) VALUES
-- Liste de Marie
(1, 16, 500, 'g', 1, FALSE), -- Boeuf pour bolognaise
(1, 2, 200, 'g', 1, FALSE), -- Carottes
(1, 29, 200, 'g', NULL, FALSE), -- Beurre
-- Liste de Jean  
(2, 17, 1500, 'g', 6, FALSE), -- Poulet pour rôti
(2, 4, 1000, 'g', 6, FALSE), -- Pommes de terre
(2, 14, 2, 'piece', 6, TRUE); -- Citrons (déjà acheté)