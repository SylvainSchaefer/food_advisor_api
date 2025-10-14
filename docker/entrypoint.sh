#!/bin/bash
set -e

echo "🔄 Starting Food Advisor API in development mode..."

# Nettoyer le cache au démarrage pour éviter les problèmes
echo "🧹 Cleaning previous build artifacts..."
rm -rf /app/target/debug/food_advisor /app/target/debug/deps/food_advisor*

echo "🚀 Starting cargo-watch with polling mode..."

# Forcer une compilation complète au démarrage
cargo build

# Ensuite lancer cargo watch
exec cargo watch --poll --delay 1 -x run -w src