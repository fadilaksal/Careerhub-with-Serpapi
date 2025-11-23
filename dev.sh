#!/bin/bash

# CareerHub - Simple Development Server
# Run both frontend and backend in development mode with network access

set -e

echo "🚀 CareerHub Development Server"
echo "================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get local IP
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "localhost")

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

# Create .env.local for frontend if it doesn't exist
echo -e "\n${YELLOW}Setting up environment...${NC}"
cat > "$FRONTEND_DIR/.env.local" << EOF
VITE_API_URL=http://${LOCAL_IP}:8080
EOF

echo -e "${GREEN}✅ Frontend environment configured${NC}"
echo "   API URL: http://${LOCAL_IP}:8080"

# Start backend in background
echo -e "\n${YELLOW}Starting Backend...${NC}"
cd "$BACKEND_DIR"
pkill -f "go run main.go" 2>/dev/null || true
go run main.go > backend.log 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > backend.pid
sleep 2

if ps -p $BACKEND_PID > /dev/null; then
    echo -e "${GREEN}✅ Backend running (PID: $BACKEND_PID)${NC}"
else
    echo "❌ Backend failed to start. Check backend.log"
    exit 1
fi

# Start frontend
echo -e "\n${YELLOW}Starting Frontend...${NC}"
cd "$FRONTEND_DIR"
pkill -f "vite" 2>/dev/null || true

# Start frontend with network access
npm run dev -- --host 0.0.0.0 &
FRONTEND_PID=$!
echo $FRONTEND_PID > frontend.pid
sleep 3

if ps -p $FRONTEND_PID > /dev/null; then
    echo -e "${GREEN}✅ Frontend running (PID: $FRONTEND_PID)${NC}"
else
    echo "❌ Frontend failed to start"
    exit 1
fi

echo -e "\n${GREEN}✨ Development servers started!${NC}"
echo "=================================="
echo ""
echo -e "${GREEN}📱 Access URLs:${NC}"
echo ""
echo -e "  Frontend:"
echo -e "    Local:   ${YELLOW}http://localhost:5173${NC}"
echo -e "    Network: ${YELLOW}http://${LOCAL_IP}:5173${NC}"
echo ""
echo -e "  Backend:"
echo -e "    Local:   ${YELLOW}http://localhost:8080${NC}"
echo -e "    Network: ${YELLOW}http://${LOCAL_IP}:8080${NC}"
echo ""
echo -e "${YELLOW}💡 Share the Network URLs to access from other devices!${NC}"
echo ""
echo "Press Ctrl+C to stop servers..."
echo ""

# Wait for both processes
wait
