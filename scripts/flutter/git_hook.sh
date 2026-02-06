#!/usr/bin/env bash

set -e

echo "🚀 Setting up Git hooks for Flutter..."

# Check Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew not found. Install it first:"
  echo "👉 https://brew.sh"
  exit 1
fi

# Install pre-commit if missing
if ! command -v pre-commit >/dev/null 2>&1; then
  echo "📦 Installing pre-commit..."
  brew install pre-commit
else
  echo "✅ pre-commit already installed."
fi

# Install git hooks
echo "🔧 Installing pre-commit hooks..."
pre-commit install

echo "🎉 Git hooks installed successfully!"
echo "From now on, commits will run:"
echo "  • dart format"
echo "  • flutter analyze"
