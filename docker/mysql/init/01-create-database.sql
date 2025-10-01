-- Créer la base de données si elle n'existe pas
CREATE DATABASE IF NOT EXISTS food_advisor_db 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE food_advisor_db;

-- Créer l'utilisateur application avec privilèges limités
CREATE USER IF NOT EXISTS 'food_advisor_user'@'%' IDENTIFIED BY 'user';

-- Accorder les privilèges CRUD à l'utilisateur application
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE 
    ON food_advisor_db.* 
    TO 'food_advisor_user'@'%';

-- Créer l'utilisateur admin avec tous les privilèges
CREATE USER IF NOT EXISTS 'food_advisor_admin'@'%' IDENTIFIED BY 'admin';

-- Accorder tous les privilèges à l'admin
GRANT ALL PRIVILEGES 
    ON food_advisor_db.* 
    TO 'food_advisor_admin'@'%';

FLUSH PRIVILEGES;