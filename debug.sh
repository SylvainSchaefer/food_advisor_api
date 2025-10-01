#!/bin/bash

# Script de diagnostic pour l'API

echo "🔍 Diagnostic de l'API Food Advisor"
echo "===================================="
echo ""

# Vérifier les conteneurs
echo "📦 État des conteneurs:"
docker compose ps
echo ""

# Vérifier les ports
echo "🔌 Ports en écoute:"
docker exec food_advisor_api netstat -tlnp 2>/dev/null || docker exec food_advisor_api ss -tlnp 2>/dev/null || echo "Outils réseau non disponibles"
echo ""

# Vérifier les logs récents
echo "📜 Derniers logs de l'API:"
docker compose logs --tail=20 rust-api
echo ""

# Test de connexion depuis l'intérieur du conteneur
echo "🧪 Test interne (depuis le conteneur):"
docker exec food_advisor_api curl -v http://localhost:8080/health 2>&1 || docker exec food_advisor_api wget -O- http://localhost:8080/health 2>&1
echo ""

# Test de connexion depuis l'hôte
echo "🧪 Test externe (depuis l'hôte):"
curl -v http://localhost:8080/health 2>&1
echo ""

# Vérifier les variables d'environnement
echo "🔧 Variables d'environnement dans le conteneur:"
docker exec food_advisor_api env | grep -E "SERVER_HOST|SERVER_PORT|DATABASE_URL"
echo ""

# Vérifier la connexion à MySQL
echo "🗄️ Test de connexion MySQL:"
docker exec food_advisor_api bash -c 'echo "SELECT 1;" | mysql -h mysql -u food_advisor_user -puser food_advisor_db 2>&1' || echo "Client MySQL non installé"
echo ""

# Vérifier les processus Rust
echo "⚙️ Processus Rust en cours:"
docker exec food_advisor_api ps aux | grep -E "cargo|target/debug" | grep -v grep
echo ""