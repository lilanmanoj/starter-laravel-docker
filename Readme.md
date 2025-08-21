# Laravel Docker Development Environment

This project provides a **full Laravel development environment** using Docker and Docker Compose. It includes:

- **Alpine Linux** as the base image  
- **Apache + PHP-FPM** for serving Laravel  
- **MySQL** as the database  
- **Redis** for caching and queue  
- **Laravel queue workers and scheduler**  
- Automatic Laravel installation and migration  

This setup works out of the box and avoids common permission and Forbidden issues.

## 📁 Project Folder Structure
```
├── Dockerfile # Docker image for app
├── docker-compose.yml # Docker Compose configuration
├── entrypoint.sh # Entrypoint script for Laravel setup
├── supervisord.conf # Supervisor configuration for Apache + PHP-FPM
├── supervisord-queue.conf # Supervisor configuration for queue workers & scheduler
└── app/ # Laravel application (mounted as Docker volume)
```

## ⚡ Prerequisites

- Docker >= 20.x  
- Docker Compose >= 2.x  

> **Note:** On Linux, file permissions on host-mounted volumes can cause write issues. This setup handles most of them, but see troubleshooting below.

## 🚀 Getting Started

### 1. Build and start containers

```bash
docker-compose up --build
```

This will:
- Install Laravel if missing
- Set up .env with proper environment variables
- Run database migrations
- Start Apache + PHP-FPM
- Start Redis queue workers and scheduler

### 2. Access the Laravel app
Visit: http://localhost:8080

### 3. Stop containers
```bash
docker-compose down
```

### 4. Rebuild containers (after Dockerfile changes)
```bash
docker-compose up --build
```

## Laravel Queue Workers
- Queue workers run in the queue_worker container.
- Laravel jobs dispatched via php artisan queue:dispatch will be automatically processed.
- Scheduler runs automatically via Supervisor.

View logs:
```bash
docker logs -f laravel_queue
```

## Folder Permissions
- Laravel requires write permissions for:
 - `storage/` (all subfolders)
 - `bootstrap/cache/`
- The entrypoint.sh ensures proper permissions inside the container.

If you get Permission denied errors:
```bash
chmod -R 777 ./app/storage ./app/bootstrap/cache
```

## MySQL Access
From your host:
```bash
docker exec -it laravel_mysql mysql -u laravel-user -p
```
Database: `laravel-app`
User: `laravel-user`
Password: `pass`


## Troubleshooting
| Problem                          | Possible Cause                                    | Solution                                                                                                                                                 |
| -------------------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **403 Forbidden**                | Apache cannot access files in bind-mounted volume | Ensure host `app/` folder is readable (`chmod -R 755 ./app`) and `storage/bootstrap/cache` writable (`chmod -R 775 ./app/storage ./app/bootstrap/cache`) |
| **Permission denied on storage** | PHP-FPM cannot write to storage/bootstrap/cache   | Run `chmod -R 775 ./app/storage ./app/bootstrap/cache` or use named Docker volume                                                                        |
| **Laravel not installing**       | First run or empty volume                         | `docker-compose down && docker-compose up --build`                                                                                                       |
| **MySQL not ready**              | Laravel tries to migrate before MySQL is up       | Entrypoint script waits for DB automatically                                                                                                             |
