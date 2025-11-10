#!/bin/bash
# Install Cursor CLI
# Cursor is an AI-first code editor (this installs the CLI tools)

set -e

echo "📦 Installing Cursor CLI..."

# Ensure common user bin directories are in PATH
export PATH="$HOME/.local/bin:$HOME/.cursor/bin:$HOME/bin:$PATH"

# Check if already installed
if command -v cursor &> /dev/null; then
    echo "✅ Cursor CLI already installed"
else
    # Install Cursor using their official installer
    curl -fsSL https://cursor.com/install | bash

    # Source shell profiles to update PATH (if they exist)
    [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null || true
    [ -f "$HOME/.profile" ] && source "$HOME/.profile" 2>/dev/null || true

    # Update PATH again in case installer modified it
    export PATH="$HOME/.local/bin:$HOME/.cursor/bin:$HOME/bin:$PATH"

    # Verify installation
    if command -v cursor &> /dev/null; then
        cursor --version || echo "Cursor CLI installed"
        echo "✅ Cursor CLI installed successfully"
        echo "   Location: $(which cursor)"
        echo "   Note: The full Cursor editor UI requires a graphical environment"
    else
        # Try to find cursor in common locations
        CURSOR_PATH=""
        for dir in "$HOME/.local/bin" "$HOME/.cursor/bin" "$HOME/bin"; do
            if [ -x "$dir/cursor" ]; then
                CURSOR_PATH="$dir/cursor"
                break
            fi
        done

        if [ -n "$CURSOR_PATH" ]; then
            echo "✅ Cursor CLI installed at: $CURSOR_PATH"
            echo "   Creating global symlink..."
            sudo ln -sf "$CURSOR_PATH" /usr/local/bin/cursor
            echo "   Created symlink: /usr/local/bin/cursor -> $CURSOR_PATH"
            echo "✅ Cursor CLI is now available globally"
            echo "   Note: The full Cursor editor UI requires a graphical environment"
        else
            echo "⚠️  Cursor CLI installation completed but binary not found"
            echo "   You may need to restart your shell"
        fi
    fi
fi
