# Moodle 5.2 Project Instructions

## 📚 Documentation & References
- **Moodle 5.2 Official Release Notes**: https://moodledev.io/general/releases/5.2
- **Moodle 5.2 Repository**: https://github.com/moodle/moodle/tree/MOODLE_502_STABLE
- **Official Docker Setup**: https://github.com/moodlehq/moodle-docker

## 🛠️ Environment

### Server Requirements (Moodle 5.2)
- **PHP**: 8.3.0+ minimum (PHP 8.5.x supported). Only 64-bit versions supported.
- **PHP Extension**: `sodium` is required
- **PHP Settings**: `max_input_vars` must be >= 5000
- **Web Server**: Apache/Nginx (via Docker recommended)

### Database Requirements
- **PostgreSQL**: 16+ (recommended for this project)
- **MySQL**: 8.4+
- **MariaDB**: 10.11.0+
- **Microsoft SQL Server**: 2019+
- **Aurora MySQL**: 8.0+ (MySQL compatibility version)
- **Oracle Database**: ❌ NOT SUPPORTED (since Moodle 5.0)

## ✅ Coding Standards
- Follow [Moodle Coding Style](https://moodledev.io/general/development/policies/codingstyle) (official)
- Defer to [PSR-12](https://www.php-fig.org/psr/psr-12/) and [PSR-1](https://www.php-fig.org/psr/psr-1/) where not specified
- 4-space indentation, **no tabs**
- All PHP files require PHPDoc blocks
- Use short array syntax (`[]`) for new code
- Namespaces **required** for all new classes
- Line length: aim for 132 characters, maximum 180
- Unix line endings (LF only), no trailing whitespace
- Use `moodle-php-lint` for validation
- Strings must be internationalized via `get_string()`

## 🚫 Constraints
- Never modify `vendor/` directory
- Do not edit core Moodle files unless patching a verified bug
- Prefix custom database tables with `local_` or plugin name
- Always use `$CFG->` for configuration access
- File permissions: 0644 for files, 0755 for directories
- Only 64-bit PHP versions supported

## 🧪 Testing
- **PHPUnit**: `php vendor/bin/phpunit`
- **Behat**: `php vendor/bin/behat`
- **PHP lint**: `php vendor/bin/moodle-php-lint`
- **Code checker**: `php vendor/bin/moodle-check`

## 📁 Project File Structure

```
.
├── dev/
│   ├── php_server.Dockerfile    # PHP 8.5.8 + Apache container with Moodle dependencies
│   ├── setup.sh                 # Moodle installation and configuration script
│   ├── .env.example              # Environment variable template
│   └── compose.yaml             # Docker Compose configuration
│
├── docker_data/                  # Persistent volumes (created at runtime)
│   ├── moodledata/              # Moodle uploaded files and sessions
│   ├── postgres/                 # PostgreSQL data directory
│   └── pgadmin/                  # pgAdmin configuration
│
├── apache_configuration/
│   └── moodle_listener.conf     # Apache configuration for Moodle
│
└── moodle/                      # Moodle source code (copied into container)
```

> 📝 **Note**: 
> - Moodle source code must be placed in `./moodle/` before building
> - All persistent data is stored in `docker_data/` on the host machine
> - The `setup.sh` script creates a symlink `/var/www/html/public` -> `/var/www/html/moodle` for Apache compatibility

## 🐳 Docker Configuration

### Docker Compose Services
| Service | Port | Description |
|---------|------|-------------|
| **php_server** | 80 | Apache + PHP 8.5.8 with Moodle |
| **postgres** | 5432 | PostgreSQL 18.4 database |
| **pgadmin** | 8443 | pgAdmin database management UI |
| **redis** | 6379 | Redis 8.8.0 caching layer |
| **redisinsight** | 5540 | RedisInsight management UI |

### Docker Commands
```bash
# Navigate to project directory
cd dev

# Build and start all services
docker compose up -d --build

# View logs
docker compose logs -f

# View Moodle logs only
docker compose logs -f php_server

# View PostgreSQL logs only
docker compose logs -f postgres

# Access Moodle container shell
docker compose exec php_server bash

# Access database shell
docker compose exec postgres psql -U moodleadmin -d moodle

# Stop services
docker compose down

# Stop and remove volumes
docker compose down -v
```

## 🔧 Installation & Setup

### Prerequisites
- Docker and Docker Compose installed
- Moodle source code placed in `./moodle/` directory
- Environment configured via `.env` file (copy from `.env.example`)

### Setup Process
1. **Configure environment**: Copy `.env.example` to `.env` and edit with your values
2. **Place Moodle code**: Ensure Moodle source is in `./moodle/`
3. **Build and run**: Execute `docker compose up -d --build` in the `dev/` directory
4. **Access Moodle**: Open `http://127.0.0.1` in your browser

### Key Configuration Notes
- **GIT_REMOTE_REPO_URL**: Must use raw GitHub URL format (`https://raw.githubusercontent.com/...`) not `/blob/` URL
- **Apache DocumentRoot**: `/var/www/html/moodle/` inside container
- **Symlink**: Setup script creates `/var/www/html/public` -> `/var/www/html/moodle` for compatibility
- **Permissions**: Directory permissions are set during Docker build (in `php_server.Dockerfile`)

## 💡 Project Notes
- This project uses **PostgreSQL 18** (configured in compose.yaml)
- Redis is included for caching/session storage
- pgAdmin available at port 8443 for database management
- RedisInsight available at port 5540 for Redis management
- Moodle CLI installation uses hardcoded defaults in `setup.sh`

---

## 🚀 Project Improvements & Fixes

### Health Checks
- **Moodle**: HTTP check on port 80 (30s interval, 10s timeout, 3 retries, 60s start period)
- **PostgreSQL**: `pg_isready` check (5s interval, 5s timeout, 5 retries)
- **Redis**: `redis-cli ping` check (10s interval, 5s timeout, 3 retries)

### Security
- `.env` in `.gitignore` (never commit credentials)
- Sensitive defaults removed from documentation
- Volume data persisted outside containers for security

### Critical Bug Fixes Applied
- **Apache configuration URL**: Fixed to use `raw.githubusercontent.com` instead of `github.com/blob/` to avoid downloading HTML
- **Path compatibility**: Added symlink `/var/www/html/public` -> `/var/www/html/moodle` to resolve "Failed to open stream" errors
- **Directory permissions**: Moved `chown` commands to Dockerfile for one-time execution during build
- **Setup script**: Fully documented CLI installation parameters

### Development Tools
- **setup.sh**: Automated Moodle installation and configuration
- **compose.yaml**: Docker Compose configuration with all services
- **php_server.Dockerfile**: PHP 8.5.8 + Apache container with all dependencies
- **.env.example**: Environment variable template
