# Moodle 5.2 Docker Stack

A Docker Compose stack for running **Moodle 5.2** with PostgreSQL 18, Redis 8.8, and pgAdmin.

> ✅ **Updated**: Fixed Apache configuration URL, Moodle path alignment, installation permissions, and resolved critical Docker setup issues.
> 
> ⚠️ **Important Fixes Applied**: Fixed raw GitHub URL for config files, added symlink for path compatibility, moved permissions to Dockerfile.

---

## 🚀 Quick Start

```bash
# 1. Configure environment
# Copy template and edit with your values
cp .env.example .env
# Edit .env with your database credentials

# 2. Place Moodle source code in ./moodle/ directory

# 3. Start all services
docker compose up -d

# 4. Access Moodle
# Open http://127.0.0.1 in your browser
```

---

## 📋 Services

| Service | Default Port | Description |
|---------|--------------|-------------|
| **Moodle** | `127.0.0.1:80` | Main Moodle application (Apache + PHP 8.5.8) |
| **PostgreSQL** | `127.0.0.1:5432` | Database server (v18.4) |
| **pgAdmin** | `127.0.0.1:8443` | Database management UI |
| **Redis** | `127.0.0.1:6379` | Caching layer (v8.8.0) |
| **RedisInsight** | `127.0.0.1:5540` | Redis management UI (v3.6) |

> 📝 **Note**: All services are started via `docker compose up -d` in the `dev/` directory

---

## 🔧 Configuration

### Environment Variables (`.env`)

See `.env.example` for the complete template with all available variables.

> ⚠️ **Important**: The `GIT_REMOTE_REPO_URL` variable must use the raw GitHub URL format: `https://raw.githubusercontent.com/sambarnades/MoPgR` (not the `/blob/` URL) to avoid downloading HTML content instead of configuration files.

> ⚠️ **Security Note**: Never commit `.env` to version control (it's in `.gitignore`). Change all default passwords before production use.

### Apache Configuration

- **`moodle_listener.conf`**: Apache configuration for Moodle, includes rewrite rules and directory settings
- **DocumentRoot**: `/var/www/html/moodle/` (Moodle web root inside container)
- **Symlink Note**: The setup script creates a symlink `/var/www/html/public` → `/var/www/html/moodle` to ensure compatibility with the Apache configuration
- **Note**: The configuration expects Moodle to be accessible at the container's root path

---

### HTTPS Configuration

#### Install Certbot
```bash
apt install python3 python3-dev python3-venv libaugeas-dev gcc
python3 -m venv /opt/certbot/
/opt/certbot/bin/pip install --upgrade pip
/opt/certbot/bin/pip install certbot certbot-apache
ln -s /opt/certbot/bin/certbot /usr/local/bin/certbot
```

##### Proceed the interactive installation
```bash
certbot --apache
```

##### Add a cron job to renew the certificate
```bash
echo "0 0,12 * * * root /opt/certbot/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && sudo certbot renew -q" | sudo tee -a /etc/crontab > /dev/null
```

Read the [certbot documentation](https://certbot.eff.org/instructions?ws=apache&os=pip) for more details.

---

## 📁 Project Structure

```
.
├── dev/
│   ├── php_server.Dockerfile    # PHP 8.5.8 + Apache container with Moodle dependencies
│   ├── setup.sh                 # Moodle installation and configuration script
│   ├── .env.example              # Template for environment variables
│   ├── README.md                 # This documentation
│   └── compose.yaml             # Docker Compose configuration
│
├── docker_data/                  # Persistent volumes (created at runtime)
│   ├── moodledata/              # Moodle uploaded files and sessions
│   ├── postgres/                 # PostgreSQL data directory
│   └── pgadmin/                  # pgAdmin configuration
│
└── apache_configuration/
    └── moodle_listener.conf     # Apache configuration for Moodle
```

> 📝 **Note**: 
> - Moodle source code should be placed in `./moodle/` (copied into container)
> - All persistent data is stored in `docker_data/` on the host machine
> - Apache is configured to serve Moodle from `/var/www/html/moodle/` inside the container
> - A symlink `/var/www/html/public` → `/var/www/html/moodle` ensures compatibility with the Apache configuration

---

## ⚙️ Setup Script Details

The `setup.sh` script performs the following operations:

1. **Creates required directories**:
   - `/data/moodledata` for Moodle file storage (uploaded files, sessions)
   - `/var/log/moodle` for cron logs

2. **Fixes path compatibility**:
   - Creates symlink `/var/www/html/public` → `/var/www/html/moodle` to align with Apache configuration
   - This resolves the "Failed to open stream" error for Moodle library files

3. **Installs Moodle** via CLI:
   - Uses `php /var/www/html/moodle/admin/cli/install.php` with hardcoded default parameters
   - Runs in non-interactive mode with `--non-interactive` and `--agree-license`
   - All parameters are documented in the script

4. **Configures Cron**:
   - Runs `cron.php` every minute via www-data user
   - Runs `adhoc_task.php` every minute with keep-alive
   - Logs all output to `/var/log/moodle/cron.log`

5. **Starts Services**:
   - Launches cron daemon in background
   - Starts Apache in foreground mode

> 💡 **Key Paths**:
> - PHP CLI: `/usr/local/bin/php` (used in cron and Moodle CLI)
> - Moodle CLI: `/var/www/html/moodle/admin/cli/`
> - Cron log: `/var/log/moodle/cron.log`
> - Data directory: `/data/moodledata`

> ⚠️ **Important**: The `chown` command for Moodle directory has been moved to the Dockerfile to execute only once during build, not on every container start.

---

## 🔄 Development Workflow

### Using Docker Compose

```bash
# Build and start all services
docker compose up -d --build

# View logs
docker compose logs -f

# View Moodle logs only
docker compose logs -f php_server

# View PostgreSQL logs only
docker compose logs -f postgres

# Restart services
docker compose restart

# Stop and remove containers
docker compose down

# Stop and remove containers with volumes
docker compose down -v

# Access container shell
docker compose exec php_server bash

# Run Moodle CLI commands
docker compose exec php_server /usr/local/bin/php /var/www/html/moodle/admin/cli/cron.php

# Access database shell
docker compose exec postgres psql -U moodleadmin -d moodle
```

---

## 🛡️ Security

### 🔒 Security Best Practices
- **Never commit `.env`** to version control (it's in `.gitignore`)
- **Change all default passwords** in `.env` before production use
- Use HTTPS in production (add a reverse proxy like Traefik or Caddy)
- Consider using Docker secrets for sensitive data in production

### 🌐 Network Security
- All database ports (PostgreSQL, Redis) are bound to `127.0.0.1` by default
- All services use health checks to ensure proper startup sequencing
- PostgreSQL uses shared memory (`shm_size: 128mb`) for optimal performance

### 📋 Security Configuration
- Database passwords are set to `change_me` by default and must be overridden
- Volume data is persisted outside containers for security
- **Important**: Always use raw GitHub URLs (raw.githubusercontent.com) for configuration files to avoid downloading HTML content

---

## 💾 Backup & Restore

### Backup Database
```bash
# Create backup
docker compose exec postgres pg_dump -U moodleadmin moodle > moodle_backup_$(date +%Y%m%d_%H%M%S).sql
```

### Restore Database
```bash
# Restore from backup
cat moodle_backup.sql | docker compose exec -i postgres psql -U moodleadmin -d moodle
```

### Volume Data Backup
```bash
# PostgreSQL data is stored in docker_data/postgres/
# pgAdmin data is stored in docker_data/pgadmin/
# Moodle data is stored in docker_data/moodledata/
# These directories are on the host machine and persist between container restarts

# To backup all volumes:
tar -czvf moodle_volumes_backup_$(date +%Y%m%d).tar.gz docker_data/
```

> ⚠️ **Important**: 
> - Backups are saved to the host machine (outside containers)
> - Store backup files securely and encrypt sensitive data
> - Test restore procedures regularly

---

## 🐛 Troubleshooting

### Common Issues & Solutions
| Issue | Solution |
|-------|----------|
| **PostgreSQL connection fails** | Check `docker compose logs postgres` for startup errors |
| **Moodle install hangs** | Ensure PostgreSQL is ready before installation; check database connectivity |
| **Apache won't start** | Check `docker compose logs php_server` for configuration errors |
| **"Failed to open stream" error** | Verify symlink `/var/www/html/public` → `/var/www/html/moodle` exists; check Apache DocumentRoot |
| **HTML instead of config file** | Ensure `GIT_REMOTE_REPO_URL` uses `raw.githubusercontent.com` not `/blob/` |
| **Port already in use** | Run `docker compose down` then `docker compose up -d` |
| **Cron not running** | Check `/var/log/moodle/cron.log` inside the Moodle container |
| **Health checks failing** | Wait for dependencies to start (check service logs) |
| **Volume permission issues** | Ensure volume directories have proper permissions on host |

### Service Health Checks
All services include health checks:
- **Moodle**: HTTP check on port 80 (30s interval, 10s timeout, 3 retries)
- **PostgreSQL**: `pg_isready` check (5s interval, 5s timeout, 5 retries)
- **Redis**: `redis-cli ping` check (10s interval, 5s timeout, 3 retries)

### Common Commands
```bash
# Check container status and health
docker compose ps

# View resource usage
docker stats

# Inspect Moodle container
docker compose exec php_server bash

# Test database connection
docker compose exec postgres psql -U moodleadmin -d moodle

# View service logs
docker compose logs -f        # All services
docker compose logs -f php_server  # Moodle only
docker compose logs -f postgres  # PostgreSQL only

# Check health check status
docker inspect --format='{{json .State.Health}}' $(docker ps -q)
```

### Debugging Tips
- Use `docker compose exec php_server bash` for interactive debugging
- Check `.env` file for typos in variable names
- Ensure all required volumes exist: `docker_data/postgres/`, `docker_data/pgadmin/`, `docker_data/moodledata/`
- Verify port availability: `netstat -tlnp | grep -E '80|5432|6379|8443|5540'`

---

## 📚 Additional Resources

### Project Documentation
- **`AGENTS.md`**: Detailed project instructions, coding standards, and development guidelines
- **`.env.example`**: Environment variable template with all available options
- **`setup.sh`**: Fully documented Moodle installation script with all CLI parameters

### Moodle Resources
- **Moodle 5.2 Release Notes**: https://moodledev.io/general/releases/5.2
- **Moodle Official Documentation**: https://docs.moodle.org/
- **Moodle Developer Resources**: https://moodledev.io/

### Docker Resources
- **Official Moodle Docker**: https://github.com/moodlehq/moodle-docker (recommended for standard setups)
- **Docker Compose Documentation**: https://docs.docker.com/compose/

---

## 🎯 Project Evolution Summary

This project has undergone significant improvements:

✅ **Critical Bug Fixes Applied**:
- Fixed Apache configuration URL to use `raw.githubusercontent.com` instead of `github.com/blob/` to avoid downloading HTML content
- Added symlink `/var/www/html/public` → `/var/www/html/moodle` to resolve Moodle path compatibility issues
- Moved directory permissions to Dockerfile for one-time execution during build
- Documented all CLI installation parameters in setup.sh

📁 **Directory Structure**:
- Moodle source code in `./moodle/` (copied into container during build)
- Volume data stored in `docker_data/` on host machine
- Moodle web root in `/var/www/html/moodle/` inside container
- Symlink `/var/www/html/public` → `/var/www/html/moodle` for Apache compatibility

🚀 **Enhanced Features**:
- Comprehensive health checks for all services
- Improved setup script with detailed documentation
- Updated service versions (PHP 8.5.8, PostgreSQL 18.4, Redis 8.8.0)
- Enhanced security defaults and documentation
