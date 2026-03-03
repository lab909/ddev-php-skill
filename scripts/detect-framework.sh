#!/bin/bash
set -euo pipefail
DIR="${1:-.}"
[ ! -d "$DIR" ] && echo "ERROR: Directory not found" >&2 && exit 1
cd "$DIR"

FRAMEWORK="php-plain"; PROJECT_TYPE="php"; DOCROOT="."; POST_INSTALL=""

if [ -f "artisan" ] && [ -f "composer.json" ] && grep -q '"laravel/framework"' composer.json 2>/dev/null; then
    FRAMEWORK="laravel"; PROJECT_TYPE="laravel"; DOCROOT="public"
    POST_INSTALL="ddev exec php artisan key:generate && ddev exec php artisan migrate"
elif [ -f "bin/console" ] && [ -f "composer.json" ] && grep -q '"symfony/framework-bundle"' composer.json 2>/dev/null; then
    FRAMEWORK="symfony"; PROJECT_TYPE="php"; DOCROOT="public"
    POST_INSTALL="ddev exec php bin/console doctrine:migrations:migrate --no-interaction"
elif [ -f "wp-config.php" ] || [ -f "wp-login.php" ]; then
    FRAMEWORK="wordpress"; PROJECT_TYPE="wordpress"; DOCROOT="."
elif [ -f "craft" ] && [ -f "composer.json" ] && grep -q '"craftcms/cms"' composer.json 2>/dev/null; then
    FRAMEWORK="craftcms"; PROJECT_TYPE="craftcms"; DOCROOT="web"
    POST_INSTALL="ddev exec php craft install"
elif [ -f "web/core/lib/Drupal.php" ] || ([ -f "composer.json" ] && grep -q '"drupal/core"' composer.json 2>/dev/null); then
    FRAMEWORK="drupal"; PROJECT_TYPE="drupal"; DOCROOT="web"
elif [ -f "composer.json" ] && grep -q '"cakephp/cakephp"' composer.json 2>/dev/null; then
    FRAMEWORK="cakephp"; PROJECT_TYPE="php"; DOCROOT="webroot"
elif [ -f "spark" ] && [ -f "composer.json" ] && grep -q '"codeigniter4/framework"' composer.json 2>/dev/null; then
    FRAMEWORK="codeigniter"; PROJECT_TYPE="php"; DOCROOT="public"
elif [ -f "composer.json" ] && grep -q '"slim/slim"' composer.json 2>/dev/null; then
    FRAMEWORK="slim"; PROJECT_TYPE="php"; DOCROOT="public"
elif [ -f "composer.json" ]; then
    FRAMEWORK="php-composer"; PROJECT_TYPE="php"
    for d in public web www htdocs; do [ -d "$d" ] && DOCROOT="$d" && break; done
fi

DDEV_CONFIGURED="false"; DDEV_RUNNING="false"
[ -f ".ddev/config.yaml" ] && DDEV_CONFIGURED="true"
ddev describe > /dev/null 2>&1 && DDEV_RUNNING="true"

printf '{"framework":"%s","project_type":"%s","docroot":"%s","post_install":"%s","ddev_configured":%s,"ddev_running":%s,"directory":"%s","project_name":"%s"}\n' \
  "$FRAMEWORK" "$PROJECT_TYPE" "$DOCROOT" "$POST_INSTALL" "$DDEV_CONFIGURED" "$DDEV_RUNNING" "$(pwd)" "$(basename "$(pwd)")"
