#!/bin/bash

# Docker deployment script for CareerHub

set -e

echo "🐳 CareerHub Docker Deployment"
echo "=============================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Please install Docker from https://docker.com"
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose is not installed${NC}"
    echo "Please install docker-compose"
    exit 1
fi

echo -e "${GREEN}✅ Docker and docker-compose found${NC}"

# Check for .env file
if [ ! -f "backend/.env" ]; then
    echo -e "${YELLOW}⚠️  No .env file found in backend/${NC}"
    echo "Creating .env from template..."
    cat > backend/.env << EOF
SERPAPI_KEY=your_serpapi_key_here
PORT=8080
EOF
    echo -e "${YELLOW}📝 Please update backend/.env with your SERPAPI_KEY${NC}"
    read -p "Press Enter to continue after updating .env file..."
fi

# Select deployment mode
echo ""
echo "Select deployment mode:"
echo "1) Production (optimized builds)"
echo "2) Development (hot reload)"
read -p "Enter choice [1-2]: " choice

case $choice in
    1)
        echo -e "\n${YELLOW}🏗️  Building production containers...${NC}"
        docker-compose down 2>/dev/null || true
        docker-compose build --no-cache
        
        echo -e "\n${YELLOW}🚀 Starting production containers...${NC}"
        docker-compose up -d
        
        echo -e "\n${GREEN}✨ Production deployment complete!${NC}"
        echo ""
        echo "📱 Access URLs:"
        echo "  Frontend: http://localhost:3000"
        echo "  Backend:  http://localhost:8080"
        echo ""
        echo "📊 View logs:"
        echo "  docker-compose logs -f"
        echo ""
        echo "🛑 Stop containers:"
        echo "  docker-compose down"
        ;;
    2)
        echo -e "\n${YELLOW}🏗️  Building development containers...${NC}"
        docker-compose -f docker-compose.dev.yml down 2>/dev/null || true
        docker-compose -f docker-compose.dev.yml build
        
        echo -e "\n${YELLOW}🚀 Starting development containers...${NC}"
        docker-compose -f docker-compose.dev.yml up -d
        
        echo -e "\n${GREEN}✨ Development deployment complete!${NC}"
        echo ""
        echo "📱 Access URLs:"
        echo "  Frontend: http://localhost:5173"
        echo "  Backend:  http://localhost:8080"
        echo ""
        echo "📊 View logs:"
        echo "  docker-compose -f docker-compose.dev.yml logs -f"
        echo ""
        echo "🛑 Stop containers:"
        echo "  docker-compose -f docker-compose.dev.yml down"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# Wait for services to be ready
echo -e "\n${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 5

# Check backend health
echo -e "\n${YELLOW}🔍 Checking backend health...${NC}"
for i in {1..10}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend is healthy${NC}"
        break
    fi
    if [ $i -eq 10 ]; then
        echo -e "${RED}❌ Backend health check failed${NC}"
        echo "Check logs with: docker-compose logs backend"
    fi
    sleep 2
done

# Check frontend
echo -e "\n${YELLOW}🔍 Checking frontend...${NC}"
FRONTEND_PORT=$([ "$choice" = "1" ] && echo "3000" || echo "5173")
if curl -s http://localhost:$FRONTEND_PORT > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend is running${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend might still be starting...${NC}"
fi

echo -e "\n${GREEN}🎉 Deployment successful!${NC}"
echo ""
echo "💡 Quick commands:"
echo "  docker-compose ps              # View running containers"
echo "  docker-compose logs -f         # Follow logs"
echo "  docker-compose restart         # Restart all services"
echo "  docker-compose down            # Stop all services"
echo "  docker-compose down -v         # Stop and remove volumes"
echo ""
