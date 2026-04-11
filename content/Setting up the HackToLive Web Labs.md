---
title: Setting up the HackToLive Web Labs
tags:
  - child
---
# One Liner:
- Copy paste the command below in your terminal in Kali Linux as a **non root** user to automatically setup OWASP JuiceShop & OWASP Webgoat:
```sh
wget -qO setup.sh https://raw.githubusercontent.com/avdol0521/public-stuff/fc562f75701b311bb7f90d50613ba90040f59503/hacktolive-web-lab.sh && sudo chmod +x setup.sh && bash setup.sh
```
- make sure to reopen your terminal after the setup is done (or just source `~/.zshrc`/`~/.bashrc`) to use the aliases :D
# HackToLive Web Security Lab Setup

> A one shot Bash script that sets up a fully working **web application hacking lab** on Kali Linux. No manual Docker configuration needed.

Run it once and you'll have two industry-standard vulnerable web apps ready to practice on, with simple commands to start and stop them anytime.

---
## What It Does

1. **Checks your system** - verifies internet access, confirms you're on a Debian/Ubuntu-based system (Kali), and ensures `systemd` is available.
2. **Installs Docker** - if Docker isn't already installed, it installs `docker.io` via `apt`, starts the service, and adds your user to the `docker` group so you never need `sudo` to run containers.
3. **Downloads the lab apps** - pulls the official Docker images for OWASP Juice Shop and OWASP WebGoat. If they're already installed, it asks if you want to reinstall.
4. **Installs lab commands into your shell** - writes a set of easy-to-use commands (functions + aliases) into your `.bashrc` or `.zshrc` so you can control the labs from any terminal.
5. **Saves an instruction file** - writes a `HackToLive-Lab-Instructions.txt` to your home folder and Desktop for quick reference.

---
## The Labs:
### 🐐 OWASP WebGoat

A guided, lesson-based learning platform. Each section teaches you a vulnerability type step by step with explanations, hints, and interactive exercises. Perfect if you're just starting out and want to understand _why_ something is vulnerable, not just _that_ it is.

- Runs on: `http://localhost:8080/WebGoat`
- Topics: SQL Injection, Cross-Site Scripting (XSS), Broken Access Control, Insecure Deserialization, JWT attacks, and more
- **First time?** You'll need to register a local account at the login page (no real email needed, any username/password works)

### 🧃 OWASP Juice Shop

An intentionally vulnerable web application built to look and feel like a real online shop. There are no instructions, you explore it yourself and try to find and exploit the hidden vulnerabilities. Great for hands-on practice and CTF-style challenges.

- Runs on: `http://localhost:3000`
- Topics: XSS, SQL injection, broken authentication, IDOR, insecure direct object references, and many more

> **Tip:** You can run both labs at the same time, they use different ports and don't interfere with each other.
---
## Requirements

- **Kali Linux** (or any Debian/Ubuntu system with `systemd`)
- Run as a **regular user** - do **not** use `sudo`
- Internet connection (to download Docker images)

---
## How to Run

```bash
wget -qO setup.sh https://raw.githubusercontent.com/avdol0521/public-stuff/fc562f75701b311bb7f90d50613ba90040f59503/hacktolive-web-lab.sh && sudo chmod +x setup.sh && bash setup.sh
```

After setup completes, **close and reopen your terminal** - this is required for the new commands to become available.

---

## Commands Added to Your Shell

After running the script, these commands will be available in any new terminal:

### `StartJuiceshop`

Starts the OWASP Juice Shop container. If Docker isn't running, it starts it automatically. Waits until the app is ready, then shows you the URL to open in your browser.

```
[+] Launching OWASP Juice Shop...
[+] Waiting for Juice Shop to start..........

=========================================
  ✅ Juice Shop is READY!
=========================================
  🌐 Open in browser (inside this VM):
     http://localhost:3000

  🖥  Accessing from your HOST machine?
     http://192.168.x.x:3000
=========================================
```

---

### `StopJuiceshop`

Stops the Juice Shop container. Your progress and any data inside it is preserved, it's just paused, not deleted.

```
[+] Stopping Juice Shop...
[+] Juice Shop stopped.
```

---

### `StartWebgoat`

Starts the OWASP WebGoat container. WebGoat takes a bit longer to boot (~30 seconds), so the command waits and lets you know when it's ready.

```
[+] Launching OWASP WebGoat...
[+] Waiting for WebGoat to start (may take ~30 seconds)..........

=========================================
  ✅ WebGoat is READY!
=========================================
  🌐 Open in browser (inside this VM):
     http://localhost:8080/WebGoat

  📝 First time? Register a new account
     at the login page to get started.

  🖥  Accessing from your HOST machine?
     http://192.168.x.x:8080/WebGoat
=========================================
```

---

### `StopWebgoat`

Stops the WebGoat container. Important: always use this command to stop WebGoat, don't use `docker rm` directly or you'll lose your lesson progress.

```
[+] Stopping WebGoat...
[+] WebGoat stopped.
```

---

### `LabStatus`

Shows whether each lab is currently running, stopped, or not installed. Also shows the current VM IP address so you can access the labs from your host machine (e.g. Windows).

```
=========================================
  HackToLive Lab — Container Status
=========================================
  ✅ Juice Shop  → RUNNING  → http://localhost:3000  (host: http://192.168.x.x:3000)
  ⏹  WebGoat    → STOPPED  (run StartWebgoat)
=========================================
```

> **Note:** All commands are case-insensitive. `startjuiceshop`, `STARTJUICESHOP`, and `start_juiceshop` all work the same way.

---

## Accessing from Your Host Machine (e.g. Windows)

If you're running Kali in a VM and want to open the labs in your Windows browser, use the VM's IP address instead of `localhost`. Run `LabStatus` to see the current IP. The IP may change after a reboot.

|Lab|VM (inside Kali)|Host machine (Windows)|
|---|---|---|
|Juice Shop|`http://localhost:3000`|`http://<VM-IP>:3000`|
|WebGoat|`http://localhost:8080/WebGoat`|`http://<VM-IP>:8080/WebGoat`|

---
## Troubleshooting

**Commands not found after setup?** Close your terminal completely and open a new one. If it still doesn't work, run:

```bash
source ~/.zshrc   # if you use zsh (default on Kali)
source ~/.bashrc  # if you use bash
```

**Docker won't start?**

```bash
sudo systemctl start docker
```

**Permission denied errors with Docker?**

```bash
sudo chmod 666 /var/run/docker.sock
```

**Lab URL not loading in browser?** Make sure you ran `StartJuiceshop` or `StartWebgoat` and saw the READY message. Check container status with `LabStatus`.

---

## Stay Connected

- 🌐 Website → [hacktolive.net](https://hacktolive.net/)
- 💬 Discord → [discord.gg/zyrDWRqgM2](https://discord.gg/zyrDWRqgM2)
- 📘 Facebook Page → [facebook.com/hacktolive.academy](https://www.facebook.com/hacktolive.academy)
- 📘 Facebook Group → [https://www.facebook.com/groups/hacktolive/](https://www.facebook.com/groups/hacktolive/)
- 💼 LinkedIn → [linkedin.com/company/hacktolive](https://www.linkedin.com/company/hacktolive/)

---

_Good luck and happy hacking! 🔐_