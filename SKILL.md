---
name: ddev-php
description: >
  Use this skill whenever the user wants to create, run, or manage a PHP project using DDEV
  (Docker-based local development environment). Triggers include: any mention of 'ddev', 'DDEV',
  'ddev start', 'ddev config', 'local PHP server', 'PHP development environment', or requests to
  serve/test PHP files locally. Also use when the user asks to set up a PHP project with Composer,
  run PHP scripts in a containerized environment, test a PHP page in a browser, or interact with
  a DDEV-managed MySQL/nginx stack. Covers fresh project initialization AND existing DDEV projects.
  Supports generic PHP as well as auto-detection of Laravel, Symfony, and other common frameworks.
  Always use this skill when DDEV or local PHP development is involved, even if the user doesn't
  explicitly say "DDEV" — if they mention running PHP locally with Docker, this is the skill to use.
---

# DDEV PHP Development Skill

You are an expert in DDEV, the Docker-based local development environment for PHP projects.
This skill enables you to create PHP projects, configure and manage DDEV environments, run
PHP files on the DDEV server, and validate rendered output via browser automation tools.

## Table of Contents

1. [Prerequisites Check](#1-prerequisites-check)
2. [Environment Detection](#2-environment-detection)
3. [Project Initialization](#3-project-initialization)
4. [DDEV Configuration](#4-ddev-configuration)
5. [Running PHP in DDEV](#5-running-php-in-ddev)
6. [Page Testing & Validation](#6-page-testing--validation)
7. [Services & Tools](#7-services--tools)
8. [Framework Detection & Adaptation](#8-framework-detection--adaptation)
9. [Common Commands Reference](#9-common-commands-reference)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Prerequisites Check

**ALWAYS run these checks first before any DDEV operation:**

```bash
# Check DDEV is installed
ddev version

# Check Docker is running
docker info > /dev/null 2>&1 && echo "Docker is running" || echo "Docker is NOT running"
```

If DDEV is not installed, inform the user and point them to https://ddev.readthedocs.io/en/stable/users/install/ddev-installation/

If Docker is not running, tell the user to start Docker Desktop (or their Docker daemon) first.

---

## 2. Environment Detection

**Before doing anything, detect the current state of the project directory.**

### Step 1: Check for existing DDEV configuration

```bash
if [ -f .ddev/config.yaml ]; then
    echo "EXISTING DDEV project detected"
    cat .ddev/config.yaml
else
    echo "No DDEV project found — fresh setup needed"
fi
```

### Step 2: Check if DDEV is already running

```bash
ddev describe 2>/dev/null || echo "DDEV project is not running"
```

### Step 3: Detect project type / framework

Run the detection script at `scripts/detect-framework.sh`, or inline:

```bash
if [ -f "artisan" ] && [ -f "composer.json" ] && grep -q "laravel/framework" composer.json 2>/dev/null; then
    FRAMEWORK="laravel"
elif [ -f "bin/console" ] && [ -f "composer.json" ] && grep -q "symfony/framework-bundle" composer.json 2>/dev/null; then
    FRAMEWORK="symfony"
elif [ -f "wp-config.php" ] || [ -f "wp-login.php" ]; then
    FRAMEWORK="wordpress"
elif [ -f "craft" ] && [ -f "composer.json" ] && grep -q "craftcms/cms" composer.json 2>/dev/null; then
    FRAMEWORK="craftcms"
elif [ -f "composer.json" ]; then
    FRAMEWORK="php-composer"
else
    FRAMEWORK="php-plain"
fi
echo "Detected framework: $FRAMEWORK"
```

### Behavior based on detection

- **Existing DDEV project found**: Read `.ddev/config.yaml`, respect existing settings. Only modify what the user explicitly asks to change. Use `ddev start` if not running.
- **No DDEV project**: Proceed with fresh initialization (Section 3).
- **Framework detected**: Adapt docroot and project-type accordingly (Section 8).

---

## 3. Project Initialization

### Project naming convention

The DDEV project name defaults to the current directory name. This is the correct and expected behavior — **do NOT override it** unless the user explicitly requests a different name.

Example: if the directory is `whatsapp-client`, the project name will be `whatsapp-client` and the URL will be `https://whatsapp-client.ddev.site`.

### Fresh generic PHP project

```bash
ddev config \
  --project-type=php \
  --php-version=8.3 \
  --webserver-type=nginx-fpm \
  --docroot=. \
  --database=mysql:8.0

ddev start
```

### Fresh project with Composer

```bash
ddev config \
  --project-type=php \
  --php-version=8.3 \
  --webserver-type=nginx-fpm \
  --docroot=. \
  --database=mysql:8.0

ddev start

# Initialize Composer inside the container
ddev composer init --no-interaction --name="project/$(basename "$PWD")"
```

### Important: HTTPS

DDEV automatically provides HTTPS via mkcert. The site URL will always be `https://<project-name>.ddev.site`. No manual SSL setup is needed.

---

## 4. DDEV Configuration

### Default configuration values

| Setting          | Default Value   | Notes                                    |
|------------------|-----------------|------------------------------------------|
| php_version      | 8.3             | Change with `--php-version`              |
| webserver_type   | nginx-fpm       | Change with `--webserver-type`           |
| database         | mysql:8.0       | Change with `--database`                 |
| docroot          | . (project root)| Adjust per framework                     |
| nodejs_version   | 22              | Set via `ddev config --nodejs-version`   |

### Modifying configuration on an existing project

```bash
# Change PHP version
ddev config --php-version=8.4

# Change Node.js version
ddev config --nodejs-version=22

# Change database
ddev config --database=mysql:8.4

# Apply changes — always restart after config changes
ddev restart
```

### Custom PHP settings

Create `.ddev/php/custom.ini` for PHP overrides:

```ini
memory_limit = 512M
max_execution_time = 300
display_errors = On
error_reporting = E_ALL
```

Then `ddev restart` to apply.

### Custom nginx configuration

If needed, override nginx config by placing a file at `.ddev/nginx_full/nginx-site.conf`. Copy the default first:

```bash
ddev exec cat /etc/nginx/sites-enabled/*.conf > .ddev/nginx_full/nginx-site.conf
# Edit as needed, then:
ddev restart
```

---

## 5. Running PHP in DDEV

### Execute a PHP file (CLI)

```bash
# Run a PHP script inside the DDEV web container
ddev php my-script.php

# Run with arguments
ddev php my-script.php --arg1 value1

# Run arbitrary inline PHP
ddev exec php -r "echo PHP_VERSION;"
```

### Serve and access PHP pages via the browser

Once DDEV is running, PHP files in the docroot are automatically served by nginx:

- `./index.php` → `https://<project-name>.ddev.site/`
- `./api/test.php` → `https://<project-name>.ddev.site/api/test.php`
- `./pages/about.php` → `https://<project-name>.ddev.site/pages/about.php`

```bash
# Get the primary project URL
DDEV_URL=$(ddev describe -j | grep -o '"primary_url":"[^"]*"' | cut -d'"' -f4)
echo "$DDEV_URL"

# Simpler fallback:
echo "https://$(basename "$PWD").ddev.site"
```

### Create and verify a test page

```bash
cat > index.php << 'PHEOF'
<?php
echo "<h1>Hello from DDEV!</h1>";
echo "<p>PHP Version: " . PHP_VERSION . "</p>";
echo "<p>Server: " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
PHEOF

# Verify it's accessible
curl -sk "https://$(basename "$PWD").ddev.site/" | head -20
```

### Run commands inside the web container

```bash
# SSH into the container interactively
ddev ssh

# Execute a single command
ddev exec <command>

# Examples:
ddev exec ls -la /var/www/html
ddev exec php -v
ddev exec whoami
```

---

## 6. Page Testing & Validation

This section describes how to fully validate PHP pages rendered by DDEV using browser
automation. Use **Puppeteer MCP**, **Chrome MCP**, or equivalent browser tools.

### 6.1 Determining the page URL

```bash
# Base URL pattern:
#   https://<directory-name>.ddev.site/<path-to-file>.php
#
# Example: directory "my-app", file "pages/dashboard.php"
#   → https://my-app.ddev.site/pages/dashboard.php

PROJECT_URL="https://$(basename "$PWD").ddev.site"
```

### 6.2 Pre-flight: ensure DDEV is up and serving

```bash
# Start if not running
ddev describe > /dev/null 2>&1 || ddev start

# Verify HTTP response
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "$PROJECT_URL/")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Server responding (HTTP $HTTP_CODE)"
else
    echo "✗ Unexpected response: HTTP $HTTP_CODE"
    ddev logs --tail=20
fi
```

### 6.3 Check for PHP errors in response body

```bash
RESPONSE=$(curl -sk "$PROJECT_URL/target-page.php")

# Check for PHP error patterns
echo "$RESPONSE" | grep -ciE "(Fatal error|Warning|Notice|Parse error|Deprecated|Uncaught)" > /dev/null
if [ $? -eq 0 ]; then
    echo "⚠ PHP errors detected in output:"
    echo "$RESPONSE" | grep -iE "(Fatal error|Warning|Notice|Parse error|Deprecated|Uncaught)"
else
    echo "✓ No PHP errors in output"
fi
```

### 6.4 Full browser validation (Puppeteer / Chrome MCP)

When browser automation tools are available, perform **full validation**:

**Step-by-step workflow:**

1. **Navigate** to `https://<project-name>.ddev.site/<page>.php`
2. **Wait** for page load (`networkidle` or `domcontentloaded`)
3. **Screenshot** the rendered page
4. **Check `document.title`** — verify it matches expectations
5. **Query DOM elements** — assert expected elements exist:
   - `document.querySelector('h1')` for headings
   - `document.querySelectorAll('table tr')` for table rows
   - Any user-specified selectors
6. **Check text content** of key elements
7. **Listen for console errors** — capture `console.error` events
8. **Check for PHP error strings** visible in the rendered DOM:
   - Search page text for "Fatal error", "Warning", "Notice", "Parse error"
9. **Verify assets load** — images, CSS, JS return 200
10. **Report results** to the user with screenshot + findings

**SSL/TLS note:** DDEV uses mkcert self-signed certificates. Configure the browser tool to:
- Puppeteer: launch with `ignoreHTTPSErrors: true`
- Chrome flags: `--ignore-certificate-errors`

### 6.5 Server-side log inspection

Always check server logs alongside browser output:

```bash
# Recent web server logs
ddev logs --tail=50

# Filter for errors only
ddev logs --tail=100 2>&1 | grep -iE "(error|fatal|warning|exception)"

# PHP-FPM specific logs
ddev exec tail -50 /var/log/php-fpm.log 2>/dev/null || echo "No PHP-FPM log found"
```

### 6.6 Validation summary template

After testing, report to the user in this format:

```
## Page Test Results: <page-name>.php

- **URL**: https://<project>.ddev.site/<page>.php
- **HTTP Status**: 200 OK
- **PHP Errors**: None detected
- **Console Errors**: None
- **Screenshot**: [attached/displayed]
- **DOM Checks**:
  - ✓ <h1> element found with text "..."
  - ✓ Form with id "..." present
  - ✗ Missing expected element: ...
- **Server Logs**: No errors in last 50 lines
```

---

## 7. Services & Tools

### 7.1 Composer

```bash
ddev composer install
ddev composer require vendor/package
ddev composer update
ddev composer dump-autoload
ddev composer --version
```

### 7.2 Node.js & npm

```bash
# Set Node.js version
ddev config --nodejs-version=22
ddev restart

# npm commands
ddev npm install
ddev npm run build
ddev npm run dev

# npx
ddev npx tailwindcss init

# Verify versions
ddev exec node --version
ddev exec npm --version
```

### 7.3 MySQL Database

```bash
# MySQL CLI
ddev mysql

# Run queries
ddev mysql -e "SHOW DATABASES;"
ddev mysql -e "CREATE DATABASE myapp;"

# Import / Export
ddev import-db --file=dump.sql
ddev import-db --file=dump.sql.gz
ddev export-db --file=backup.sql.gz

# Snapshots (fast backup/restore)
ddev snapshot --name=before-migration
ddev snapshot restore --latest

# Connection details (from inside container):
#   Host:     db
#   Port:     3306
#   User:     db
#   Password: db
#   Database: db
```

**PHP connection example:**
```php
<?php
$pdo = new PDO(
    'mysql:host=db;port=3306;dbname=db;charset=utf8mb4',
    'db',
    'db',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);
```

### 7.4 Mailpit (Email Testing)

Mailpit is built into DDEV — all PHP `mail()` calls and SMTP to `localhost:1025` are captured.

```bash
# Open Mailpit web UI
ddev launch -m

# Mailpit URL (typically):
#   https://<project-name>.ddev.site:8026
```

**PHP email test:**
```php
<?php
mail('test@example.com', 'Test Subject', 'Hello from DDEV!');
echo "Email sent — check Mailpit at port 8026";
```

### 7.5 Xdebug (on-demand)

```bash
ddev xdebug on      # Enable (slower performance)
ddev xdebug off     # Disable (recommended default)
ddev xdebug status  # Check current state
```

---

## 8. Framework Detection & Adaptation

When a framework is detected (Section 2, Step 3), adapt DDEV configuration automatically.

### Laravel

```bash
ddev config \
  --project-type=laravel \
  --php-version=8.3 \
  --webserver-type=nginx-fpm \
  --docroot=public \
  --database=mysql:8.0
ddev start
ddev composer install
ddev exec php artisan key:generate
ddev exec php artisan migrate
```

**New Laravel project from scratch:**
```bash
mkdir my-laravel && cd my-laravel
ddev config --project-type=laravel --php-version=8.3 --docroot=public --database=mysql:8.0
ddev start
ddev composer create-project laravel/laravel tmp && cp -rT tmp . && rm -rf tmp
ddev exec php artisan key:generate
```

### Symfony

```bash
ddev config \
  --project-type=php \
  --php-version=8.3 \
  --webserver-type=nginx-fpm \
  --docroot=public \
  --database=mysql:8.0
ddev start
ddev composer install
ddev exec php bin/console doctrine:migrations:migrate --no-interaction
```

**New Symfony project from scratch:**
```bash
mkdir my-symfony && cd my-symfony
ddev config --project-type=php --php-version=8.3 --docroot=public --database=mysql:8.0
ddev start
ddev composer create-project symfony/skeleton tmp && cp -rT tmp . && rm -rf tmp
```

### WordPress

```bash
ddev config \
  --project-type=wordpress \
  --php-version=8.3 \
  --webserver-type=nginx-fpm \
  --database=mysql:8.0
ddev start
```

### Craft CMS

```bash
ddev config \
  --project-type=craftcms \
  --php-version=8.3 \
  --webserver-type=nginx-fpm \
  --docroot=web \
  --database=mysql:8.0
ddev start
ddev composer install
ddev exec php craft install
```

**New Craft CMS project from scratch:**
```bash
mkdir my-craft && cd my-craft
ddev config --project-type=craftcms --php-version=8.3 --docroot=web --database=mysql:8.0
ddev start
ddev composer create-project craftcms/craft tmp && cp -rT tmp . && rm -rf tmp
ddev exec php craft install
```

**Craft CMS notes:**
- Craft uses `web` as its default docroot
- DDEV has a native `craftcms` project type — always use it
- The `craft` CLI executable lives in the project root
- Database connection is auto-configured by DDEV (via `CRAFT_DB_*` env vars)
- After install, the control panel is at `https://<project>.ddev.site/admin`
- For Craft 5, ensure PHP 8.2+ (8.3 recommended)

### Generic PHP (no framework)

```bash
ddev config \
  --project-type=php \
  --php-version=8.3 \
  --webserver-type=nginx-fpm \
  --docroot=. \
  --database=mysql:8.0
ddev start
```

### Key differences by framework

| Framework | project-type | docroot   | Post-install steps                      |
|-----------|-------------|-----------|------------------------------------------|
| Laravel   | laravel     | public    | `artisan key:generate`, `artisan migrate`|
| Symfony   | php         | public    | `bin/console` commands                   |
| WordPress | wordpress   | . or web  | WP admin setup wizard                    |
| Craft CMS | craftcms   | web       | `php craft install`, admin at `/admin`   |
| Plain PHP | php         | .         | None                                     |

---

## 9. Common Commands Reference

### Lifecycle

| Command              | Description                          |
|----------------------|--------------------------------------|
| `ddev start`         | Start the project containers         |
| `ddev stop`          | Stop the project containers          |
| `ddev restart`       | Restart containers (applies config)  |
| `ddev poweroff`      | Stop ALL DDEV projects system-wide   |
| `ddev delete`        | Remove project (keeps files on disk) |

### Information

| Command              | Description                          |
|----------------------|--------------------------------------|
| `ddev describe`      | Show project info, URLs, services    |
| `ddev list`          | List all DDEV projects               |
| `ddev logs`          | View web container logs              |
| `ddev logs -s db`    | View database container logs         |
| `ddev version`       | Show DDEV version info               |

### Execution

| Command                | Description                          |
|------------------------|--------------------------------------|
| `ddev exec <cmd>`     | Run command in web container         |
| `ddev ssh`             | SSH into web container               |
| `ddev php <file>`     | Run a PHP file                       |
| `ddev composer <cmd>` | Run Composer                         |
| `ddev npm <cmd>`      | Run npm                              |
| `ddev mysql`           | Open MySQL CLI                       |

### Utilities

| Command                    | Description                          |
|----------------------------|--------------------------------------|
| `ddev launch`              | Open site in browser                 |
| `ddev launch -m`          | Open Mailpit in browser              |
| `ddev share`               | Create public URL via ngrok          |
| `ddev xdebug on/off`      | Toggle Xdebug                        |
| `ddev import-db --file=X` | Import database dump                 |
| `ddev export-db --file=X` | Export database dump                 |
| `ddev snapshot`            | Create database snapshot             |
| `ddev snapshot restore`    | Restore latest snapshot              |
| `ddev config --show`       | Display current configuration        |

---

## 10. Troubleshooting

Below are the most common issues and their solutions.

### Port conflicts (most common issue)

```bash
# Find what's using ports 80/443
sudo lsof -i :80
sudo lsof -i :443

# Option A: Stop conflicting service
# Option B: Change DDEV router ports
ddev config global --router-http-port=8080 --router-https-port=8443
ddev start
```

### DDEV won't start

```bash
docker info                  # Verify Docker is running
ddev poweroff                # Stop everything cleanly
docker network prune -f      # Clean stale networks
ddev start                   # Try again
```

### PHP file shows source code instead of executing

1. Verify docroot is correct in `.ddev/config.yaml`
2. Ensure file has `.php` extension
3. Run `ddev restart`

### Permission denied errors

```bash
ddev exec chmod -R 775 /var/www/html
ddev exec chown -R www-data:www-data /var/www/html
```

### Can't connect to database from PHP

Use `db` as the hostname (not `localhost` or `127.0.0.1`):

```php
$host = 'db';
$port = 3306;
$user = 'db';
$pass = 'db';
$name = 'db';
```

### Node.js/npm not found

```bash
ddev config --nodejs-version=22
ddev restart
ddev exec node --version
```

### Container seems stuck or stale

```bash
ddev poweroff
ddev start
# If still stuck:
ddev delete --omit-snapshot
ddev config   # re-run config
ddev start
```
