#!/bin/bash
set -e

# Parse inputs
ESTELA_USERNAME="$1"
ESTELA_PASSWORD="$2"
PROJECT_ID="$3"
ESTELA_HOST="$4"
COMMAND="$5"
ENVIRONMENT="$6"
REQUIREMENTS_FILE="$7"
SCRAPY_CFG="$8"

# Set defaults
ESTELA_HOST="${ESTELA_HOST:-https://api.estela.io}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Validate required inputs
if [ -z "$ESTELA_USERNAME" ] || [ -z "$ESTELA_PASSWORD" ]; then
    echo_error "Username and password are required"
    exit 1
fi

# Configure Estela CLI
echo_info "Configuring Estela CLI..."
export ESTELA_API_HOST="$ESTELA_HOST"

# Login to Estela
echo_info "Authenticating with Estela..."
estela login --username "$ESTELA_USERNAME" --password "$ESTELA_PASSWORD" --host "$ESTELA_HOST"

if [ $? -ne 0 ]; then
    echo_error "Authentication failed"
    exit 1
fi

echo_info "Authentication successful"

# Execute command based on input
case "$COMMAND" in
    "deploy")
        echo_info "Starting deployment..."
        
        # Check if we're in a Scrapy project
        if [ ! -f "$SCRAPY_CFG" ]; then
            echo_error "scrapy.cfg not found. Are you in a Scrapy project directory?"
            exit 1
        fi
        
        # Check if project ID is provided
        if [ -z "$PROJECT_ID" ]; then
            echo_error "Project ID is required for deployment"
            exit 1
        fi
        
        # Deploy the project
        echo_info "Deploying project $PROJECT_ID..."
        
        DEPLOY_CMD="estela deploy $PROJECT_ID"
        
        # Add environment variables if provided
        if [ -n "$ENVIRONMENT" ]; then
            echo_info "Setting environment variables..."
            DEPLOY_CMD="$DEPLOY_CMD --env '$ENVIRONMENT'"
        fi
        
        # Execute deployment
        eval $DEPLOY_CMD
        
        if [ $? -eq 0 ]; then
            echo_info "Deployment successful!"
            
            # Set outputs
            echo "deployment-id=$(estela deployments list $PROJECT_ID --limit 1 | jq -r '.[0].id')" >> $GITHUB_OUTPUT
            echo "deployment-url=$ESTELA_HOST/projects/$PROJECT_ID/deployments" >> $GITHUB_OUTPUT
            echo "status=success" >> $GITHUB_OUTPUT
        else
            echo_error "Deployment failed"
            echo "status=failed" >> $GITHUB_OUTPUT
            exit 1
        fi
        ;;
        
    "projects list")
        echo_info "Listing projects..."
        estela projects list
        ;;
        
    "projects create")
        echo_info "Creating new project..."
        if [ -z "$PROJECT_NAME" ]; then
            echo_error "Project name is required"
            exit 1
        fi
        PROJECT_OUTPUT=$(estela projects create --name "$PROJECT_NAME")
        echo "$PROJECT_OUTPUT"
        
        # Extract project ID from output
        PROJECT_ID=$(echo "$PROJECT_OUTPUT" | grep -oP 'Project ID: \K[^\s]+')
        echo "project-id=$PROJECT_ID" >> $GITHUB_OUTPUT
        ;;
        
    "spiders list")
        if [ -z "$PROJECT_ID" ]; then
            echo_error "Project ID is required"
            exit 1
        fi
        echo_info "Listing spiders for project $PROJECT_ID..."
        estela spiders list $PROJECT_ID
        ;;
        
    "spiders run")
        if [ -z "$PROJECT_ID" ] || [ -z "$SPIDER_NAME" ]; then
            echo_error "Project ID and Spider name are required"
            exit 1
        fi
        echo_info "Running spider $SPIDER_NAME..."
        estela spiders run $PROJECT_ID $SPIDER_NAME
        ;;
        
    "jobs list")
        if [ -z "$PROJECT_ID" ]; then
            echo_error "Project ID is required"
            exit 1
        fi
        echo_info "Listing jobs for project $PROJECT_ID..."
        estela jobs list $PROJECT_ID
        ;;
        
    *)
        # Execute custom command
        echo_info "Executing custom command: $COMMAND"
        eval "estela $COMMAND"
        ;;
esac

echo_info "Action completed successfully"
