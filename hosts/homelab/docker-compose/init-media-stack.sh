#!/usr/bin/env bash
set -euo pipefail

# Media Stack Auto-Configuration Script
# Configures connections between Prowlarr, Sonarr, Radarr, and Transmission
# Run once on first boot, creates flag file to skip subsequent runs

CONFIG_PATH="${CONFIG_PATH:-/srv/config}"
FLAG_FILE="${CONFIG_PATH}/.media-stack-initialized"
MAX_RETRIES=30
RETRY_DELAY=10

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
error() { log "ERROR: $*" >&2; }

# Wait for a service to be ready
wait_for_service() {
    local name="$1" url="$2" retries=0
    log "Waiting for $name to be ready..."
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -sf "$url" > /dev/null 2>&1; then
            log "$name is ready"
            return 0
        fi
        retries=$((retries + 1))
        sleep $RETRY_DELAY
    done
    error "$name not ready after $MAX_RETRIES attempts"
    return 1
}

# Extract API key from config.xml
get_api_key() {
    local service="$1"
    local config_file="${CONFIG_PATH}/${service}/config.xml"
    if [ -f "$config_file" ]; then
        grep -oP '(?<=<ApiKey>)[^<]+' "$config_file" || echo ""
    else
        echo ""
    fi
}

# Check if already initialized
if [ -f "$FLAG_FILE" ]; then
    log "Media stack already initialized, skipping..."
    exit 0
fi

log "Starting media stack initialization..."

# Wait for all services
wait_for_service "Sonarr" "http://localhost:8989/api/v3/system/status"
wait_for_service "Radarr" "http://localhost:7878/api/v3/system/status"
wait_for_service "Prowlarr" "http://localhost:9696/api/v1/system/status"
wait_for_service "Transmission" "http://localhost:9091/transmission/web/"

# Get API keys
SONARR_API_KEY=$(get_api_key "sonarr")
RADARR_API_KEY=$(get_api_key "radarr")
PROWLARR_API_KEY=$(get_api_key "prowlarr")

if [ -z "$SONARR_API_KEY" ] || [ -z "$RADARR_API_KEY" ] || [ -z "$PROWLARR_API_KEY" ]; then
    error "Could not extract API keys. Ensure services have started at least once."
    exit 1
fi

log "API keys extracted successfully"

# Configure Sonarr - Add Transmission download client
log "Configuring Sonarr download client..."
curl -sf -X POST "http://localhost:8989/api/v3/downloadclient" \
    -H "X-Api-Key: $SONARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Transmission",
        "implementation": "Transmission",
        "configContract": "TransmissionSettings",
        "enable": true,
        "protocol": "torrent",
        "priority": 1,
        "fields": [
            {"name": "host", "value": "transmission"},
            {"name": "port", "value": 9091},
            {"name": "urlBase", "value": "/transmission/"},
            {"name": "username", "value": ""},
            {"name": "password", "value": ""},
            {"name": "tvCategory", "value": "tv-sonarr"},
            {"name": "tvDirectory", "value": ""},
            {"name": "recentTvPriority", "value": 0},
            {"name": "olderTvPriority", "value": 0},
            {"name": "addPaused", "value": false},
            {"name": "useSsl", "value": false}
        ]
    }' > /dev/null && log "Sonarr: Transmission configured" || log "Sonarr: Transmission may already exist"

# Configure Sonarr - Add root folder
log "Configuring Sonarr root folder..."
curl -sf -X POST "http://localhost:8989/api/v3/rootfolder" \
    -H "X-Api-Key: $SONARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"path": "/tv"}' > /dev/null && log "Sonarr: Root folder /tv configured" || log "Sonarr: Root folder may already exist"

# Configure Radarr - Add Transmission download client
log "Configuring Radarr download client..."
curl -sf -X POST "http://localhost:7878/api/v3/downloadclient" \
    -H "X-Api-Key: $RADARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Transmission",
        "implementation": "Transmission",
        "configContract": "TransmissionSettings",
        "enable": true,
        "protocol": "torrent",
        "priority": 1,
        "fields": [
            {"name": "host", "value": "transmission"},
            {"name": "port", "value": 9091},
            {"name": "urlBase", "value": "/transmission/"},
            {"name": "username", "value": ""},
            {"name": "password", "value": ""},
            {"name": "movieCategory", "value": "movies-radarr"},
            {"name": "movieDirectory", "value": ""},
            {"name": "recentMoviePriority", "value": 0},
            {"name": "olderMoviePriority", "value": 0},
            {"name": "addPaused", "value": false},
            {"name": "useSsl", "value": false}
        ]
    }' > /dev/null && log "Radarr: Transmission configured" || log "Radarr: Transmission may already exist"

# Configure Radarr - Add root folder
log "Configuring Radarr root folder..."
curl -sf -X POST "http://localhost:7878/api/v3/rootfolder" \
    -H "X-Api-Key: $RADARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"path": "/movies"}' > /dev/null && log "Radarr: Root folder /movies configured" || log "Radarr: Root folder may already exist"

# Configure Prowlarr - Add Sonarr as application
log "Configuring Prowlarr -> Sonarr connection..."
curl -sf -X POST "http://localhost:9696/api/v1/applications" \
    -H "X-Api-Key: $PROWLARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Sonarr\",
        \"syncLevel\": \"fullSync\",
        \"implementation\": \"Sonarr\",
        \"configContract\": \"SonarrSettings\",
        \"fields\": [
            {\"name\": \"prowlarrUrl\", \"value\": \"http://prowlarr:9696\"},
            {\"name\": \"baseUrl\", \"value\": \"http://sonarr:8989\"},
            {\"name\": \"apiKey\", \"value\": \"$SONARR_API_KEY\"},
            {\"name\": \"syncCategories\", \"value\": [5000, 5010, 5020, 5030, 5040, 5045, 5050]}
        ]
    }" > /dev/null && log "Prowlarr: Sonarr connection configured" || log "Prowlarr: Sonarr connection may already exist"

# Configure Prowlarr - Add Radarr as application
log "Configuring Prowlarr -> Radarr connection..."
curl -sf -X POST "http://localhost:9696/api/v1/applications" \
    -H "X-Api-Key: $PROWLARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Radarr\",
        \"syncLevel\": \"fullSync\",
        \"implementation\": \"Radarr\",
        \"configContract\": \"RadarrSettings\",
        \"fields\": [
            {\"name\": \"prowlarrUrl\", \"value\": \"http://prowlarr:9696\"},
            {\"name\": \"baseUrl\", \"value\": \"http://radarr:7878\"},
            {\"name\": \"apiKey\", \"value\": \"$RADARR_API_KEY\"},
            {\"name\": \"syncCategories\", \"value\": [2000, 2010, 2020, 2030, 2040, 2045, 2050, 2060]}
        ]
    }" > /dev/null && log "Prowlarr: Radarr connection configured" || log "Prowlarr: Radarr connection may already exist"

# Configure Prowlarr - Add FlareSolverr as indexer proxy
log "Configuring Prowlarr -> FlareSolverr proxy..."
curl -sf -X POST "http://localhost:9696/api/v1/indexerProxy" \
    -H "X-Api-Key: $PROWLARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "FlareSolverr",
        "implementation": "FlareSolverr",
        "configContract": "FlareSolverrSettings",
        "fields": [
            {"name": "host", "value": "http://flaresolverr:8191/"},
            {"name": "requestTimeout", "value": 60}
        ],
        "tags": []
    }' > /dev/null && log "Prowlarr: FlareSolverr proxy configured" || log "Prowlarr: FlareSolverr proxy may already exist"

# Export API keys for Recyclarr
log "Exporting API keys for Recyclarr..."
cat > "${CONFIG_PATH}/recyclarr/secrets.yml" << EOF
sonarr_api_key: $SONARR_API_KEY
radarr_api_key: $RADARR_API_KEY
EOF
chmod 600 "${CONFIG_PATH}/recyclarr/secrets.yml"

# Configure Pi-hole DNS for *.homelab wildcard
log "Configuring Pi-hole DNS for homelab domain..."
DOMAIN="${DOMAIN:-homelab}"
# Get server IP (prefer Tailscale IP if available, fallback to local IP)
if command -v tailscale &> /dev/null && tailscale status &> /dev/null; then
    SERVER_IP=$(tailscale ip -4 2>/dev/null || ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1)
else
    SERVER_IP=$(ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1)
fi

mkdir -p "${CONFIG_PATH}/pihole/dnsmasq"
cat > "${CONFIG_PATH}/pihole/dnsmasq/02-homelab.conf" << EOF
# Wildcard DNS for homelab services
# Routes all *.homelab requests to this server
address=/.${DOMAIN}/${SERVER_IP}
EOF
log "Pi-hole: DNS wildcard *.${DOMAIN} -> ${SERVER_IP}"

# Restart Pi-hole to load new DNS config
log "Restarting Pi-hole to apply DNS config..."
docker restart pihole > /dev/null 2>&1 || log "Pi-hole: restart skipped (may not be running yet)"

# Create initialized flag
touch "$FLAG_FILE"
log "Media stack initialization complete!"
log ""
log "Next steps:"
log "  1. Point your devices to use Pi-hole as DNS (${SERVER_IP})"
log "  2. Add indexers in Prowlarr UI (https://prowlarr.${DOMAIN})"
log "     - Enable FlareSolverr proxy for Cloudflare-protected sites"
log "  3. Run Recyclarr to sync quality profiles:"
log "     docker compose run recyclarr sync"
