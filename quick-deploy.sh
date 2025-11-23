#!/bin/bash
# Quick deployment for internet access

echo "🌐 Making CareerHub accessible over internet..."

# Get IP
IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)

if [ -z "$IP" ]; then
    echo "❌ Could not detect IP address"
    exit 1
fi

echo "✅ Your IP: $IP"
echo ""
echo "📝 Quick Setup:"
echo "1. Starting servers with network access..."
echo ""

cd "$(dirname "$0")"

# Update frontend .env.local
echo "VITE_API_URL=http://$IP:8080" > frontend/.env.local

# Start backend
cd backend
pkill -f "go run main.go" 2>/dev/null || true
go run main.go &
sleep 2

# Start frontend  
cd ../frontend
pkill -f "vite" 2>/dev/null || true
npm run dev -- --host 0.0.0.0 &
sleep 3

echo ""
echo "✨ Ready! Share this URL:"
echo ""
echo "   🔗 http://$IP:5173"
echo ""
echo "Press Ctrl+C to stop"
wait
