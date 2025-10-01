DELIMITER //

-- =============================================
-- Procédure: Authentification utilisateur
-- =============================================
CREATE PROCEDURE sp_authentifier_utilisateur(
    IN p_email VARCHAR(255),
    IN p_mot_de_passe VARCHAR(255)
)
BEGIN
    SELECT 
        id,
        email,
        nom,
        prenom,
        role,
        actif
    FROM utilisateurs
    WHERE email = p_email 
        AND mot_de_passe = p_mot_de_passe
        AND actif = TRUE;
END//

-- =============================================
-- Procédure: Créer un nouvel utilisateur
-- =============================================
CREATE PROCEDURE sp_creer_utilisateur(
    IN p_email VARCHAR(255),
    IN p_mot_de_passe VARCHAR(255),
    IN p_nom VARCHAR(100),
    IN p_prenom VARCHAR(100),
    IN p_date_naissance DATE,
    IN p_ville VARCHAR(100),
    OUT p_user_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur lors de la création de l utilisateur';
    END;
    
    START TRANSACTION;
    
    INSERT INTO utilisateurs (email, mot_de_passe, nom, prenom, date_naissance, ville)
    VALUES (p_email, p_mot_de_passe, p_nom, p_prenom, p_date_naissance, p_ville);
    
    SET p_user_id = LAST_INSERT_ID();
    
    COMMIT;
END//

-- =============================================
-- Procédure: Recommander des recettes
-- =============================================
CREATE PROCEDURE sp_recommander_recettes(
    IN p_utilisateur_id INT,
    IN p_uniquement_stock BOOLEAN,
    IN p_limite INT,
    IN p_ordre_tri VARCHAR(20) -- 'note', 'cout', 'temps', 'recent'
)
BEGIN
    -- Table temporaire pour stocker les scores
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_recettes_scores (
        recette_id INT,
        score DECIMAL(10,2),
        compatible BOOLEAN DEFAULT TRUE,
        ingredients_disponibles INT DEFAULT 0,
        ingredients_total INT DEFAULT 0,
        derniere_realisation DATE
    );
    
    -- Réinitialiser la table temporaire
    TRUNCATE TABLE temp_recettes_scores;
    
    -- Calculer les scores pour chaque recette
    INSERT INTO temp_recettes_scores (recette_id, ingredients_total)
    SELECT 
        r.id,
        COUNT(DISTINCT ir.ingredient_id)
    FROM recettes r
    INNER JOIN ingredients_recette ir ON r.id = ir.recette_id
    WHERE r.publie = TRUE
    GROUP BY r.id;
    
    -- Marquer les recettes incompatibles (allergies, exclusions)
    UPDATE temp_recettes_scores trs
    SET compatible = FALSE
    WHERE EXISTS (
        SELECT 1 
        FROM ingredients_recette ir
        INNER JOIN preferences_ingredients pi ON ir.ingredient_id = pi.ingredient_id
        WHERE ir.recette_id = trs.recette_id 
            AND pi.utilisateur_id = p_utilisateur_id
            AND pi.type_preference IN ('exclu', 'evite')
    );
    
    -- Marquer les recettes avec allergènes
    UPDATE temp_recettes_scores trs
    SET compatible = FALSE
    WHERE EXISTS (
        SELECT 1 
        FROM ingredients_recette ir
        INNER JOIN ingredients_allergenes ia ON ir.ingredient_id = ia.ingredient_id
        INNER JOIN preferences_alimentaires pa ON ia.allergene_id = pa.allergene_id
        WHERE ir.recette_id = trs.recette_id 
            AND pa.utilisateur_id = p_utilisateur_id
    );
    
    -- Si uniquement avec stock, calculer les ingrédients disponibles
    IF p_uniquement_stock THEN
        UPDATE temp_recettes_scores trs
        SET ingredients_disponibles = (
            SELECT COUNT(DISTINCT ir.ingredient_id)
            FROM ingredients_recette ir
            INNER JOIN stocks_utilisateur su ON ir.ingredient_id = su.ingredient_id
            WHERE ir.recette_id = trs.recette_id 
                AND su.utilisateur_id = p_utilisateur_id
                AND su.quantite >= ir.quantite
                AND (su.date_peremption IS NULL OR su.date_peremption > CURDATE())
        );
        
        -- Filtrer les recettes non réalisables
        UPDATE temp_recettes_scores
        SET compatible = FALSE
        WHERE ingredients_disponibles < ingredients_total;
    END IF;
    
    -- Récupérer la date de dernière réalisation
    UPDATE temp_recettes_scores trs
    SET derniere_realisation = (
        SELECT MAX(hr.date_realisation)
        FROM historique_recettes hr
        WHERE hr.recette_id = trs.recette_id 
            AND hr.utilisateur_id = p_utilisateur_id
    );
    
    -- Calculer le score final
    UPDATE temp_recettes_scores trs
    INNER JOIN recettes r ON trs.recette_id = r.id
    SET trs.score = 
        (r.note_moyenne * 20) +  -- Note sur 100
        (CASE 
            WHEN trs.derniere_realisation IS NULL THEN 50
            WHEN DATEDIFF(CURDATE(), trs.derniere_realisation) > 30 THEN 40
            WHEN DATEDIFF(CURDATE(), trs.derniere_realisation) > 14 THEN 20
            ELSE 0
        END) + -- Bonus si pas récemment réalisé
        (CASE 
            WHEN p_uniquement_stock THEN (trs.ingredients_disponibles / trs.ingredients_total * 30)
            ELSE 0
        END); -- Bonus si ingrédients disponibles
    
    -- Sélectionner les recettes recommandées
    SELECT 
        r.*,
        trs.score,
        trs.ingredients_disponibles,
        trs.ingredients_total,
        trs.derniere_realisation,
        CASE 
            WHEN rf.recette_id IS NOT NULL THEN TRUE 
            ELSE FALSE 
        END AS est_favori
    FROM temp_recettes_scores trs
    INNER JOIN recettes r ON trs.recette_id = r.id
    LEFT JOIN recettes_favoris rf ON r.id = rf.recette_id AND rf.utilisateur_id = p_utilisateur_id
    WHERE trs.compatible = TRUE
    ORDER BY 
        CASE 
            WHEN p_ordre_tri = 'note' THEN r.note_moyenne
            WHEN p_ordre_tri = 'cout' THEN -r.cout_estime
            WHEN p_ordre_tri = 'temps' THEN -r.temps_total
            ELSE trs.score
        END DESC
    LIMIT p_limite;
    
    DROP TEMPORARY TABLE IF EXISTS temp_recettes_scores;
END//

-- =============================================
-- Procédure: Réaliser une recette
-- =============================================
CREATE PROCEDURE sp_realiser_recette(
    IN p_utilisateur_id INT,
    IN p_recette_id INT,
    IN p_note INT,
    IN p_mise_a_jour_stock BOOLEAN,
    IN p_nb_portions INT
)
BEGIN
    DECLARE v_historique_id INT;
    DECLARE v_facteur_portion DECIMAL(5,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur lors de la réalisation de la recette';
    END;
    
    START TRANSACTION;
    
    -- Calculer le facteur de portion
    SELECT p_nb_portions / nb_portions INTO v_facteur_portion
    FROM recettes 
    WHERE id = p_recette_id;
    
    -- Ajouter à l'historique
    INSERT INTO historique_recettes (
        utilisateur_id, 
        recette_id, 
        note, 
        nb_portions_realisees, 
        stock_mis_a_jour
    )
    VALUES (
        p_utilisateur_id, 
        p_recette_id, 
        p_note, 
        p_nb_portions, 
        p_mise_a_jour_stock
    );
    
    SET v_historique_id = LAST_INSERT_ID();
    
    -- Mettre à jour les stocks si demandé
    IF p_mise_a_jour_stock THEN
        UPDATE stocks_utilisateur su
        INNER JOIN ingredients_recette ir ON su.ingredient_id = ir.ingredient_id
        SET su.quantite = GREATEST(0, su.quantite - (ir.quantite * v_facteur_portion))
        WHERE su.utilisateur_id = p_utilisateur_id 
            AND ir.recette_id = p_recette_id;
    END IF;
    
    -- Mettre à jour les statistiques de la recette
    UPDATE recettes
    SET 
        nb_realisations = nb_realisations + 1,
        note_moyenne = (
            SELECT AVG(note)
            FROM historique_recettes
            WHERE recette_id = p_recette_id AND note IS NOT NULL
        ),
        nb_evaluations = (
            SELECT COUNT(*)
            FROM historique_recettes
            WHERE recette_id = p_recette_id AND note IS NOT NULL
        )
    WHERE id = p_recette_id;
    
    COMMIT;
    
    SELECT v_historique_id AS historique_id;
END//

-- =============================================
-- Procédure: Générer liste de courses
-- =============================================
CREATE PROCEDURE sp_generer_liste_courses(
    IN p_utilisateur_id INT,
    IN p_recettes_ids TEXT, -- IDs séparés par des virgules
    IN p_nb_portions_par_recette TEXT, -- Nombres séparés par des virgules
    IN p_nom_liste VARCHAR(100)
)
BEGIN
    DECLARE v_liste_id INT;
    DECLARE v_recette_id INT;
    DECLARE v_nb_portions INT;
    DECLARE v_facteur DECIMAL(5,2);
    DECLARE v_position INT DEFAULT 1;
    DECLARE v_recettes_count INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur lors de la génération de la liste de courses';
    END;
    
    START TRANSACTION;
    
    -- Créer la liste de courses
    INSERT INTO liste_courses (utilisateur_id, nom)
    VALUES (p_utilisateur_id, p_nom_liste);
    
    SET v_liste_id = LAST_INSERT_ID();
    
    -- Table temporaire pour les ingrédients nécessaires
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_ingredients_needed (
        ingredient_id INT,
        quantite_totale DECIMAL(10,2),
        unite_mesure VARCHAR(20),
        recette_id INT
    );
    
    -- Calculer le nombre de recettes
    SET v_recettes_count = (LENGTH(p_recettes_ids) - LENGTH(REPLACE(p_recettes_ids, ',', '')) + 1);
    
    -- Parcourir chaque recette
    WHILE v_position <= v_recettes_count DO
        -- Extraire l'ID de recette et le nombre de portions
        SET v_recette_id = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(p_recettes_ids, ',', v_position), ',', -1) AS UNSIGNED);
        SET v_nb_portions = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(p_nb_portions_par_recette, ',', v_position), ',', -1) AS UNSIGNED);
        
        -- Calculer le facteur de portion
        SELECT v_nb_portions / nb_portions INTO v_facteur
        FROM recettes 
        WHERE id = v_recette_id;
        
        -- Ajouter les ingrédients nécessaires
        INSERT INTO temp_ingredients_needed (ingredient_id, quantite_totale, unite_mesure, recette_id)
        SELECT 
            ir.ingredient_id,
            ir.quantite * v_facteur,
            ir.unite_mesure,
            v_recette_id
        FROM ingredients_recette ir
        WHERE ir.recette_id = v_recette_id AND ir.optionnel = FALSE
        ON DUPLICATE KEY UPDATE 
            quantite_totale = quantite_totale + (ir.quantite * v_facteur);
        
        SET v_position = v_position + 1;
    END WHILE;
    
    -- Soustraire les stocks disponibles et ajouter à la liste
    INSERT INTO liste_courses_ingredients (liste_id, ingredient_id, quantite, unite_mesure, recette_id)
    SELECT 
        v_liste_id,
        tin.ingredient_id,
        GREATEST(0, tin.quantite_totale - COALESCE(
            (SELECT SUM(su.quantite)
             FROM stocks_utilisateur su
             WHERE su.utilisateur_id = p_utilisateur_id 
                AND su.ingredient_id = tin.ingredient_id
                AND (su.date_peremption IS NULL OR su.date_peremption > CURDATE())
            ), 0
        )),
        tin.unite_mesure,
        tin.recette_id
    FROM temp_ingredients_needed tin
    WHERE tin.quantite_totale > COALESCE(
        (SELECT SUM(su.quantite)
         FROM stocks_utilisateur su
         WHERE su.utilisateur_id = p_utilisateur_id 
            AND su.ingredient_id = tin.ingredient_id
            AND (su.date_peremption IS NULL OR su.date_peremption > CURDATE())
        ), 0
    );
    
    DROP TEMPORARY TABLE IF EXISTS temp_ingredients_needed;
    
    COMMIT;
    
    SELECT v_liste_id AS liste_id;
END//

-- =============================================
-- Procédure: Vérifier stocks périmés
-- =============================================
CREATE PROCEDURE sp_verifier_stocks_perimes(
    IN p_utilisateur_id INT,
    IN p_jours_avant_peremption INT
)
BEGIN
    SELECT 
        su.*,
        i.nom AS nom_ingredient,
        DATEDIFF(su.date_peremption, CURDATE()) AS jours_restants
    FROM stocks_utilisateur su
    INNER JOIN ingredients i ON su.ingredient_id = i.id
    WHERE su.utilisateur_id = p_utilisateur_id
        AND su.date_peremption IS NOT NULL
        AND su.date_peremption <= DATE_ADD(CURDATE(), INTERVAL p_jours_avant_peremption DAY)
        AND su.quantite > 0
    ORDER BY su.date_peremption ASC;
END//

-- =============================================
-- Fonction: Calculer le coût d'une recette
-- =============================================
CREATE FUNCTION fn_calculer_cout_recette(p_recette_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_cout_total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(ir.quantite * i.prix_estime / 
        CASE 
            WHEN ir.unite_mesure = 'kg' AND i.unite_mesure = 'g' THEN 1000
            WHEN ir.unite_mesure = 'l' AND i.unite_mesure = 'ml' THEN 1000
            ELSE 1
        END
    ), 0) INTO v_cout_total
    FROM ingredients_recette ir
    INNER JOIN ingredients i ON ir.ingredient_id = i.id
    WHERE ir.recette_id = p_recette_id
        AND i.prix_estime IS NOT NULL
        AND ir.optionnel = FALSE;
    
    RETURN v_cout_total;
END//

-- =============================================
-- Procédure: Rechercher recettes
-- =============================================
CREATE PROCEDURE sp_rechercher_recettes(
    IN p_terme_recherche VARCHAR(255),
    IN p_categorie_ingredient INT,
    IN p_temps_max INT,
    IN p_difficulte VARCHAR(20),
    IN p_note_min DECIMAL(3,2),
    IN p_limite INT,
    IN p_offset INT
)
BEGIN
    SELECT DISTINCT
        r.*,
        COUNT(DISTINCT c.id) AS nb_commentaires,
        MAX(hr.date_realisation) AS derniere_realisation
    FROM recettes r
    LEFT JOIN ingredients_recette ir ON r.id = ir.recette_id
    LEFT JOIN ingredients i ON ir.ingredient_id = i.id
    LEFT JOIN commentaires c ON r.id = c.recette_id AND c.visible = TRUE
    LEFT JOIN historique_recettes hr ON r.id = hr.recette_id
    WHERE r.publie = TRUE
        AND (p_terme_recherche IS NULL OR 
            (MATCH(r.titre, r.description) AGAINST(p_terme_recherche IN NATURAL LANGUAGE MODE)
            OR r.titre LIKE CONCAT('%', p_terme_recherche, '%')))
        AND (p_categorie_ingredient IS NULL OR i.categorie_id = p_categorie_ingredient)
        AND (p_temps_max IS NULL OR r.temps_total <= p_temps_max)
        AND (p_difficulte IS NULL OR r.difficulte = p_difficulte)
        AND (p_note_min IS NULL OR r.note_moyenne >= p_note_min)
    GROUP BY r.id
    ORDER BY r.note_moyenne DESC, r.nb_realisations DESC
    LIMIT p_limite OFFSET p_offset;
END//

-- =============================================
-- Procédure: Statistiques utilisateur
-- =============================================
CREATE PROCEDURE sp_statistiques_utilisateur(
    IN p_utilisateur_id INT
)
BEGIN
    -- Statistiques générales
    SELECT 
        COUNT(DISTINCT hr.recette_id) AS nb_recettes_realisees,
        COUNT(*) AS nb_total_realisations,
        AVG(hr.note) AS note_moyenne_donnee,
        MAX(hr.date_realisation) AS derniere_realisation,
        COUNT(DISTINCT DATE(hr.date_realisation)) AS nb_jours_cuisine
    FROM historique_recettes hr
    WHERE hr.utilisateur_id = p_utilisateur_id;
    
    -- Top 5 recettes préférées
    SELECT 
        r.id,
        r.titre,
        COUNT(*) AS nb_realisations,
        AVG(hr.note) AS note_moyenne
    FROM historique_recettes hr
    INNER JOIN recettes r ON hr.recette_id = r.id
    WHERE hr.utilisateur_id = p_utilisateur_id
    GROUP BY r.id
    ORDER BY AVG(hr.note) DESC, COUNT(*) DESC
    LIMIT 5;
    
    -- Catégories d'ingrédients les plus utilisées
    SELECT 
        ci.nom AS categorie,
        COUNT(DISTINCT i.id) AS nb_ingredients_differents,
        COUNT(*) AS nb_utilisations
    FROM historique_recettes hr
    INNER JOIN ingredients_recette ir ON hr.recette_id = ir.recette_id
    INNER JOIN ingredients i ON ir.ingredient_id = i.id
    INNER JOIN categories_ingredients ci ON i.categorie_id = ci.id
    WHERE hr.utilisateur_id = p_utilisateur_id
    GROUP BY ci.id
    ORDER BY COUNT(*) DESC
    LIMIT 5;
END//

-- =============================================
-- Procédure: Nettoyer les stocks périmés
-- =============================================
CREATE PROCEDURE sp_nettoyer_stocks_perimes()
BEGIN
    DELETE FROM stocks_utilisateur
    WHERE date_peremption < DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        AND quantite = 0;
    
    SELECT ROW_COUNT() AS nb_stocks_supprimes;
END//

-- =============================================
-- Trigger: Mise à jour note moyenne après commentaire
-- =============================================
CREATE TRIGGER trg_update_note_moyenne
AFTER INSERT ON commentaires
FOR EACH ROW
BEGIN
    IF NEW.note IS NOT NULL THEN
        UPDATE recettes
        SET 
            note_moyenne = (
                SELECT AVG(note)
                FROM commentaires
                WHERE recette_id = NEW.recette_id 
                    AND note IS NOT NULL 
                    AND visible = TRUE
            ),
            nb_evaluations = (
                SELECT COUNT(*)
                FROM commentaires
                WHERE recette_id = NEW.recette_id 
                    AND note IS NOT NULL 
                    AND visible = TRUE
            )
        WHERE id = NEW.recette_id;
    END IF;
END//

-- =============================================
-- Trigger: Vérifier cohérence des stocks
-- =============================================
CREATE TRIGGER trg_check_stock_coherence
BEFORE UPDATE ON stocks_utilisateur
FOR EACH ROW
BEGIN
    IF NEW.quantite < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'La quantité en stock ne peut pas être négative';
    END IF;
    
    IF NEW.date_peremption IS NOT NULL AND NEW.date_peremption < CURDATE() THEN
        SET NEW.quantite = 0;
    END IF;
END//

DELIMITER ;