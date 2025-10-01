# Makefile pour faciliter l'utilisation de Docker

.PHONY: help build up down restart logs shell db-shell clean rebuild dev

# Couleurs pour l'affichage
GREEN=\033[0;32m
YELLOW=\033[0;33m
RED=\033[0;31m
NC=\033[0m

help: ## Afficher cette aide
	@echo "$(GREEN)Commandes disponibles:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

build: ## Construire les images Docker
	@echo "$(GREEN)Construction des images Docker...$(NC)"
	docker compose build --no-cache

up: ## Démarrer les conteneurs
	@echo "$(GREEN)Démarrage des conteneurs...$(NC)"
	docker compose up -d
	@echo "$(GREEN)✓ API disponible sur http://localhost:8080$(NC)"
	@echo "$(GREEN)✓ MySQL disponible sur localhost:3306$(NC)"

down: ## Arrêter les conteneurs
	@echo "$(YELLOW)Arrêt des conteneurs...$(NC)"
	docker compose down

restart: down up ## Redémarrer les conteneurs

logs: ## Afficher les logs (tous les services)
	docker compose logs -f

logs-api: ## Afficher les logs de l'API uniquement
	docker compose logs -f rust-api

logs-db: ## Afficher les logs de MySQL uniquement
	docker compose logs -f mysql

shell: ## Ouvrir un shell dans le conteneur API
	docker exec -it food_advisor_api /bin/bash

db-shell: ## Ouvrir un shell MySQL
	docker exec -it food_advisor_mysql mysql -u food_advisor_user -puser food_advisor_db

db-admin: ## Ouvrir un shell MySQL en tant qu'admin
	docker exec -it food_advisor_mysql mysql -u food_advisor_admin -padmin food_advisor_db

clean: ## Nettoyer les conteneurs et volumes
	@echo "$(RED)⚠️  Attention: Cette commande va supprimer tous les conteneurs et volumes!$(NC)"
	@echo "Appuyez sur Ctrl+C pour annuler, ou Entrée pour continuer..."
	@read dummy
	docker compose down -v
	@echo "$(GREEN)✓ Nettoyage terminé$(NC)"

rebuild: clean build up ## Reconstruire complètement (clean + build + up)

dev: ## Mode développement avec logs en temps réel
	@echo "$(GREEN)Démarrage en mode développement...$(NC)"
	docker compose up

test: ## Exécuter les tests dans le conteneur
	docker exec -it food_advisor_api cargo test

fmt: ## Formater le code Rust
	docker exec -it food_advisor_api cargo fmt

clippy: ## Exécuter clippy (linter Rust)
	docker exec -it food_advisor_api cargo clippy -- -D warnings

check: fmt clippy test ## Vérifier le code (format + lint + tests)

status: ## Afficher le statut des conteneurs
	@echo "$(GREEN)Statut des conteneurs:$(NC)"
	@docker-compose ps

init-local: ## Initialiser l'environnement local (copier .env.example)
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)✓ Fichier .env créé$(NC)"; \
		echo "$(YELLOW)⚠️  Pensez à modifier le JWT_SECRET dans .env$(NC)"; \
	else \
		echo "$(YELLOW)Le fichier .env existe déjà$(NC)"; \
	fi