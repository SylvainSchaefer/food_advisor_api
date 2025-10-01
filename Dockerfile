# Dockerfile pour le développement avec hot reload
FROM rust:latest

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

# Installer cargo-watch pour le hot reload
RUN cargo install cargo-watch

# Créer le répertoire de l'application
WORKDIR /app

# Copier les fichiers de dépendances
COPY Cargo.toml Cargo.lock ./

# Créer un src dummy pour build les dépendances
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build && \
    rm -rf src

# Les sources seront montées via volume dans docker-compose
# COPY src ./src

# Exposer le port
EXPOSE 8080

# La commande sera définie dans docker-compose.yml
CMD ["cargo", "watch", "-x", "run", "-w", "src"]