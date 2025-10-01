-- =============================================
-- VUES
-- =============================================

-- Vue : Recettes avec toutes leurs informations
CREATE OR REPLACE VIEW v_recettes_completes AS
SELECT 
    r.*,
    u.nom AS createur_nom,
    u.prenom AS createur_prenom,
    COUNT(DISTINCT ir.ingredient_id) AS nb_ingredients,
    COUNT(DISTINCT c.id) AS nb_commentaires,
    COUNT(DISTINCT rf.utilisateur_id) AS nb_favoris,
    fn_calculer_cout_recette(r.id) AS cout_calcule
FROM recettes r
LEFT JOIN utilisateurs u ON r.cree_par = u.id
LEFT JOIN ingredients_recette ir ON r.id = ir.recette_id
LEFT JOIN commentaires c ON r.id = c.recette_id AND c.visible = TRUE
LEFT JOIN recettes_favoris rf ON r.id = rf.recette_id
GROUP BY r.id;

-- Vue : Stocks proches de la péremption
CREATE OR REPLACE VIEW v_stocks_a_consommer AS
SELECT 
    su.utilisateur_id,
    u.nom,
    u.prenom,
    i.nom AS ingredient,
    su.quantite,
    su.unite_mesure,
    su.date_peremption,
    DATEDIFF(su.date_peremption, CURDATE()) AS jours_restants,
    i.categorie_id,
    ci.nom AS categorie
FROM stocks_utilisateur su
INNER JOIN utilisateurs u ON su.utilisateur_id = u.id
INNER JOIN ingredients i ON su.ingredient_id = i.id
INNER JOIN categories_ingredients ci ON i.categorie_id = ci.id
WHERE su.date_peremption IS NOT NULL
    AND su.date_peremption <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
    AND su.quantite > 0
ORDER BY su.date_peremption ASC;

-- Vue : Recettes populaires du mois
CREATE OR REPLACE VIEW v_recettes_populaires_mois AS
SELECT 
    r.id,
    r.titre,
    r.description,
    r.note_moyenne,
    COUNT(DISTINCT hr.id) AS realisations_mois,
    COUNT(DISTINCT hr.utilisateur_id) AS utilisateurs_uniques
FROM recettes r
INNER JOIN historique_recettes hr ON r.id = hr.recette_id
WHERE hr.date_realisation >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    AND r.publie = TRUE
GROUP BY r.id
ORDER BY realisations_mois DESC, r.note_moyenne DESC
LIMIT 10;

-- Vue : Compatibilité recettes/régimes
CREATE OR REPLACE VIEW v_recettes_vegetariennes AS
SELECT DISTINCT r.*
FROM recettes r
WHERE NOT EXISTS (
    SELECT 1 
    FROM ingredients_recette ir
    INNER JOIN ingredients i ON ir.ingredient_id = i.id
    WHERE ir.recette_id = r.id 
        AND i.categorie_id IN (3, 4) -- Viandes et Poissons
)
AND r.publie = TRUE;

-- Vue : Statistiques par utilisateur
CREATE OR REPLACE VIEW v_stats_utilisateurs AS
SELECT 
    u.id,
    u.nom,
    u.prenom,
    COUNT(DISTINCT r.id) AS nb_recettes_creees,
    COUNT(DISTINCT hr.recette_id) AS nb_recettes_realisees,
    COUNT(DISTINCT hr.id) AS nb_total_realisations,
    AVG(hr.note) AS note_moyenne_donnee,
    COUNT(DISTINCT c.id) AS nb_commentaires,
    COUNT(DISTINCT rf.recette_id) AS nb_favoris
FROM utilisateurs u
LEFT JOIN recettes r ON u.id = r.cree_par
LEFT JOIN historique_recettes hr ON u.id = hr.utilisateur_id
LEFT JOIN commentaires c ON u.id = c.utilisateur_id
LEFT JOIN recettes_favoris rf ON u.id = rf.utilisateur_id
GROUP BY u.id;

-- Vue : Ingredients les plus utilisés
CREATE OR REPLACE VIEW v_ingredients_populaires AS
SELECT 
    i.id,
    i.nom,
    ci.nom AS categorie,
    COUNT(DISTINCT ir.recette_id) AS nb_recettes,
    AVG(r.note_moyenne) AS note_moyenne_recettes
FROM ingredients i
INNER JOIN categories_ingredients ci ON i.categorie_id = ci.id
INNER JOIN ingredients_recette ir ON i.id = ir.ingredient_id
INNER JOIN recettes r ON ir.recette_id = r.id
WHERE r.publie = TRUE
GROUP BY i.id
ORDER BY nb_recettes DESC;

-- =============================================
-- TRIGGERS SUPPLÉMENTAIRES
-- =============================================

DELIMITER //

-- Trigger : Validation des quantités d'ingrédients
CREATE TRIGGER trg_valider_quantite_ingredient
BEFORE INSERT ON ingredients_recette
FOR EACH ROW
BEGIN
    IF NEW.quantite <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'La quantité doit être supérieure à 0';
    END IF;
END//

-- Trigger : Mise à jour automatique du coût estimé d'une recette
CREATE TRIGGER trg_update_cout_recette_insert
AFTER INSERT ON ingredients_recette
FOR EACH ROW
BEGIN
    UPDATE recettes
    SET cout_estime = fn_calculer_cout_recette(NEW.recette_id)
    WHERE id = NEW.recette_id;
END//

CREATE TRIGGER trg_update_cout_recette_update
AFTER UPDATE ON ingredients_recette
FOR EACH ROW
BEGIN
    UPDATE recettes
    SET cout_estime = fn_calculer_cout_recette(NEW.recette_id)
    WHERE id = NEW.recette_id;
END//

CREATE TRIGGER trg_update_cout_recette_delete
AFTER DELETE ON ingredients_recette
FOR EACH ROW
BEGIN
    UPDATE recettes
    SET cout_estime = fn_calculer_cout_recette(OLD.recette_id)
    WHERE id = OLD.recette_id;
END//

-- Trigger : Archivage automatique des listes de courses anciennes
CREATE TRIGGER trg_archiver_liste_courses
BEFORE UPDATE ON liste_courses
FOR EACH ROW
BEGIN
    IF NEW.statut = 'complete' 
       AND OLD.statut = 'en_cours' 
       AND DATEDIFF(CURDATE(), NEW.date_creation) > 30 THEN
        SET NEW.statut = 'archivee';
    END IF;
END//

-- Trigger : Empêcher la suppression d'ingrédients utilisés
CREATE TRIGGER trg_prevent_ingredient_delete
BEFORE DELETE ON ingredients
FOR EACH ROW
BEGIN
    DECLARE nb_utilisations INT;
    
    SELECT COUNT(*) INTO nb_utilisations
    FROM ingredients_recette
    WHERE ingredient_id = OLD.id;
    
    IF nb_utilisations > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Impossible de supprimer un ingrédient utilisé dans des recettes';
    END IF;
END//

-- Trigger : Log des modifications de recettes
CREATE TRIGGER trg_log_recette_modification
BEFORE UPDATE ON recettes
FOR EACH ROW
BEGIN
    IF OLD.titre != NEW.titre OR OLD.description != NEW.description THEN
        SET NEW.updated_at = CURRENT_TIMESTAMP;
    END IF;
END//

-- Trigger : Validation cohérence régime alimentaire
CREATE TRIGGER trg_valider_regime_utilisateur
BEFORE UPDATE ON utilisateurs
FOR EACH ROW
BEGIN
    -- Si passage à végétarien, vérifier les préférences
    IF NEW.regime_alimentaire_id = 2 AND OLD.regime_alimentaire_id != 2 THEN
        -- On pourrait ajouter automatiquement les exclusions de viande
        -- mais pour l'instant on laisse juste passer
        SET NEW.updated_at = CURRENT_TIMESTAMP;
    END IF;
END//

DELIMITER ;

-- =============================================
-- FONCTIONS SUPPLÉMENTAIRES
-- =============================================

DELIMITER //

-- Fonction : Vérifier si une recette est réalisable avec les stocks
CREATE FUNCTION fn_recette_realisable(
    p_recette_id INT,
    p_utilisateur_id INT
)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE ingredients_necessaires INT;
    DECLARE ingredients_disponibles INT;
    
    -- Compter les ingrédients nécessaires (non optionnels)
    SELECT COUNT(DISTINCT ingredient_id) INTO ingredients_necessaires
    FROM ingredients_recette
    WHERE recette_id = p_recette_id AND optionnel = FALSE;
    
    -- Compter les ingrédients disponibles en stock
    SELECT COUNT(DISTINCT ir.ingredient_id) INTO ingredients_disponibles
    FROM ingredients_recette ir
    INNER JOIN stocks_utilisateur su ON ir.ingredient_id = su.ingredient_id
    WHERE ir.recette_id = p_recette_id 
        AND ir.optionnel = FALSE
        AND su.utilisateur_id = p_utilisateur_id
        AND su.quantite >= ir.quantite
        AND (su.date_peremption IS NULL OR su.date_peremption > CURDATE());
    
    RETURN (ingredients_disponibles = ingredients_necessaires);
END//

-- Fonction : Calculer le score de compatibilité d'une recette
CREATE FUNCTION fn_score_compatibilite(
    p_recette_id INT,
    p_utilisateur_id INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE score INT DEFAULT 100;
    DECLARE nb_ingredients_exclus INT;
    DECLARE nb_allergenes INT;
    
    -- Vérifier les ingrédients exclus
    SELECT COUNT(*) INTO nb_ingredients_exclus
    FROM ingredients_recette ir
    INNER JOIN preferences_ingredients pi ON ir.ingredient_id = pi.ingredient_id
    WHERE ir.recette_id = p_recette_id 
        AND pi.utilisateur_id = p_utilisateur_id
        AND pi.type_preference IN ('exclu', 'evite');
    
    -- Vérifier les allergènes
    SELECT COUNT(*) INTO nb_allergenes
    FROM ingredients_recette ir
    INNER JOIN ingredients_allergenes ia ON ir.ingredient_id = ia.ingredient_id
    INNER JOIN preferences_alimentaires pa ON ia.allergene_id = pa.allergene_id
    WHERE ir.recette_id = p_recette_id 
        AND pa.utilisateur_id = p_utilisateur_id;
    
    -- Calculer le score
    SET score = score - (nb_ingredients_exclus * 50) - (nb_allergenes * 100);
    
    IF score < 0 THEN
        SET score = 0;
    END IF;
    
    RETURN score;
END//

-- Fonction : Obtenir le prochain repas suggéré
CREATE FUNCTION fn_prochain_repas_suggere(
    p_utilisateur_id INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE recette_id INT;
    
    -- Sélectionner une recette non réalisée récemment et compatible
    SELECT r.id INTO recette_id
    FROM recettes r
    WHERE r.publie = TRUE
        AND fn_score_compatibilite(r.id, p_utilisateur_id) > 50
        AND NOT EXISTS (
            SELECT 1 
            FROM historique_recettes hr
            WHERE hr.recette_id = r.id 
                AND hr.utilisateur_id = p_utilisateur_id
                AND hr.date_realisation > DATE_SUB(CURDATE(), INTERVAL 14 DAY)
        )
    ORDER BY r.note_moyenne DESC, RAND()
    LIMIT 1;
    
    RETURN recette_id;
END//

DELIMITER ;

-- =============================================
-- PROCÉDURES DE MAINTENANCE
-- =============================================

DELIMITER //

-- Procédure : Nettoyer les données anciennes
CREATE PROCEDURE sp_maintenance_cleanup()
BEGIN
    DECLARE nb_lignes_supprimees INT DEFAULT 0;
    
    -- Supprimer les listes de courses archivées de plus de 6 mois
    DELETE FROM liste_courses
    WHERE statut = 'archivee' 
        AND created_at < DATE_SUB(CURDATE(), INTERVAL 6 MONTH);
    SET nb_lignes_supprimees = nb_lignes_supprimees + ROW_COUNT();
    
    -- Supprimer les stocks vides et périmés depuis plus de 30 jours
    DELETE FROM stocks_utilisateur
    WHERE quantite = 0 
        AND date_peremption < DATE_SUB(CURDATE(), INTERVAL 30 DAY);
    SET nb_lignes_supprimees = nb_lignes_supprimees + ROW_COUNT();
    
    -- Désactiver les comptes inactifs depuis plus d'un an
    UPDATE utilisateurs
    SET actif = FALSE
    WHERE actif = TRUE
        AND id NOT IN (
            SELECT DISTINCT utilisateur_id 
            FROM historique_recettes 
            WHERE date_realisation > DATE_SUB(CURDATE(), INTERVAL 365 DAY)
        )
        AND updated_at < DATE_SUB(CURDATE(), INTERVAL 365 DAY);
    
    SELECT nb_lignes_supprimees AS total_lignes_supprimees;
END//

-- Procédure : Recalculer toutes les statistiques
CREATE PROCEDURE sp_recalculer_stats()
BEGIN
    -- Recalculer les notes moyennes
    UPDATE recettes r
    SET 
        note_moyenne = (
            SELECT AVG(note)
            FROM commentaires
            WHERE recette_id = r.id AND note IS NOT NULL AND visible = TRUE
        ),
        nb_evaluations = (
            SELECT COUNT(*)
            FROM commentaires
            WHERE recette_id = r.id AND note IS NOT NULL AND visible = TRUE
        ),
        nb_realisations = (
            SELECT COUNT(*)
            FROM historique_recettes
            WHERE recette_id = r.id
        );
    
    -- Mettre à jour la table de stats si elle existe
    TRUNCATE TABLE stats_recettes;
    
    INSERT INTO stats_recettes (recette_id, note_moyenne, nb_evaluations, nb_realisations, derniere_realisation, cout_moyen)
    SELECT 
        r.id,
        r.note_moyenne,
        r.nb_evaluations,
        r.nb_realisations,
        MAX(hr.date_realisation),
        fn_calculer_cout_recette(r.id)
    FROM recettes r
    LEFT JOIN historique_recettes hr ON r.id = hr.recette_id
    GROUP BY r.id;
    
    SELECT 'Statistiques recalculées avec succès' AS message;
END//

-- Procédure : Rapport hebdomadaire
CREATE PROCEDURE sp_rapport_hebdomadaire()
BEGIN
    -- Nouvelles recettes de la semaine
    SELECT 'Nouvelles recettes' AS categorie, COUNT(*) AS nombre
    FROM recettes
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
    
    -- Nouveaux utilisateurs
    SELECT 'Nouveaux utilisateurs' AS categorie, COUNT(*) AS nombre
    FROM utilisateurs
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
    
    -- Recettes les plus réalisées
    SELECT 
        r.titre,
        COUNT(*) AS realisations_semaine
    FROM historique_recettes hr
    INNER JOIN recettes r ON hr.recette_id = r.id
    WHERE hr.date_realisation >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY r.id
    ORDER BY realisations_semaine DESC
    LIMIT 5;
    
    -- Utilisateurs les plus actifs
    SELECT 
        u.nom,
        u.prenom,
        COUNT(*) AS activites
    FROM utilisateurs u
    INNER JOIN historique_recettes hr ON u.id = hr.utilisateur_id
    WHERE hr.date_realisation >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY u.id
    ORDER BY activites DESC
    LIMIT 5;
END//

DELIMITER ;