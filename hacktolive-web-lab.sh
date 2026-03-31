#!/bin/bash

set -e

# ==============================
# Branding
# ==============================
clear
echo "========================================="
echo "   HackToLive Academy - Web Lab Setup"
echo "========================================="
echo ""
sleep 1

log() {
    echo -e "\e[32m[+]\e[0m $1"
}

warn() {
    echo -e "\e[33m[!]\e[0m $1"
}

# ==============================
# Detect shell
# ==============================
SHELL_NAME=$(basename "$SHELL")

if [[ "$SHELL_NAME" == "zsh" ]]; then
    RC_FILE="$HOME/.zshrc"
else
    RC_FILE="$HOME/.bashrc"
fi

log "Detected shell: $SHELL_NAME"

# ==============================
# Docker Installation
# ==============================
if ! command -v docker &> /dev/null; then
    log "Docker not found. Installing..."

    sudo apt update -y
    sudo apt install -y docker.io

    sudo systemctl enable docker --now

    sudo usermod -aG docker $USER

    warn "Docker installed. Applying permissions..."
else
    log "Docker already installed"
fi

# Ensure Docker running
if ! systemctl is-active --quiet docker; then
    log "Starting Docker service..."
    sudo systemctl start docker
fi

# ==============================
# Pull Images
# ==============================
log "Downloading Juice Shop..."
sudo docker pull bkimminich/juice-shop > /dev/null

log "Downloading WebGoat..."
sudo docker pull webgoat/webgoat > /dev/null

# ==============================
# IP Detection
# ==============================
IP=$(hostname -I | awk '{print $1}')
log "Detected VM IP: $IP"

# ==============================
# Setup Aliases
# ==============================
log "Setting up lab commands..."

sed -i '/# OWASP LAB ALIASES/,$d' $RC_FILE

cat << 'EOF' >> $RC_FILE

# OWASP LAB ALIASES (HackToLive)

StartJuiceshop() {
    echo "[+] Launching Juice Shop..."
    sudo systemctl start docker

    if docker ps -a --format '{{.Names}}' | grep -q "^juice-shop$"; then
        docker start juice-shop >/dev/null
    else
        docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop >/dev/null
    fi

    IP=$(hostname -I | awk '{print $1}')
    echo "[+] Access Juice Shop: http://$IP:3000"
}

StopJuiceshop() {
    echo "[+] Stopping Juice Shop..."
    docker stop juice-shop >/dev/null 2>&1 || echo "[!] Not running"
}

StartWebgoat() {
    echo "[+] Launching WebGoat..."
    sudo systemctl start docker

    if docker ps -a --format '{{.Names}}' | grep -q "^webgoat$"; then
        docker start webgoat >/dev/null
    else
        docker run -d --name webgoat -p 8080:8080 -p 9090:9090 webgoat/webgoat >/dev/null
    fi

    IP=$(hostname -I | awk '{print $1}')
    echo "[+] Access WebGoat: http://$IP:8080/WebGoat"
}

StopWebgoat() {
    echo "[+] Stopping WebGoat..."
    docker stop webgoat >/dev/null 2>&1 || echo "[!] Not running"
}

EOF

# ==============================
# Apply docker group without logout
# ==============================
newgrp docker <<EONG
echo "[+] Docker permissions applied"
EONG

# ==============================
# Reload shell
# ==============================
log "Reloading shell..."

if [[ "$SHELL_NAME" == "zsh" ]]; then
    source ~/.zshrc
else
    source ~/.bashrc
fi

# ==============================
# Final Output (IMPROVED UX)
# ==============================
echo ""
echo "========================================="
echo "        ✅ SETUP COMPLETE"
echo "========================================="
echo ""

echo "🎯 Your Web Security Lab is Ready!"
echo ""

echo "📌 Available Commands:"
echo ""

echo "▶ StartJuiceshop"
echo "   - Launches OWASP Juice Shop (intentionally vulnerable web app)"
echo "   - Use this to practice real-world web hacking scenarios"
echo "   - Opens at: http://$IP:3000"
echo ""

echo "▶ StopJuiceshop"
echo "   - Stops the Juice Shop lab environment"
echo "   - Use this when you're done practicing"
echo ""

echo "▶ StartWebgoat"
echo "   - Launches OWASP WebGoat (guided training platform)"
echo "   - Includes lessons like SQL Injection, XSS, authentication flaws"
echo "   - Opens at: http://$IP:8080/WebGoat"
echo ""

echo "▶ StopWebgoat"
echo "   - Stops the WebGoat training environment safely"
echo ""

echo "💡 Learning Tip:"
echo "   Juice Shop → Practice hacking"
echo "   WebGoat   → Learn concepts step-by-step"
echo ""

echo "🚀 Start with:"
echo "   StartJuiceshop"
echo "   OR"
echo "   StartWebgoat"
echo ""
