# 🐳 Docker Deployment Guide

## Quick Start

### One-Command Deployment

```bash
./docker-deploy.sh
```

This interactive script will:
1. Check prerequisites (Docker, docker-compose)
2. Let you choose production or development mode
3. Build and start all containers
4. Verify health of services
5. Show you access URLs

### Manual Deployment

#### Production Mode

```bash
# Build and start
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

**Access:**
- Frontend: http://localhost:3000
- Backend: http://localhost:8080

#### Development Mode (Hot Reload)

```bash
# Build and start
docker-compose -f docker-compose.dev.yml up -d --build

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Stop
docker-compose -f docker-compose.dev.yml down
```

**Access:**
- Frontend: http://localhost:5173
- Backend: http://localhost:8080

## Prerequisites

1. **Docker Desktop** (v20.10+)
   - macOS: https://docs.docker.com/desktop/install/mac-install/
   - Windows: https://docs.docker.com/desktop/install/windows-install/
   - Linux: https://docs.docker.com/engine/install/

2. **Environment Variables**
   - Create `backend/.env` with your SERPAPI_KEY:
   ```env
   SERPAPI_KEY=your_api_key_here
   PORT=8080
   ```

## Container Architecture

```
┌─────────────────────────────────────┐
│         Docker Network              │
│                                     │
│  ┌─────────────┐  ┌──────────────┐ │
│  │  Frontend   │  │   Backend    │ │
│  │  (Nginx)    │→ │   (Go)       │ │
│  │  Port: 3000 │  │  Port: 8080  │ │
│  └─────────────┘  └──────────────┘ │
└─────────────────────────────────────┘
```

## Docker Commands Reference

### Container Management

```bash
# List running containers
docker-compose ps

# View container logs
docker-compose logs -f [service]

# Restart services
docker-compose restart

# Restart specific service
docker-compose restart backend

# Stop all containers
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Remove all (containers, networks, images)
docker-compose down --rmi all -v
```

### Building

```bash
# Build without cache
docker-compose build --no-cache

# Build specific service
docker-compose build backend

# Pull latest base images
docker-compose pull
```

### Debugging

```bash
# Execute command in running container
docker-compose exec backend sh
docker-compose exec frontend sh

# View container resource usage
docker stats

# Inspect container
docker-compose logs backend --tail=100

# Check health status
docker-compose ps
```

## Environment Configuration

### Production

The production build uses:
- Multi-stage builds for smaller images
- Nginx for serving frontend (optimized)
- Compiled Go binary (no development dependencies)
- Health checks for reliability

### Development

The development setup includes:
- Hot reload for both frontend and backend
- Source code mounted as volumes
- Air for Go hot reload
- Vite dev server for frontend
- Debug mode enabled

## Customization

### Change Ports

Edit `docker-compose.yml`:

```yaml
services:
  frontend:
    ports:
      - "8080:80"  # Change 8080 to your desired port
  backend:
    ports:
      - "9000:8080"  # Change 9000 to your desired port
```

### Custom API URL for Frontend

Build with custom API URL:

```bash
docker-compose build --build-arg VITE_API_URL=http://api.example.com
```

Or in `docker-compose.yml`:

```yaml
frontend:
  build:
    args:
      - VITE_API_URL=http://your-backend-url:8080
```

## Production Deployment

### Using Docker Compose (Single Server)

```bash
# On your server
git clone <your-repo>
cd job_search_aggregator

# Configure environment
cp backend/.env.example backend/.env
nano backend/.env  # Add your API keys

# Deploy
docker-compose up -d --build

# Setup auto-restart
docker update --restart=always careerhub-backend
docker update --restart=always careerhub-frontend
```

### Using Docker Swarm

```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml careerhub

# List services
docker stack services careerhub

# Remove stack
docker stack rm careerhub
```

### Using Kubernetes

First, build and push images:

```bash
# Build
docker build -t your-registry/careerhub-backend:latest ./backend
docker build -t your-registry/careerhub-frontend:latest ./frontend

# Push
docker push your-registry/careerhub-backend:latest
docker push your-registry/careerhub-frontend:latest
```

Then create Kubernetes manifests (example in `k8s/` directory).

## Cloud Deployment

### Railway.app

1. Connect your GitHub repository
2. Add backend service → Point to `backend/Dockerfile`
3. Add frontend service → Point to `frontend/Dockerfile`
4. Set environment variables
5. Deploy!

### Fly.io

```bash
# Install flyctl
curl -L https://fly.io/install.sh | sh

# Deploy backend
cd backend
fly launch
fly deploy

# Deploy frontend
cd ../frontend
fly launch
fly deploy
```

### AWS ECS

```bash
# Push to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin <your-ecr-url>
docker tag careerhub-backend:latest <your-ecr-url>/careerhub-backend:latest
docker push <your-ecr-url>/careerhub-backend:latest

# Create ECS task definition and service (use AWS Console or CLI)
```

## Monitoring

### Check Health

```bash
# Backend health
curl http://localhost:8080/health

# Frontend health
curl http://localhost:3000
```

### View Resource Usage

```bash
docker stats
```

### Logs Management

```bash
# Follow all logs
docker-compose logs -f

# Only backend logs
docker-compose logs -f backend

# Last 100 lines
docker-compose logs --tail=100

# With timestamps
docker-compose logs -f -t
```

## Troubleshooting

### Containers Won't Start

```bash
# Check logs
docker-compose logs

# Rebuild without cache
docker-compose build --no-cache
docker-compose up -d
```

### Port Already in Use

```bash
# Find and kill process
lsof -ti:8080 | xargs kill -9
lsof -ti:3000 | xargs kill -9

# Or change ports in docker-compose.yml
```

### Backend Can't Connect to Database/API

- Check environment variables: `docker-compose config`
- Verify network: `docker network ls`
- Test connectivity: `docker-compose exec backend ping <service>`

### Image Build Fails

```bash
# Check disk space
docker system df

# Clean up unused resources
docker system prune -a
```

### Frontend Can't Reach Backend

1. Check backend is running: `docker-compose ps`
2. Verify network: `docker network inspect careerhub_careerhub-network`
3. Check CORS settings in backend
4. Verify API URL in frontend build args

## Best Practices

1. **Use .dockerignore** - Reduce build context size
2. **Multi-stage builds** - Smaller production images
3. **Health checks** - Enable automatic recovery
4. **Resource limits** - Prevent memory issues
5. **Named volumes** - Persist data safely
6. **Environment variables** - Never hardcode secrets
7. **Regular updates** - Keep base images updated

## Security

### Production Checklist

- [ ] Use specific image versions (not `latest`)
- [ ] Run containers as non-root user
- [ ] Scan images for vulnerabilities
- [ ] Use secrets management
- [ ] Enable HTTPS (use reverse proxy like Traefik/Caddy)
- [ ] Set resource limits
- [ ] Enable logging and monitoring
- [ ] Regular security updates

### Scan for Vulnerabilities

```bash
# Install trivy
brew install trivy  # macOS

# Scan images
docker-compose build
trivy image careerhub-backend
trivy image careerhub-frontend
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build images
        run: docker-compose build
      - name: Run tests
        run: docker-compose run backend go test ./...
      - name: Deploy
        run: |
          # Your deployment script
```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Security](https://docs.docker.com/engine/security/)
