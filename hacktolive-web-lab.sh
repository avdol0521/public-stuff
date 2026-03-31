#!/usr/bin/env bash
# ==============================================================================
#   HackToLive Academy — Web Security Lab Setup
#   Installs Docker + OWASP Juice Shop + WebGoat on Kali Linux
#   Supports any username, any shell (bash/zsh), with full failsafe handling
# ==============================================================================

# ── Safety: do NOT use set -e (it kills script on any non-zero exit)
#    We handle every exit code manually for robustness.
set -uo pipefail

# ── Color helpers ──────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log()  { echo -e "${GREEN}[+]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
err()  { echo -e "${RED}[✗]${RESET} $1" >&2; }
info() { echo -e "${CYAN}[i]${RESET} $1"; }
step() { echo -e "\n${BOLD}${CYAN}━━ $1 ━━${RESET}"; }

# ── Must NOT run as root ───────────────────────────────────────────────────────
# Running as root causes $HOME and $USER to resolve incorrectly for the target user
if [[ "$EUID" -eq 0 ]]; then
    err "Do NOT run this script as root (do not use sudo)."
    err "Run it as your regular user: bash hacktolive-web-lab.sh"
    exit 1
fi

# ── Detect real user and home ──────────────────────────────────────────────────
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

if [[ -z "$REAL_HOME" ]]; then
    REAL_HOME="$HOME"
fi

# ── Detect active shell RC file ────────────────────────────────────────────────
# We look at the current $SHELL environment, not the script's interpreter
SHELL_BIN=$(basename "$SHELL")

if [[ "$SHELL_BIN" == "zsh" ]]; then
    RC_FILE="$REAL_HOME/.zshrc"
elif [[ "$SHELL_BIN" == "bash" ]]; then
    RC_FILE="$REAL_HOME/.bashrc"
else
    # Fallback: try zsh first (Kali default), then bash
    if [[ -f "$REAL_HOME/.zshrc" ]]; then
        RC_FILE="$REAL_HOME/.zshrc"
    else
        RC_FILE="$REAL_HOME/.bashrc"
    fi
fi

# ── Branding ───────────────────────────────────────────────────────────────────
clear
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ██╗  ██╗ █████╗  ██████╗██╗  ██╗████████╗ ██████╗ ██╗     ██╗██╗   ██╗███████╗"
echo "  ██║  ██║██╔══██╗██╔════╝██║ ██╔╝╚══██╔══╝██╔═══██╗██║     ██║██║   ██║██╔════╝"
echo "  ███████║███████║██║     █████╔╝    ██║   ██║   ██║██║     ██║██║   ██║█████╗  "
echo "  ██╔══██║██╔══██║██║     ██╔═██╗    ██║   ██║   ██║██║     ██║╚██╗ ██╔╝██╔══╝  "
echo "  ██║  ██║██║  ██║╚██████╗██║  ██╗   ██║   ╚██████╔╝███████╗██║ ╚████╔╝ ███████╗"
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝  ╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═══╝  ╚══════╝"
echo -e "${RESET}"
echo -e "${BOLD}           Web Security Lab Setup — OWASP Juice Shop + WebGoat${RESET}"
echo ""
echo -e "  Installing for user: ${GREEN}${REAL_USER}${RESET}"
echo -e "  Shell RC file:       ${GREEN}${RC_FILE}${RESET}"
echo ""
sleep 2

# ── Pre-flight checks ──────────────────────────────────────────────────────────
step "Pre-flight Checks"

# Check internet connectivity
log "Checking internet connectivity..."
if ! curl -sf --max-time 10 https://google.com > /dev/null 2>&1; then
    if ! wget -q --spider --timeout=10 https://google.com 2>/dev/null; then
        err "No internet connection detected. Please connect to the internet and try again."
        exit 1
    fi
fi
log "Internet connection: OK"

# Check if running on a Debian/Ubuntu-based system
if ! command -v apt-get &> /dev/null; then
    err "This script requires a Debian/Ubuntu-based system (Kali Linux)."
    err "Detected system does not have apt-get."
    exit 1
fi

# Check for systemd
if ! command -v systemctl &> /dev/null; then
    err "systemd is required but not found. Are you running inside an unsupported container?"
    exit 1
fi

# ── RC file setup ──────────────────────────────────────────────────────────────
step "Shell Configuration"

# Create RC file if it doesn't exist
if [[ ! -f "$RC_FILE" ]]; then
    warn "RC file not found at $RC_FILE. Creating it..."
    touch "$RC_FILE"
    chmod 644 "$RC_FILE"
fi
log "Using RC file: $RC_FILE"

# ── Docker Installation ────────────────────────────────────────────────────────
step "Docker Installation"

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')
    log "Docker already installed (version: ${DOCKER_VERSION})"
else
    log "Docker not found. Installing docker.io..."

    # Wait for any existing apt locks to clear (up to 60 seconds)
    LOCK_WAIT=0
    while sudo fuser /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock &>/dev/null 2>&1; do
        if [[ $LOCK_WAIT -ge 60 ]]; then
            err "apt is locked by another process after 60s. Close any package managers and retry."
            exit 1
        fi
        warn "apt is locked by another process. Waiting... (${LOCK_WAIT}s)"
        sleep 5
        LOCK_WAIT=$((LOCK_WAIT + 5))
    done

    log "Updating package list..."
    if ! sudo apt-get update -y 2>&1 | tail -1; then
        err "apt-get update failed. Check your internet connection."
        exit 1
    fi

    log "Installing docker.io..."
    if ! sudo apt-get install -y docker.io; then
        err "Failed to install docker.io. Try running: sudo apt-get install -y docker.io"
        exit 1
    fi

    log "Docker installed successfully."
fi

# ── Docker Service ─────────────────────────────────────────────────────────────
step "Docker Service"

log "Enabling Docker service..."
if ! sudo systemctl enable docker --now 2>/dev/null; then
    warn "Could not enable Docker via systemctl. Trying manual start..."
fi

# Start if not active
if ! sudo systemctl is-active --quiet docker; then
    log "Starting Docker service..."
    if ! sudo systemctl start docker; then
        err "Failed to start Docker service."
        err "Try: sudo systemctl start docker"
        exit 1
    fi
fi

# Verify Docker daemon is responding
log "Verifying Docker daemon is responding..."
DOCKER_WAIT=0
until sudo docker info &>/dev/null 2>&1; do
    if [[ $DOCKER_WAIT -ge 30 ]]; then
        err "Docker daemon did not become ready after 30 seconds."
        exit 1
    fi
    warn "Waiting for Docker daemon... (${DOCKER_WAIT}s)"
    sleep 3
    DOCKER_WAIT=$((DOCKER_WAIT + 3))
done
log "Docker daemon is ready."

# ── Docker Group & Permissions ─────────────────────────────────────────────────
step "Docker Permissions"

# Create docker group if it doesn't exist
if ! getent group docker &>/dev/null; then
    log "Creating docker group..."
    sudo groupadd docker
fi

# Add user to docker group if not already a member
if id -nG "$REAL_USER" 2>/dev/null | grep -qw docker; then
    log "User '$REAL_USER' is already in the docker group."
else
    log "Adding user '$REAL_USER' to docker group..."
    sudo usermod -aG docker "$REAL_USER"
    warn "Docker group permission added. Full effect on next login."
    warn "For this session, the script will use 'sudo docker' where needed."
fi

# Fix Docker socket permissions for the current session
# This lets docker work immediately without logout
sudo chmod 666 /var/run/docker.sock 2>/dev/null && log "Docker socket permissions set for this session." || true

# Fix .docker config dir permissions if it exists
if [[ -d "$REAL_HOME/.docker" ]]; then
    sudo chown -R "$REAL_USER":"$REAL_USER" "$REAL_HOME/.docker" 2>/dev/null || true
    sudo chmod g+rwx "$REAL_HOME/.docker" -R 2>/dev/null || true
fi

# ── Pull Docker Images ─────────────────────────────────────────────────────────
step "Downloading Docker Images"

pull_image() {
    local IMAGE="$1"
    local NAME="$2"
    log "Downloading ${NAME} (this may take a few minutes)..."
    if ! docker pull "$IMAGE"; then
        err "Failed to pull ${NAME}. Check internet connection and try again."
        exit 1
    fi
    log "${NAME} downloaded successfully."
}

pull_image "bkimminich/juice-shop" "OWASP Juice Shop"
pull_image "webgoat/webgoat"       "OWASP WebGoat"

# ── IP Detection ───────────────────────────────────────────────────────────────
step "Network Detection"

# Get the primary non-loopback IP
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
if [[ -z "$IP" ]]; then
    IP="127.0.0.1"
    warn "Could not detect VM IP. Falling back to localhost (127.0.0.1)"
else
    log "Detected VM IP: $IP"
fi

# ── Write Shell Aliases to RC File ────────────────────────────────────────────
step "Installing Lab Commands"

log "Writing lab commands to $RC_FILE..."

# Remove any previous install block cleanly
if grep -q "# OWASP LAB ALIASES" "$RC_FILE" 2>/dev/null; then
    warn "Previous lab commands found. Removing old version first..."
    # Use a temp file for safe in-place edit (compatible with both bash and zsh rc files)
    TMPFILE=$(mktemp)
    sed '/# OWASP LAB ALIASES/,/# END OWASP LAB ALIASES/d' "$RC_FILE" > "$TMPFILE"
    mv "$TMPFILE" "$RC_FILE"
fi

# Append the new alias block
# NOTE: We use 'docker' (not 'sudo docker') here because socket perms are set correctly.
# The StartXxx functions also handle starting docker if it's not running.
cat >> "$RC_FILE" << 'LABEOF'

# OWASP LAB ALIASES (HackToLive Academy)

_lab_ensure_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo "[+] Starting Docker service..."
        sudo systemctl start docker
        # Re-fix socket perms if needed
        sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
        sleep 2
        if ! docker info > /dev/null 2>&1; then
            echo "[✗] Could not start Docker. Try: sudo systemctl start docker"
            return 1
        fi
    fi
}

_lab_get_ip() {
    hostname -I 2>/dev/null | awk '{print $1}'
}

StartJuiceshop() {
    echo ""
    echo "[+] Launching OWASP Juice Shop..."
    _lab_ensure_docker || return 1

    if docker ps --format '{{.Names}}' | grep -q "^juice-shop$"; then
        echo "[i] Juice Shop is already running."
    elif docker ps -a --format '{{.Names}}' | grep -q "^juice-shop$"; then
        echo "[+] Restarting existing Juice Shop container..."
        docker start juice-shop > /dev/null
    else
        echo "[+] Creating new Juice Shop container..."
        docker run -d --name juice-shop \
            --restart unless-stopped \
            -p 3000:3000 \
            bkimminich/juice-shop > /dev/null
    fi

    # Wait for service to be ready
    echo -n "[+] Waiting for Juice Shop to start"
    for i in $(seq 1 20); do
        if curl -sf --max-time 2 http://localhost:3000 > /dev/null 2>&1; then
            break
        fi
        echo -n "."
        sleep 2
    done
    echo ""

    local IP
    IP=$(_lab_get_ip)
    echo ""
    echo "========================================="
    echo "  ✅ Juice Shop is READY!"
    echo "========================================="
    echo "  🌐 Open in browser (inside this VM):"
    echo "     http://localhost:3000"
    echo ""
    echo "  🖥  Accessing from your HOST machine?"
    echo "     http://${IP}:3000"
    echo "========================================="
    echo ""
}

StopJuiceshop() {
    echo "[+] Stopping Juice Shop..."
    if docker ps --format '{{.Names}}' | grep -q "^juice-shop$"; then
        docker stop juice-shop > /dev/null && echo "[+] Juice Shop stopped."
    else
        echo "[!] Juice Shop is not currently running."
    fi
}

StartWebgoat() {
    echo ""
    echo "[+] Launching OWASP WebGoat..."
    _lab_ensure_docker || return 1

    if docker ps --format '{{.Names}}' | grep -q "^webgoat$"; then
        echo "[i] WebGoat is already running."
    elif docker ps -a --format '{{.Names}}' | grep -q "^webgoat$"; then
        echo "[+] Restarting existing WebGoat container..."
        docker start webgoat > /dev/null
    else
        echo "[+] Creating new WebGoat container..."
        docker run -d --name webgoat \
            --restart unless-stopped \
            -p 8080:8080 \
            -p 9090:9090 \
            webgoat/webgoat > /dev/null
    fi

    # Wait for service to be ready (WebGoat takes longer)
    echo -n "[+] Waiting for WebGoat to start (may take ~30 seconds)"
    for i in $(seq 1 25); do
        if curl -sf --max-time 2 http://localhost:8080/WebGoat/ > /dev/null 2>&1; then
            break
        fi
        echo -n "."
        sleep 3
    done
    echo ""

    local IP
    IP=$(_lab_get_ip)
    echo ""
    echo "========================================="
    echo "  ✅ WebGoat is READY!"
    echo "========================================="
    echo "  🌐 Open in browser (inside this VM):"
    echo "     http://localhost:8080/WebGoat"
    echo ""
    echo "  📝 First time? Register a new account"
    echo "     at the login page to get started."
    echo ""
    echo "  🖥  Accessing from your HOST machine?"
    echo "     http://${IP}:8080/WebGoat"
    echo "========================================="
    echo ""
}

StopWebgoat() {
    echo "[+] Stopping WebGoat..."
    if docker ps --format '{{.Names}}' | grep -q "^webgoat$"; then
        docker stop webgoat > /dev/null && echo "[+] WebGoat stopped."
    else
        echo "[!] WebGoat is not currently running."
    fi
}

LabStatus() {
    echo ""
    echo "========================================="
    echo "  HackToLive Lab — Container Status"
    echo "========================================="
    local IP
    IP=$(_lab_get_ip)

    # Juice Shop
    if docker ps --format '{{.Names}}' | grep -q "^juice-shop$" 2>/dev/null; then
        echo "  ✅ Juice Shop  → RUNNING  → http://localhost:3000  (host: http://${IP}:3000)"
    elif docker ps -a --format '{{.Names}}' | grep -q "^juice-shop$" 2>/dev/null; then
        echo "  ⏹  Juice Shop  → STOPPED  (run StartJuiceshop)"
    else
        echo "  ❌ Juice Shop  → NOT INSTALLED"
    fi

    # WebGoat
    if docker ps --format '{{.Names}}' | grep -q "^webgoat$" 2>/dev/null; then
        echo "  ✅ WebGoat     → RUNNING  → http://localhost:8080/WebGoat  (host: http://${IP}:8080/WebGoat)"
    elif docker ps -a --format '{{.Names}}' | grep -q "^webgoat$" 2>/dev/null; then
        echo "  ⏹  WebGoat     → STOPPED  (run StartWebgoat)"
    else
        echo "  ❌ WebGoat     → NOT INSTALLED"
    fi
    echo "========================================="
    echo ""
}

# Case-insensitive aliases — lowercase
alias startjuiceshop='StartJuiceshop'
alias stopjuiceshop='StopJuiceshop'
alias startwebgoat='StartWebgoat'
alias stopwebgoat='StopWebgoat'
alias labstatus='LabStatus'

# Case-insensitive aliases — UPPERCASE
alias STARTJUICESHOP='StartJuiceshop'
alias STOPJUICESHOP='StopJuiceshop'
alias STARTWEBGOAT='StartWebgoat'
alias STOPWEBGOAT='StopWebgoat'
alias LABSTATUS='LabStatus'

# Case-insensitive aliases — common mixed variants
alias Startjuiceshop='StartJuiceshop'
alias Stopjuiceshop='StopJuiceshop'
alias Startwebgoat='StartWebgoat'
alias Stopwebgoat='StopWebgoat'
alias Labstatus='LabStatus'
alias start_juiceshop='StartJuiceshop'
alias stop_juiceshop='StopJuiceshop'
alias start_webgoat='StartWebgoat'
alias stop_webgoat='StopWebgoat'
alias lab_status='LabStatus'

# END OWASP LAB ALIASES
LABEOF

log "Lab commands written to $RC_FILE"

# ── Save Instructions File ─────────────────────────────────────────────────────
step "Saving Instructions File"

INSTRUCTIONS_FILE="$REAL_HOME/HackToLive-Lab-Instructions.txt"

# Also try to save to Desktop if it exists
DESKTOP_DIR="$REAL_HOME/Desktop"

cat > "$INSTRUCTIONS_FILE" << INSTRUCTIONS_EOF
===============================================================

  ██╗  ██╗ █████╗  ██████╗██╗  ██╗████████╗ ██████╗ ██╗     ██╗██╗   ██╗███████╗
  ██║  ██║██╔══██╗██╔════╝██║ ██╔╝╚══██╔══╝██╔═══██╗██║     ██║██║   ██║██╔════╝
  ███████║███████║██║     █████╔╝    ██║   ██║   ██║██║     ██║██║   ██║█████╗
  ██╔══██║██╔══██║██║     ██╔═██╗    ██║   ██║   ██║██║     ██║╚██╗ ██╔╝██╔══╝
  ██║  ██║██║  ██║╚██████╗██║  ██╗   ██║   ╚██████╔╝███████╗██║ ╚████╔╝ ███████╗
  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝  ╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═══╝  ╚══════╝

               Web Security Lab — Instructions & Quick Reference

===============================================================

  🌐  Website  →  https://hacktolive.net/
  💬  Discord  →  https://discord.gg/zyrDWRqgM2
  📘  Facebook →  https://www.facebook.com/hacktolive.academy
  💼  LinkedIn →  https://www.linkedin.com/company/hacktolive/

===============================================================

Setup completed for user: ${REAL_USER}
Lab commands saved to:    ${RC_FILE}

---------------------------------------------------------------
  IMPORTANT — First Time Setup
---------------------------------------------------------------

After running the setup script, you MUST:

  Step 1: Close this terminal completely.
          This is REQUIRED so the new commands become available.
          The commands were saved to your shell profile but
          won't load until you open a fresh terminal.

  Step 2: Open a NEW terminal window.

  Step 3: Type one of the commands below and press Enter.

  Step 4: Wait for the READY message, then open the URL
          shown in your browser.

  Step 5: When you're done with the lab, stop the container
          using the Stop command.

---------------------------------------------------------------
  Available Commands
---------------------------------------------------------------

  StartJuiceshop
      Starts OWASP Juice Shop on port 3000.
      An intentionally vulnerable web app — practice hacking here.

  StopJuiceshop
      Stops Juice Shop when you're done.

  StartWebgoat
      Starts OWASP WebGoat on port 8080.
      Guided lessons: SQL Injection, XSS, broken authentication & more.

  StopWebgoat
      Stops WebGoat when you're done.

  LabStatus
      Shows whether Juice Shop and WebGoat are running or stopped.

---------------------------------------------------------------
  Access URLs (open these in your browser after starting a lab)
---------------------------------------------------------------

  Opening browser INSIDE the Kali VM (recommended):

      Juice Shop  →  http://localhost:3000
      WebGoat     →  http://localhost:8080/WebGoat

  Opening browser on the HOST machine (e.g. Windows):

      Juice Shop  →  http://${IP}:3000
      WebGoat     →  http://${IP}:8080/WebGoat

  Note: The VM IP (${IP}) above may change after a reboot.
  If the host URL stops working, run 'hostname -I' in the
  Kali terminal to find your new IP address.

---------------------------------------------------------------
  Which Lab Should I Use?
---------------------------------------------------------------

  Juice Shop  →  Hands-on hacking. Try to find and exploit
                 vulnerabilities on your own. Great for practice.

  WebGoat     →  Guided learning. Step-by-step lessons with
                 explanations. Perfect for beginners.

  Tip: You can run BOTH at the same time — they use different ports.
       StartJuiceshop && StartWebgoat

---------------------------------------------------------------
  Troubleshooting
---------------------------------------------------------------

  Command not found after opening new terminal?
      Run this manually once:
          source ${RC_FILE}
      Then try the command again.

  Docker not starting?
      Run: sudo systemctl start docker

  URL not loading in browser?
      Make sure you typed StartJuiceshop or StartWebgoat first
      and saw the READY message.
      Check container status with: LabStatus

  Permission denied errors with Docker?
      Run: sudo chmod 666 /var/run/docker.sock
      Then try again (no logout needed).

===============================================================
  Good luck and happy hacking! 🔐

  ── Stay Connected ──────────────────────────────────────────

  🌐  Website  →  https://hacktolive.net/
  💬  Discord  →  https://discord.gg/zyrDWRqgM2
              Join the community — ask questions, share progress

  📘  Facebook →  https://www.facebook.com/hacktolive.academy
  💼  LinkedIn →  https://www.linkedin.com/company/hacktolive/

  — HackToLive Academy
===============================================================
INSTRUCTIONS_EOF

log "Instructions saved to: $INSTRUCTIONS_FILE"

# Copy to Desktop if it exists
if [[ -d "$DESKTOP_DIR" ]]; then
    cp "$INSTRUCTIONS_FILE" "$DESKTOP_DIR/HackToLive-Lab-Instructions.txt" 2>/dev/null
    log "Instructions also saved to: $DESKTOP_DIR/HackToLive-Lab-Instructions.txt"
fi

# ── Final Output ───────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║                  ✅  SETUP COMPLETE!                        ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo ""
echo -e "  ${BOLD}🎯 Your Web Security Lab is ready, ${GREEN}${REAL_USER}${RESET}${BOLD}!${RESET}"
echo ""

# ── Section: Available commands ────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  📌 Commands You Can Now Use${RESET}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${GREEN}StartJuiceshop${RESET}"
echo "     Starts OWASP Juice Shop on port 3000"
echo "     → An intentionally vulnerable web app to practice hacking"
echo ""
echo -e "  ${GREEN}StopJuiceshop${RESET}"
echo "     Stops Juice Shop when you're done"
echo ""
echo -e "  ${GREEN}StartWebgoat${RESET}"
echo "     Starts OWASP WebGoat on port 8080"
echo "     → Guided lessons: SQL Injection, XSS, broken auth & more"
echo ""
echo -e "  ${GREEN}StopWebgoat${RESET}"
echo "     Stops WebGoat when you're done"
echo ""
echo -e "  ${GREEN}LabStatus${RESET}"
echo "     Shows whether Juice Shop and WebGoat are running or stopped"
echo ""

# ── Section: Access URLs ───────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  🌐 Access URLs (after starting a lab)${RESET}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${BOLD}Inside this Kali VM:${RESET}"
echo -e "    Juice Shop  →  ${CYAN}http://localhost:3000${RESET}"
echo -e "    WebGoat     →  ${CYAN}http://localhost:8080/WebGoat${RESET}"
echo ""
echo -e "  ${BOLD}From your HOST machine (Windows):${RESET}"
echo -e "    Juice Shop  →  ${CYAN}http://${IP}:3000${RESET}"
echo -e "    WebGoat     →  ${CYAN}http://${IP}:8080/WebGoat${RESET}"
echo ""
echo -e "  ${YELLOW}⚠  Note:${RESET} The VM IP above may change after a reboot."
echo "     If host URLs stop working, run ${GREEN}LabStatus${RESET} to see the new IP."
echo ""

# ── Section: Step-by-step what to do now ──────────────────────────────────────
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  🚀 What To Do Right Now — Step by Step${RESET}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${BOLD}Step 1:${RESET}  ${RED}Close this terminal completely.${RESET}"
echo "           This is REQUIRED so the new commands become available."
echo "           (The commands were saved to your shell profile,"
echo "            but won't load until you start a fresh terminal.)"
echo ""
echo -e "  ${BOLD}Step 2:${RESET}  Open a new terminal."
echo ""
echo -e "  ${BOLD}Step 3:${RESET}  Type one of the following and press Enter:"
echo ""
echo -e "           ${GREEN}StartJuiceshop${RESET}   ← to start Juice Shop"
echo -e "           ${GREEN}StartWebgoat${RESET}     ← to start WebGoat"
echo ""
echo -e "  ${BOLD}Step 4:${RESET}  Wait for the 'READY' message, then open the URL"
echo "           shown in your browser."
echo ""
echo -e "  ${BOLD}Step 5:${RESET}  When you're done with the lab, type:"
echo -e "           ${GREEN}StopJuiceshop${RESET}  or  ${GREEN}StopWebgoat${RESET}"
echo ""

# ── Section: Tip ───────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  💡 Which Lab Should I Use?${RESET}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${GREEN}Juice Shop${RESET}  →  ${BOLD}Hands-on hacking.${RESET} Try to find & exploit"
echo "               vulnerabilities yourself. Great for practice."
echo ""
echo -e "  ${GREEN}WebGoat${RESET}     →  ${BOLD}Guided learning.${RESET} Follow step-by-step lessons"
echo "               with explanations. Great for beginners."
echo ""
echo -e "  ${YELLOW}Tip:${RESET} You can run BOTH at the same time — they use different ports."
echo ""

# ── Section: Branding footer ───────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${BOLD}Good luck and happy hacking! 🔐${RESET}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${BOLD}  Stay Connected with HackToLive Academy${RESET}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${GREEN}🌐  Website${RESET}   →  https://hacktolive.net/"
echo ""
echo -e "  ${CYAN}💬  Discord${RESET}   →  https://discord.gg/zyrDWRqgM2"
echo "               Join the community — ask questions & share progress"
echo ""
echo -e "  ${BOLD}📘  Facebook${RESET}  →  https://www.facebook.com/hacktolive.academy"
echo -e "  ${BOLD}💼  LinkedIn${RESET}  →  https://www.linkedin.com/company/hacktolive/"
echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""