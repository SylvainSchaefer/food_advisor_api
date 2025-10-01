USE food_advisor_db;
-- =============================================
-- Fichier: 02_indexes.sql
-- Description: Création des index supplémentaires pour optimiser les performances
-- Base de données: MySQL 8.0+
-- =============================================

-- =============================================
-- Index composites pour optimiser les requêtes fréquentes
-- =============================================

-- Index pour la recherche de recettes par utilisateur et statut
CREATE INDEX idx_recettes_user_publie 
ON recettes(cree_par, publie, created_at DESC);

-- Index pour les recommandations de recettes
CREATE INDEX idx_recettes_recommandation 
ON recettes(publie, note_moyenne DESC, nb_evaluations DESC);

-- Index pour la recherche de recettes par difficulté et temps
CREATE INDEX idx_recettes_difficulte_temps
ON recettes(difficulte, temps_total, publie);

-- Index pour la gestion des stocks proches de péremption
CREATE INDEX idx_stocks_peremption_user 
ON stocks_utilisateur(utilisateur_id, date_peremption, quantite);

-- Index pour l'historique récent des recettes
CREATE INDEX idx_historique_recent 
ON historique_recettes(utilisateur_id, date_realisation DESC, note);

-- Index pour les recettes réalisables avec les stocks
CREATE INDEX idx_ingredients_recette_quantite 
ON ingredients_recette(ingredient_id, quantite, optionnel);

-- Index pour les préférences utilisateurs
CREATE INDEX idx_preferences_actives 
ON preferences_ingredients(utilisateur_id, type_preference);

-- Index pour les commentaires récents
CREATE INDEX idx_commentaires_recent 
ON commentaires(recette_id, created_at DESC);

-- Index pour la recherche d'allergènes
CREATE INDEX idx_ingredients_allergenes_search 
ON ingredients_allergenes(allergene_id, ingredient_id);

-- Index pour les listes de courses
CREATE INDEX idx_liste_courses_active 
ON liste_courses(utilisateur_id, statut, date_courses_prevue);

-- Index pour les statistiques utilisateur
CREATE INDEX idx_historique_stats 
ON historique_recettes(utilisateur_id, note, date_realisation);

-- Index pour la recherche de recettes favorites
CREATE INDEX idx_favoris_user_date 
ON recettes_favoris(utilisateur_id, created_at DESC);

-- Index pour l'optimisation des calculs de coût
CREATE INDEX idx_ingredients_prix 
ON ingredients(approuve, prix_estime);

-- Index pour la recherche par catégorie d'ingrédients
CREATE INDEX idx_ingredients_categorie_nom 
ON ingredients(categorie_id, nom, approuve);

-- =============================================
-- Index de texte intégral supplémentaires
-- =============================================

-- Index fulltext pour la recherche dans les instructions
ALTER TABLE recettes 
ADD FULLTEXT idx_fulltext_instructions (instructions);

-- Index fulltext pour la recherche dans les commentaires
ALTER TABLE commentaires 
ADD FULLTEXT idx_fulltext_commentaire (commentaire);

-- Index fulltext pour la recherche d'ingrédients
ALTER TABLE ingredients 
ADD FULLTEXT idx_fulltext_nom (nom);

-- =============================================
-- Vues matérialisées (simulées avec des tables)
-- =============================================

-- Table pour stocker les statistiques calculées des recettes
CREATE TABLE IF NOT EXISTS stats_recettes (
    recette_id INT PRIMARY KEY,
    note_moyenne DECIMAL(3,2),
    nb_evaluations INT,
    nb_realisations INT,
    derniere_realisation DATETIME,
    cout_moyen DECIMAL(6,2),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (recette_id) REFERENCES recettes(id) ON DELETE CASCADE,
    INDEX idx_stats_note (note_moyenne DESC),
    INDEX idx_stats_popularite (nb_realisations DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table pour stocker les compatibilités régime/recette
CREATE TABLE IF NOT EXISTS recettes_regimes_compatibles (
    recette_id INT NOT NULL,
    regime_id INT NOT NULL,
    compatible BOOLEAN DEFAULT TRUE,
    verifie BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (recette_id, regime_id),
    FOREIGN KEY (recette_id) REFERENCES recettes(id) ON DELETE CASCADE,
    FOREIGN KEY (regime_id) REFERENCES regimes_alimentaires(id) ON DELETE CASCADE,
    INDEX idx_regime_compatible (regime_id, compatible)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Index pour les performances des jointures
-- =============================================

-- Amélioration des performances pour les jointures fréquentes
CREATE INDEX idx_ingredients_recette_join 
ON ingredients_recette(recette_id, ingredient_id, quantite);

CREATE INDEX idx_stocks_join 
ON stocks_utilisateur(utilisateur_id, ingredient_id, quantite);

CREATE INDEX idx_historique_join 
ON historique_recettes(utilisateur_id, recette_id, date_realisation);