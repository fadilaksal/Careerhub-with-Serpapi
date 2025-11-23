#!/bin/bash

# CareerHub - Development Deployment Script
# This script deploys both frontend and backend for internet access

set -e  # Exit on error

echo "🚀 CareerHub Development Deployment"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "\n${YELLOW}📋 Checking prerequisites...${NC}"

if ! command_exists go; then
    echo -e "${RED}❌ Go is not installed${NC}"
    exit 1
fi

if ! command_exists node; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    exit 1
fi

if ! command_exists npm; then
    echo -e "${RED}❌ npm is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites satisfied${NC}"

# Get local IP address
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "localhost")

# Build Backend
echo -e "\n${YELLOW}🔨 Building Backend...${NC}"
cd "$BACKEND_DIR"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found in backend directory${NC}"
    echo "Please create .env file with SERPAPI_KEY"
    exit 1
fi

# Build Go binary
echo "Building Go binary..."
go build -o careerhub-server main.go

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend built successfully${NC}"
else
    echo -e "${RED}❌ Backend build failed${NC}"
    exit 1
fi

# Build Frontend
echo -e "\n${YELLOW}🔨 Building Frontend...${NC}"
cd "$FRONTEND_DIR"

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install
fi

# Update API endpoint for network access
echo "Updating API endpoint configuration..."
export VITE_API_URL="http://${LOCAL_IP}:8080"

# Build frontend
echo "Building frontend for production..."
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Frontend built successfully${NC}"
else
    echo -e "${RED}❌ Frontend build failed${NC}"
    exit 1
fi

# Start Backend
echo -e "\n${YELLOW}🚀 Starting Backend Server...${NC}"
cd "$BACKEND_DIR"

# Kill existing backend process if running
pkill -f careerhub-server 2>/dev/null || true

# Set PORT for network access
export PORT=8080

# Start backend in background
nohup ./careerhub-server > backend.log 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > backend.pid

sleep 2

if ps -p $BACKEND_PID > /dev/null; then
    echo -e "${GREEN}✅ Backend started (PID: $BACKEND_PID)${NC}"
else
    echo -e "${RED}❌ Backend failed to start${NC}"
    cat backend.log
    exit 1
fi

# Start Frontend Preview Server
echo -e "\n${YELLOW}🚀 Starting Frontend Preview Server...${NC}"
cd "$FRONTEND_DIR"

# Kill existing frontend process if running
pkill -f "vite preview" 2>/dev/null || true

# Start frontend preview server in background (accessible from network)
nohup npm run preview -- --host 0.0.0.0 --port 4173 > frontend.log 2>&1 &
FRONTEND_PID=$!
echo $FRONTEND_PID > frontend.pid

sleep 3

if ps -p $FRONTEND_PID > /dev/null; then
    echo -e "${GREEN}✅ Frontend preview started (PID: $FRONTEND_PID)${NC}"
else
    echo -e "${RED}❌ Frontend failed to start${NC}"
    cat frontend.log
    exit 1
fi

# Display access information
echo -e "\n${GREEN}✨ Deployment Complete!${NC}"
echo "======================================"
echo ""
echo -e "${GREEN}📱 Access your application:${NC}"
echo ""
echo -e "  🌐 Frontend (Local):   ${YELLOW}http://localhost:4173${NC}"
echo -e "  🌐 Frontend (Network): ${YELLOW}http://${LOCAL_IP}:4173${NC}"
echo ""
echo -e "  🔌 Backend (Local):    ${YELLOW}http://localhost:8080${NC}"
echo -e "  🔌 Backend (Network):  ${YELLOW}http://${LOCAL_IP}:8080${NC}"
echo ""
echo -e "${YELLOW}📋 Management:${NC}"
echo "  • Backend logs:  tail -f $BACKEND_DIR/backend.log"
echo "  • Frontend logs: tail -f $FRONTEND_DIR/frontend.log"
echo "  • Stop servers:  $SCRIPT_DIR/stop.sh"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "  • Share the Network URLs with others on your network"
echo "  • Make sure firewall allows connections on ports 8080 and 4173"
echo "  • Backend PID: $BACKEND_PID (saved in backend/backend.pid)"
echo "  • Frontend PID: $FRONTEND_PID (saved in frontend/frontend.pid)"
echo ""
