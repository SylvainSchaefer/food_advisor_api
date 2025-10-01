#!/bin/bash
# Script pour attendre que MySQL soit prêt

set -e

host="$1"
port="$2"
shift 2
cmd="$@"

until nc -z "$host" "$port"; do
  >&2 echo "MySQL n'est pas encore prêt - attente..."
  sleep 1
done

>&2 echo "MySQL est prêt - exécution de la commande"
exec $cmd