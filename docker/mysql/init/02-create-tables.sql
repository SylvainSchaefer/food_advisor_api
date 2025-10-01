USE food_advisor_db;

-- =============================================
-- Fichier: 01_tables.sql
-- Description: Création des tables pour le système de recettes
-- Base de données: MySQL 8.0+
-- =============================================

-- Supprimer les tables existantes (dans l'ordre inverse des dépendances)
DROP TABLE IF EXISTS liste_courses_ingredients;
DROP TABLE IF EXISTS liste_courses;
DROP TABLE IF EXISTS commentaires;
DROP TABLE IF EXISTS historique_recettes;
DROP TABLE IF EXISTS stocks_utilisateur;
DROP TABLE IF EXISTS etapes_recette;
DROP TABLE IF EXISTS ingredients_recette;
DROP TABLE IF EXISTS recettes_favoris;
DROP TABLE IF EXISTS recettes;
DROP TABLE IF EXISTS preferences_ingredients;
DROP TABLE IF EXISTS preferences_alimentaires;
DROP TABLE IF EXISTS ingredients_allergenes;
DROP TABLE IF EXISTS allergenes;
DROP TABLE IF EXISTS ingredients;
DROP TABLE IF EXISTS categories_ingredients;
DROP TABLE IF EXISTS utilisateurs;
DROP TABLE IF EXISTS regimes_alimentaires;

-- =============================================
-- Table: regimes_alimentaires
-- =============================================
CREATE TABLE regimes_alimentaires (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: utilisateurs
-- =============================================
CREATE TABLE utilisateurs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    date_naissance DATE,
    sexe ENUM('M', 'F', 'Autre') DEFAULT 'Autre',
    ville VARCHAR(100),
    code_postal VARCHAR(10),
    pays VARCHAR(100) DEFAULT 'France',
    role ENUM('utilisateur', 'administrateur') DEFAULT 'utilisateur',
    regime_alimentaire_id INT,
    actif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (regime_alimentaire_id) REFERENCES regimes_alimentaires(id) ON DELETE SET NULL,
    INDEX idx_email (email),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: categories_ingredients
-- =============================================
CREATE TABLE categories_ingredients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    icone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: ingredients
-- =============================================
CREATE TABLE ingredients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(100) UNIQUE NOT NULL,
    categorie_id INT NOT NULL,
    unite_mesure ENUM('g', 'kg', 'ml', 'l', 'piece', 'cuillere_cafe', 'cuillere_soupe', 'tasse', 'pincee') DEFAULT 'g',
    calories_par_100g DECIMAL(6,2),
    proteines_par_100g DECIMAL(5,2),
    glucides_par_100g DECIMAL(5,2),
    lipides_par_100g DECIMAL(5,2),
    fibres_par_100g DECIMAL(5,2),
    prix_estime DECIMAL(6,2),
    duree_conservation_jours INT DEFAULT 7,
    cree_par INT,
    approuve BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (categorie_id) REFERENCES categories_ingredients(id),
    FOREIGN KEY (cree_par) REFERENCES utilisateurs(id) ON DELETE SET NULL,
    INDEX idx_nom (nom),
    INDEX idx_categorie (categorie_id),
    INDEX idx_approuve (approuve)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: allergenes
-- =============================================
CREATE TABLE allergenes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    niveau_risque ENUM('faible', 'moyen', 'eleve') DEFAULT 'moyen',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: ingredients_allergenes
-- =============================================
CREATE TABLE ingredients_allergenes (
    ingredient_id INT NOT NULL,
    allergene_id INT NOT NULL,
    PRIMARY KEY (ingredient_id, allergene_id),
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE,
    FOREIGN KEY (allergene_id) REFERENCES allergenes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: preferences_alimentaires
-- =============================================
CREATE TABLE preferences_alimentaires (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    allergene_id INT,
    type_preference ENUM('allergie', 'intolerance', 'aversion') NOT NULL,
    severite ENUM('legere', 'moderee', 'severe') DEFAULT 'moderee',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (allergene_id) REFERENCES allergenes(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_allergene (utilisateur_id, allergene_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: preferences_ingredients
-- =============================================
CREATE TABLE preferences_ingredients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    type_preference ENUM('exclu', 'evite', 'prefere', 'favori') NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_ingredient (utilisateur_id, ingredient_id),
    INDEX idx_user_pref (utilisateur_id, type_preference)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: recettes
-- =============================================
CREATE TABLE recettes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    titre VARCHAR(200) NOT NULL,
    description TEXT,
    instructions TEXT NOT NULL,
    temps_preparation INT, -- en minutes
    temps_cuisson INT, -- en minutes
    temps_total INT GENERATED ALWAYS AS (temps_preparation + temps_cuisson) STORED,
    nb_portions INT DEFAULT 4,
    difficulte ENUM('facile', 'moyen', 'difficile') DEFAULT 'moyen',
    cout_estime DECIMAL(6,2),
    image_url VARCHAR(500),
    cree_par INT NOT NULL,
    publie BOOLEAN DEFAULT TRUE,
    note_moyenne DECIMAL(3,2) DEFAULT 0,
    nb_evaluations INT DEFAULT 0,
    nb_realisations INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (cree_par) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_titre (titre),
    INDEX idx_cree_par (cree_par),
    INDEX idx_publie (publie),
    INDEX idx_note (note_moyenne),
    INDEX idx_difficulte (difficulte),
    FULLTEXT idx_fulltext (titre, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: recettes_favoris
-- =============================================
CREATE TABLE recettes_favoris (
    utilisateur_id INT NOT NULL,
    recette_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (utilisateur_id, recette_id),
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (recette_id) REFERENCES recettes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: ingredients_recette
-- =============================================
CREATE TABLE ingredients_recette (
    id INT PRIMARY KEY AUTO_INCREMENT,
    recette_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantite DECIMAL(10,2) NOT NULL,
    unite_mesure VARCHAR(20),
    optionnel BOOLEAN DEFAULT FALSE,
    notes VARCHAR(255),
    ordre INT DEFAULT 0,
    FOREIGN KEY (recette_id) REFERENCES recettes(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id),
    INDEX idx_recette (recette_id),
    INDEX idx_ingredient (ingredient_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: etapes_recette
-- =============================================
CREATE TABLE etapes_recette (
    id INT PRIMARY KEY AUTO_INCREMENT,
    recette_id INT NOT NULL,
    numero_etape INT NOT NULL,
    description TEXT NOT NULL,
    duree_minutes INT,
    image_url VARCHAR(500),
    FOREIGN KEY (recette_id) REFERENCES recettes(id) ON DELETE CASCADE,
    UNIQUE KEY unique_recette_etape (recette_id, numero_etape),
    INDEX idx_recette_etape (recette_id, numero_etape)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: stocks_utilisateur
-- =============================================
CREATE TABLE stocks_utilisateur (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantite DECIMAL(10,2) NOT NULL,
    unite_mesure VARCHAR(20),
    date_peremption DATE,
    emplacement VARCHAR(50) DEFAULT 'cuisine',
    notes VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_ingredient_stock (utilisateur_id, ingredient_id, date_peremption),
    INDEX idx_user_stock (utilisateur_id),
    INDEX idx_peremption (date_peremption),
    INDEX idx_ingredient_stock (ingredient_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: historique_recettes
-- =============================================
CREATE TABLE historique_recettes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    recette_id INT NOT NULL,
    date_realisation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note INT CHECK (note >= 1 AND note <= 5),
    temps_reel_minutes INT,
    nb_portions_realisees INT,
    stock_mis_a_jour BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (recette_id) REFERENCES recettes(id) ON DELETE CASCADE,
    INDEX idx_user_history (utilisateur_id, date_realisation DESC),
    INDEX idx_recette_history (recette_id),
    INDEX idx_date_realisation (date_realisation)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: commentaires
-- =============================================
CREATE TABLE commentaires (
    id INT PRIMARY KEY AUTO_INCREMENT,
    recette_id INT NOT NULL,
    utilisateur_id INT NOT NULL,
    historique_id INT,
    commentaire TEXT NOT NULL,
    note INT CHECK (note >= 1 AND note <= 5),
    visible BOOLEAN DEFAULT TRUE,
    modere BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (recette_id) REFERENCES recettes(id) ON DELETE CASCADE,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (historique_id) REFERENCES historique_recettes(id) ON DELETE SET NULL,
    INDEX idx_recette_comments (recette_id, visible),
    INDEX idx_user_comments (utilisateur_id),
    INDEX idx_moderation (modere, visible)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: liste_courses
-- =============================================
CREATE TABLE liste_courses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_id INT NOT NULL,
    nom VARCHAR(100) NOT NULL,
    date_creation DATE NOT NULL DEFAULT (CURRENT_DATE),
    date_courses_prevue DATE,
    statut ENUM('en_cours', 'complete', 'archivee') DEFAULT 'en_cours',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_user_liste (utilisateur_id, statut),
    INDEX idx_date_courses (date_courses_prevue)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Table: liste_courses_ingredients
-- =============================================
CREATE TABLE liste_courses_ingredients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    liste_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantite DECIMAL(10,2) NOT NULL,
    unite_mesure VARCHAR(20),
    recette_id INT,
    achete BOOLEAN DEFAULT FALSE,
    prix_reel DECIMAL(6,2),
    notes VARCHAR(255),
    FOREIGN KEY (liste_id) REFERENCES liste_courses(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id),
    FOREIGN KEY (recette_id) REFERENCES recettes(id) ON DELETE SET NULL,
    INDEX idx_liste (liste_id),
    INDEX idx_achete (achete)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;