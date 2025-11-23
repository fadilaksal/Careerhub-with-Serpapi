#!/bin/bash

# CareerHub - Stop Deployment Script
# Stops all running backend and frontend processes

set -e

echo "🛑 Stopping CareerHub Services"
echo "=============================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

# Stop Backend
echo -e "\n${YELLOW}Stopping Backend...${NC}"
if [ -f "$BACKEND_DIR/backend.pid" ]; then
    BACKEND_PID=$(cat "$BACKEND_DIR/backend.pid")
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        kill $BACKEND_PID
        echo -e "${GREEN}✅ Backend stopped (PID: $BACKEND_PID)${NC}"
    else
        echo -e "${YELLOW}⚠️  Backend process not running${NC}"
    fi
    rm "$BACKEND_DIR/backend.pid"
else
    echo -e "${YELLOW}⚠️  No backend PID file found${NC}"
fi

# Also kill by process name
pkill -f careerhub-server 2>/dev/null && echo -e "${GREEN}✅ Killed careerhub-server processes${NC}" || true

# Stop Frontend
echo -e "\n${YELLOW}Stopping Frontend...${NC}"
if [ -f "$FRONTEND_DIR/frontend.pid" ]; then
    FRONTEND_PID=$(cat "$FRONTEND_DIR/frontend.pid")
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        kill $FRONTEND_PID
        echo -e "${GREEN}✅ Frontend stopped (PID: $FRONTEND_PID)${NC}"
    else
        echo -e "${YELLOW}⚠️  Frontend process not running${NC}"
    fi
    rm "$FRONTEND_DIR/frontend.pid"
else
    echo -e "${YELLOW}⚠️  No frontend PID file found${NC}"
fi

# Also kill by process name
pkill -f "vite preview" 2>/dev/null && echo -e "${GREEN}✅ Killed vite preview processes${NC}" || true

echo -e "\n${GREEN}✨ All services stopped!${NC}"
