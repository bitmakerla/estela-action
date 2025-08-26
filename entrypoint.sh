#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

USERNAME="${INPUT_USERNAME}"
PASSWORD="${INPUT_PASSWORD}"
PROJECT_ID="${INPUT_PROJECT}"
HOST="${INPUT_HOST:-https://api.cloud.bitmaker.dev}"

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$PROJECT_ID" ]; then
    log_error "Faltan credenciales. Necesitas username, password y project-id"
    exit 1
fi

echo "DEBUG: Valores capturados:"
echo "- USERNAME: ${USERNAME:+[configurado]}"
echo "- PASSWORD: ${PASSWORD:+[configurado]}"
echo "- PROJECT_ID: $PROJECT_ID"
echo "- HOST: $HOST"
echo "---"

# Verificar que estamos en un proyecto Scrapy
if [ ! -f "scrapy.cfg" ]; then
    log_error "No se encontró scrapy.cfg. ¿Estás en un proyecto Scrapy?"
    log_error "Asegúrate de hacer checkout del código primero"
    exit 1
fi

echo "========================================="
echo "   Bitmaker Cloud Deploy Action"
echo "========================================="
echo ""

# Paso 1: Login
log_success "Conectando a Bitmaker Cloud..."
echo "$PASSWORD" | estela login \
    --username "$USERNAME" \
    --password "$PASSWORD" \
    --host "$HOST"

if [ $? -ne 0 ]; then
    log_error "Error al hacer login en Bitmaker Cloud"
    exit 1
fi
log_success "Login exitoso"

# Paso 2: Inicializar proyecto
log_success "Inicializando proyecto $PROJECT_ID..."
estela init "$PROJECT_ID"

if [ $? -ne 0 ]; then
    log_error "Error al inicializar el proyecto"
    exit 1
fi
log_success "Proyecto inicializado"

# Paso 3: Deploy
log_success "Iniciando deploy..."
estela deploy

if [ $? -ne 0 ]; then
    log_error "Error durante el deploy"
    echo "status=failed" >> $GITHUB_OUTPUT
    exit 1
fi

log_success "¡Deploy completado exitosamente!"
echo "status=success" >> $GITHUB_OUTPUT

echo ""
echo "========================================="
echo "   Deploy finalizado"
echo "========================================="
echo "Proyecto: $PROJECT_ID"
echo "Host: $HOST"
echo "Usuario: $USERNAME"
echo "Estado: SUCCESS"
