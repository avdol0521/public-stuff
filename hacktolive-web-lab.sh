#!/bin/bash

set -e

clear
echo "========================================="
echo "   HackToLive Academy - Web Lab Setup"
echo "========================================="
echo ""

log() {
    echo -e "\e[32m[+]\e[0m $1"
}

warn() {
    echo -e "\e[33m[!]\e[0m $1"
}

# -------------------------------
# Install Docker if needed
# -------------------------------
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."

    sudo apt update -y
    sudo apt install -y docker.io

    sudo systemctl enable docker --now
    sudo usermod -aG docker $USER

    warn "Docker installed. You may need to reopen terminal if permission issues occur."
else
    log "Docker already installed"
fi

# Ensure Docker running
if ! systemctl is-active --quiet docker; then
    log "Starting Docker..."
    sudo systemctl start docker
fi

# -------------------------------
# Pull images
# -------------------------------
log "Pulling Juice Shop..."
sudo docker pull bkimminich/juice-shop > /dev/null

log "Pulling WebGoat..."
sudo docker pull webgoat/webgoat > /dev/null

# -------------------------------
# Create binaries
# -------------------------------
log "Creating lab commands..."

# Juice Shop start
sudo tee /usr/local/bin/start-juiceshop > /dev/null << 'EOF'
#!/bin/bash
sudo systemctl start docker

if docker ps -a --format '{{.Names}}' | grep -q "^juice-shop$"; then
    docker start juice-shop >/dev/null
else
    docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop >/dev/null
fi

echo "[+] Juice Shop running at: http://localhost:3000"
EOF

# Juice Shop stop
sudo tee /usr/local/bin/stop-juiceshop > /dev/null << 'EOF'
#!/bin/bash
docker stop juice-shop >/dev/null 2>&1 || echo "[!] Juice Shop not running"
EOF

# WebGoat start
sudo tee /usr/local/bin/start-webgoat > /dev/null << 'EOF'
#!/bin/bash
sudo systemctl start docker

if docker ps -a --format '{{.Names}}' | grep -q "^webgoat$"; then
    docker start webgoat >/dev/null
else
    docker run -d --name webgoat -p 8080:8080 -p 9090:9090 webgoat/webgoat >/dev/null
fi

echo "[+] WebGoat running at: http://localhost:8080/WebGoat"
EOF

# WebGoat stop
sudo tee /usr/local/bin/stop-webgoat > /dev/null << 'EOF'
#!/bin/bash
docker stop webgoat >/dev/null 2>&1 || echo "[!] WebGoat not running"
EOF

# Make executable
sudo chmod +x /usr/local/bin/start-juiceshop
sudo chmod +x /usr/local/bin/stop-juiceshop
sudo chmod +x /usr/local/bin/start-webgoat
sudo chmod +x /usr/local/bin/stop-webgoat

# -------------------------------
# Finish
# -------------------------------
echo ""
echo "========================================="
echo "        ✅ SETUP COMPLETE"
echo "========================================="
echo ""

echo "🎯 Your Web Security Lab is Ready!"
echo ""

echo "📌 Available Commands:"
echo ""

echo "▶ start-juiceshop"
echo "   - Starts Juice Shop vulnerable app"
echo "   - Practice real-world hacking"
echo "   - Open: http://localhost:3000"
echo ""

echo "▶ stop-juiceshop"
echo "   - Stops Juice Shop"
echo ""

echo "▶ start-webgoat"
echo "   - Starts WebGoat training platform"
echo "   - Learn XSS, SQLi, auth bypass"
echo "   - Open: http://localhost:8080/WebGoat"
echo ""

echo "▶ stop-webgoat"
echo "   - Stops WebGoat"
echo ""

echo "💡 Tip:"
echo "   WebGoat → Learn"
echo "   Juice Shop → Practice"
echo ""
