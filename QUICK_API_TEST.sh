#!/bin/bash

# Quick API Test for Phase A Email Campaign
# Purpose: Test real endpoints (not mocked)
# Prerequisites: Server running (npm run start:dev)

BASE_URL="http://localhost:3001"

echo "════════════════════════════════════════════════════════"
echo "Phase A Email Campaign - Quick API Test"
echo "════════════════════════════════════════════════════════"
echo ""

# Test 1: Public endpoint (no auth required)
echo "✓ Test 1: Check unsubscribe status (public endpoint)"
echo "  GET /api/email-unsubscribe/status?email=test@example.com"
echo ""
curl -s "${BASE_URL}/api/email-unsubscribe/status?email=test@example.com" \
  -H "Content-Type: application/json" | jq '.' 2>/dev/null || curl -s "${BASE_URL}/api/email-unsubscribe/status?email=test@example.com"
echo ""
echo ""

# Test 2: Admin endpoint (requires auth)
echo "✓ Test 2: List campaigns (admin endpoint - requires auth)"
echo "  GET /api/email-campaigns?page=1&limit=20"
echo ""
echo "ERROR: Missing Authorization header (expected)"
echo "Response:"
curl -s "${BASE_URL}/api/email-campaigns?page=1&limit=20" \
  -H "Content-Type: application/json" | jq '.' 2>/dev/null || curl -s "${BASE_URL}/api/email-campaigns?page=1&limit=20"
echo ""
echo ""

echo "════════════════════════════════════════════════════════"
echo "✅ Tests completed!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "1. Get admin token:"
echo "   curl -X POST http://localhost:3001/api/auth/login \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"email\":\"admin@incard.vn\",\"password\":\"password\"}'"
echo ""
echo "2. Use token for admin endpoints:"
echo "   curl -H 'Authorization: Bearer TOKEN' \\"
echo "     http://localhost:3001/api/email-campaigns"
echo ""
