#!/bin/bash
# Install Claude Code CLI
# Claude Code is Anthropic's official CLI for interacting with Claude

set -e

echo "📦 Installing Claude Code..."

# Ensure common user bin directories are in PATH
export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"

# Check if already installed
if command -v claude &> /dev/null; then
    CURRENT_VERSION=$(claude --version 2>&1 | head -n 1 || echo "unknown")
    echo "✅ Claude Code already installed: ${CURRENT_VERSION}"
else
    # Install Claude Code using their official installer
    curl -fsSL https://claude.ai/install.sh | bash

    # Source shell profiles to update PATH (if they exist)
    [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null || true
    [ -f "$HOME/.profile" ] && source "$HOME/.profile" 2>/dev/null || true

    # Update PATH again in case installer modified it
    export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"

    # Verify installation
    if command -v claude &> /dev/null; then
        claude --version || echo "Claude Code installed"
        echo "✅ Claude Code installed successfully"
        echo "   Location: $(which claude)"
    else
        # Try to find claude in common locations
        CLAUDE_PATH=""
        for dir in "$HOME/.local/bin" "$HOME/.claude/bin" "$HOME/bin"; do
            if [ -x "$dir/claude" ]; then
                CLAUDE_PATH="$dir/claude"
                break
            fi
        done

        if [ -n "$CLAUDE_PATH" ]; then
            echo "✅ Claude Code installed at: $CLAUDE_PATH"
            echo "   Adding to PATH permanently..."

            # Add to .bashrc if it exists
            if [ -f "$HOME/.bashrc" ]; then
                if ! grep -q '.local/bin' "$HOME/.bashrc"; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
                fi
            fi

            # Symlink to a location that's definitely in PATH
            sudo ln -sf "$CLAUDE_PATH" /usr/local/bin/claude
            echo "   Created symlink: /usr/local/bin/claude -> $CLAUDE_PATH"
            echo "✅ Claude Code is now available globally"
        else
            echo "⚠️  Claude Code installation completed but binary not found"
            echo "   You may need to restart your shell or check ~/.claude/"
        fi
    fi
fi
