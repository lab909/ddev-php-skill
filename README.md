# DDEV PHP Skill

> Agent Skill for setting up and managing DDEV environments in PHP projects — with framework auto-detection, page validation, and browser testing support.

[![DDEV](https://img.shields.io/badge/DDEV-Local%20Development-blue.svg)](https://ddev.com/)
[![PHP](https://img.shields.io/badge/PHP-8.2%20%7C%208.3%20%7C%208.4-777BB4.svg)](https://www.php.net/)
[![Agent Skill](https://img.shields.io/badge/Agent%20Skill-Compatible-blueviolet.svg)](https://agentskills.io)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Compatibility

This is an **Agent Skill** following the [open standard](https://agentskills.io) originally developed by Anthropic and released for cross-platform use.

**Supported platforms:**

- ✅ Claude Code (Anthropic)
- ✅ Cursor
- ✅ Windsurf
- ✅ GitHub Copilot
- ✅ Other skills-compatible AI agents

> Skills are portable packages of procedural knowledge that work across any AI agent supporting the Agent Skills specification.

## Overview

This skill teaches AI coding agents how to work with [DDEV](https://ddev.com/) — the Docker-based local development environment — to set up, configure, and manage PHP projects. Instead of guessing at commands or producing incorrect configuration, the agent follows a structured workflow: detect the environment, configure DDEV with the right settings, serve PHP files, and validate rendered pages through browser automation.

### What It Does

- ✅ **Environment detection** — Detects existing DDEV configuration and adapts to it
- ✅ **Framework auto-detection** — Identifies Laravel, Symfony, WordPress, Craft CMS, Drupal, CakePHP, CodeIgniter, and Slim
- ✅ **Smart project setup** — Configures docroot, project type, PHP version, and database per framework
- ✅ **Project naming** — Uses the current directory name as DDEV project name (no manual overrides)
- ✅ **Page validation** — Full rendered page testing via HTTP checks, PHP error scanning, and browser automation (Puppeteer / Chrome MCP)
- ✅ **Services** — Composer, Node.js/npm, MySQL, Mailpit (email testing), Xdebug
- ✅ **Troubleshooting** — Common issues with ports, permissions, SSL, database connections, and more

### What It Doesn't Do

- ❌ Install DDEV or Docker (it checks for them and tells the user how to install)
- ❌ Manage production deployments
- ❌ Replace framework-specific skills (use dedicated skills for deep Drupal/TYPO3/WordPress workflows)

## Prerequisites

Before using this skill, ensure you have:

- [DDEV](https://ddev.readthedocs.io/en/stable/users/install/ddev-installation/) installed
- [Docker](https://www.docker.com/get-started) running
- A skills-compatible AI agent (Claude Code, Cursor, Windsurf, GitHub Copilot, etc.)

## Installation

### Claude Code

```bash
# Clone into your skills directory
git clone https://github.com/YOUR_USERNAME/ddev-php-skill.git ~/.claude/skills/ddev-php

# Or copy the folder manually
cp -r ddev-php ~/.claude/skills/ddev-php
```

### Cursor

```bash
git clone https://github.com/YOUR_USERNAME/ddev-php-skill.git .cursor/skills/ddev-php
```

### Windsurf

```bash
git clone https://github.com/YOUR_USERNAME/ddev-php-skill.git .windsurf/skills/ddev-php
```

### From the `.skill` file

Download the latest release and unzip:

```bash
unzip ddev-php.skill -d ~/.claude/skills/
```

## Usage

### Natural language (any agent)

```
Set up DDEV for this PHP project
```

```
Create a new Laravel project with DDEV
```

```
Run my PHP file and check if the page renders correctly
```

```
Test the homepage and tell me if there are any PHP errors
```

### What happens

The skill instructs the agent to:

1. **Check prerequisites** — Verify DDEV and Docker are available
2. **Detect environment** — Check for existing `.ddev/config.yaml` and identify the framework
3. **Configure DDEV** — Apply the right `project-type`, `docroot`, `php-version`, and database
4. **Start the server** — Run `ddev start` and verify the site is accessible
5. **Validate pages** — Test rendered output via HTTP, scan for PHP errors, and (when browser tools are available) take screenshots and run DOM assertions

## Supported Frameworks

The skill auto-detects these frameworks and configures DDEV accordingly:

| Framework    | Detection method                  | project-type | docroot  |
|-------------|-----------------------------------|-------------|----------|
| Laravel      | `artisan` + `laravel/framework`  | laravel     | public   |
| Symfony      | `bin/console` + `symfony/framework-bundle` | php | public   |
| WordPress    | `wp-config.php` or `wp-login.php`| wordpress   | .        |
| Craft CMS    | `craft` + `craftcms/cms`         | craftcms    | web      |
| Drupal       | `web/core/lib/Drupal.php` or `drupal/core` | drupal | web |
| CakePHP      | `cakephp/cakephp`               | php         | webroot  |
| CodeIgniter 4| `spark` + `codeigniter4/framework` | php      | public   |
| Slim         | `slim/slim`                      | php         | public   |
| Generic PHP  | `composer.json` present          | php         | auto     |
| Plain PHP    | No composer.json                 | php         | .        |

## Default Configuration

| Setting        | Default    | Configurable via                   |
|---------------|------------|-------------------------------------|
| PHP version    | 8.3       | `ddev config --php-version=X`      |
| Web server     | nginx-fpm | `ddev config --webserver-type=X`   |
| Database       | MySQL 8.0 | `ddev config --database=X`         |
| Node.js        | 22        | `ddev config --nodejs-version=X`   |

## Page Validation

One of the key features of this skill is **full page validation**. When an agent has access to browser automation tools (Puppeteer MCP, Chrome MCP, etc.), it can:

1. Navigate to the DDEV URL (`https://<project>.ddev.site/page.php`)
2. Wait for page load
3. Take a screenshot of the rendered page
4. Check for PHP errors (Fatal, Warning, Notice, Parse error) in the DOM
5. Listen for JavaScript console errors
6. Run DOM assertions (verify elements exist, check text content)
7. Inspect server-side logs for errors

For environments without browser tools, the skill falls back to `curl`-based validation with HTTP status checks and PHP error pattern matching.

## Project Structure

```
ddev-php/
├── SKILL.md                         # Main skill instructions (loaded by agent)
├── scripts/
│   ├── detect-framework.sh          # Framework detection → JSON output
│   └── validate-page.sh             # CLI page validation (HTTP + errors + logs)
└── references/
    └── troubleshooting.md           # Extended troubleshooting guide
```

### File Details

**`SKILL.md`** — The core skill file read by the AI agent. Contains 10 sections covering the full workflow from prerequisites through troubleshooting. This is what the agent loads into context when the skill triggers.

**`scripts/detect-framework.sh`** — Standalone bash script that analyzes the current directory and outputs JSON with the detected framework, recommended DDEV settings, and current DDEV status. Can be run independently:

```bash
bash scripts/detect-framework.sh /path/to/project
# {"framework":"laravel","project_type":"laravel","docroot":"public",...}
```

**`scripts/validate-page.sh`** — Quick CLI validator that checks whether a PHP page is serving correctly. Tests DDEV status, HTTP response code, PHP errors in output, and server logs:

```bash
bash scripts/validate-page.sh /index.php /path/to/project
```

**`references/troubleshooting.md`** — Extended troubleshooting reference covering installation issues, PHP configuration, database connectivity, networking, performance, and container problems.

## Common Scenarios

### New plain PHP project

```
Create a PHP project with DDEV in this directory
```

The agent will run `ddev config` with the defaults (PHP 8.3, nginx-fpm, MySQL 8.0), start DDEV, and confirm the URL.

### Existing project with framework

```
Set up DDEV for this project
```

The agent detects the framework (e.g., Laravel), configures DDEV with the correct docroot and project type, runs `composer install`, and executes framework-specific post-install steps.

### Test a page

```
Check if my contact form page renders correctly
```

The agent navigates to the page URL, takes a screenshot, checks for PHP errors, and reports back with a validation summary.

### Change PHP version

```
Switch this project to PHP 8.4
```

The agent runs `ddev config --php-version=8.4` and `ddev restart`.

## Contributing

Contributions are welcome! Some ideas:

- Add detection for more frameworks (Yii, FuelPHP, Phalcon, etc.)
- Improve browser validation patterns for specific testing tools
- Add custom DDEV commands (like the TYPO3 skill's `install-v13`)
- Expand troubleshooting scenarios

## Credits

Inspired by:

- [madsnorgaard/ddev-expert](https://lobehub.com/skills/madsnorgaard-agent-resources-ddev-expert) — DDEV expertise skill for Drupal
- [netresearch/typo3-ddev-skill](https://github.com/netresearch/typo3-ddev-skill) — DDEV skill for TYPO3 extension development
- [DDEV documentation](https://ddev.readthedocs.io/) — The official DDEV docs

## License

MIT License — see [LICENSE](LICENSE) for details.
