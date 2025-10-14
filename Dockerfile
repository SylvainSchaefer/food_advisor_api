# Dockerfile pour le développement avec hot reload
FROM rust:latest

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    default-libmysqlclient-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Installer cargo-watch pour le hot reload
RUN cargo install cargo-watch

# Créer le répertoire de l'application
WORKDIR /app

# Copier les fichiers de dépendances
COPY Cargo.toml Cargo.lock ./

# Pré-compiler les dépendances (optionnel mais recommandé)
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build && \
    rm -rf src target/debug/food_advisor* target/debug/deps/food_advisor*

# Copier et rendre exécutable le script d'entrypoint
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Exposer le port
EXPOSE 8080

# Utiliser le script d'entrypoint
ENTRYPOINT ["/entrypoint.sh"]