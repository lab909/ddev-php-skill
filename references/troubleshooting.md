# DDEV PHP Troubleshooting Guide

See Section 10 of SKILL.md for inline troubleshooting. This file provides additional detail.

## Installation and Startup

DDEV not found: Ensure it is in PATH. Reinstall via Homebrew or see DDEV docs.

Port already in use: Run sudo lsof -i :80. Change ports with ddev config global --router-http-port=8080 --router-https-port=8443.

Docker not running: Start Docker Desktop or sudo systemctl start docker.

DDEV start hangs: ddev poweroff, docker system prune -f, ddev start.

HTTPS/mkcert: mkcert -install, then ddev restart.

## PHP Issues

Source code shown instead of executing: Check docroot, .php extension, ddev restart.

Wrong PHP version: ddev config --php-version=8.3 then ddev restart.

Missing extensions: Add to .ddev/web-build/Dockerfile.

Memory limit: Create .ddev/php/custom.ini with memory_limit = 512M.

## Database Issues

Cannot connect from PHP: Use db as hostname, not localhost.

Access from host: Run ddev describe for connection details.

Reset database: ddev delete --omit-snapshot then ddev start.

## Networking

Site not accessible: Check ddev describe, DNS resolution, /etc/hosts.

SSL with curl: Use -k flag.

## Performance

Slow I/O on macOS: ddev mutagen reset and ddev restart.

Xdebug: ddev xdebug off when not debugging.

## Node.js

Not available: ddev config --nodejs-version=22 then ddev restart.

## Composer

Out of memory: ddev exec COMPOSER_MEMORY_LIMIT=-1 composer install.

## Container Issues

Stale containers: ddev poweroff, docker container prune -f, ddev start.

Disk space: docker system prune -a --volumes.
