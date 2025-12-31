#!/bin/bash
set -e

echo "🚀 Starting Flutter Web Build..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web production
flutter build web --release

echo "✅ Build complete! Output in build/web/"
