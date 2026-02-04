#!/bin/bash

# Notification System Deployment Script
# This script automates the deployment of the notification system

set -e

echo "🔔 Starting Notification System Deployment..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Install Flutter dependencies
echo -e "${BLUE}📦 Step 1: Installing Flutter dependencies...${NC}"
flutter pub get
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Flutter dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install Flutter dependencies${NC}"
    exit 1
fi
echo ""

# Step 2: Install Cloud Functions dependencies
echo -e "${BLUE}📦 Step 2: Installing Cloud Functions dependencies...${NC}"
cd functions
npm install
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Cloud Functions dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install Cloud Functions dependencies${NC}"
    exit 1
fi
echo ""

# Step 3: Build Cloud Functions
echo -e "${BLUE}🔨 Step 3: Building Cloud Functions...${NC}"
npm run build
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Cloud Functions built successfully${NC}"
else
    echo -e "${RED}❌ Failed to build Cloud Functions${NC}"
    exit 1
fi
echo ""

# Step 4: Deploy Cloud Functions
echo -e "${BLUE}🚀 Step 4: Deploying Cloud Functions to Firebase...${NC}"
echo "This may take a few minutes..."
firebase deploy --only functions
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Cloud Functions deployed successfully${NC}"
else
    echo -e "${RED}❌ Failed to deploy Cloud Functions${NC}"
    exit 1
fi
echo ""

# Step 5: Deploy Firestore Rules
echo -e "${BLUE}🔒 Step 5: Would you like to deploy Firestore security rules? (y/n)${NC}"
read -r deploy_rules
if [ "$deploy_rules" = "y" ] || [ "$deploy_rules" = "Y" ]; then
    firebase deploy --only firestore:rules
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Firestore rules deployed${NC}"
    else
        echo -e "${RED}❌ Failed to deploy Firestore rules${NC}"
    fi
fi
echo ""

# Return to root directory
cd ..

# Step 6: iOS Pod Install
echo -e "${BLUE}📱 Step 6: Would you like to install iOS pods? (y/n)${NC}"
read -r install_pods
if [ "$install_pods" = "y" ] || [ "$install_pods" = "Y" ]; then
    cd ios
    pod install
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ iOS pods installed${NC}"
    else
        echo -e "${RED}❌ Failed to install iOS pods${NC}"
    fi
    cd ..
fi
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Notification System Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "📋 Next Steps:"
echo "1. Verify Cloud Functions are active in Firebase Console"
echo "2. Test notifications by creating a booking"
echo "3. Check FCM tokens in Firestore: users/{userId}/fcmTokens"
echo "4. Review logs: firebase functions:log"
echo ""
echo "📖 For detailed testing guide, see NOTIFICATIONS_README.md"
echo ""
echo -e "${BLUE}🚀 To run the app:${NC}"
echo "   flutter run --release"
echo ""
