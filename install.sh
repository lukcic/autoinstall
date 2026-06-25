#!/usr/bin/env bash

set -euo pipefail

PACKAGES=(
    "git" \
    "curl" \
    "zsh" \
    "vim" \
    "tmux" \
    "bat" \
    "gh" \
    "fontconfig"\
    "tldr" \
    "stow" \
    "fzf" \
    "zoxide")

FONT_DIR="$(pwd)/font"

install_packages() {
    echo "Installing packages..."

    # Install package-by-package: package names differ across distros (e.g. tldr
    # vs tealdeer) and a single missing candidate shouldn't abort the whole setup.
    local pkg
    local -a failed=()

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux detected. Installing packages using the appropriate package manager."

        if command -v apt &> /dev/null; then
            sudo apt update > /dev/null
            for pkg in "$@"; do
                sudo apt install -y "$pkg" > /dev/null || failed+=("$pkg")
            done
        elif command -v dnf &> /dev/null; then
            for pkg in "$@"; do
                sudo dnf install -y "$pkg" > /dev/null || failed+=("$pkg")
            done
        elif command -v pacman &> /dev/null; then
            sudo pacman -Sy --noconfirm > /dev/null
            for pkg in "$@"; do
                sudo pacman -S --noconfirm --needed "$pkg" > /dev/null || failed+=("$pkg")
            done
        else
            echo "Unsupported package manager. Please install the packages manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "MacOS detected. Installing packages using Homebrew."
        if ! command -v brew &> /dev/null; then
            echo "Homebrew not found. Please install Homebrew first."
            exit 1
        fi
        brew update > /dev/null
        for pkg in "$@"; do
            brew install "$pkg" > /dev/null || failed+=("$pkg")
        done
    else
        echo "Unsupported OS. Please install the packages manually."
        exit 1
    fi

    if (( ${#failed[@]} > 0 )); then
        echo "⚠️  Could not install: ${failed[*]} — install manually if needed."
    fi
}

install_font() {

    FONT_DIR_MAC="$HOME/Library/Fonts"
    FONT_DIR_LINUX="$HOME/.local/share/fonts"

    install_fonts_mac() {
        echo "🖋 Installing font on MacOS..."
        mkdir -p "$FONT_DIR_MAC"

        for font in "$FONT_DIR"/*.ttf; do
            if [ ! -f "$FONT_DIR_MAC/$(basename "$font")" ]; then
            cp "$font" "$FONT_DIR_MAC/"
            echo "✅ Installed $(basename "$font")"
            else
            echo "⚠️ $(basename "$font") already installed."
            fi
        done
    }

    install_fonts_linux() {
        echo "🖋 Installing fonts on Linux..."
        mkdir -p "$FONT_DIR_LINUX"

        for font in "$FONT_DIR"/*.ttf; do
            if [ ! -f "$FONT_DIR_LINUX/$(basename "$font")" ]; then
            cp "$font" "$FONT_DIR_LINUX/"
            echo "✅ Installed $(basename "$font")"
            else
            echo "⚠️  $(basename "$font") already installed."
            fi
        done

        echo "🔄 Refreshing font cache..."
        fc-cache -fv > /dev/null
    }

    if [ ! -d "$FONT_DIR" ]; then
        echo "❌ Font source directory '$FONT_DIR' not found."
        exit 1
    fi

    case "$OSTYPE" in
        darwin*) install_fonts_mac ;;
        linux*) install_fonts_linux ;;
        *)
        echo "❌ Unsupported OS: $OSTYPE"
        exit 1
        ;;
    esac

    echo "🎉 Fonts installation completed."
}

configure_zsh() {
    export RUNZSH=no
    export CHSH=no

    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
    git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions" || true
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting" || true
    git clone https://github.com/Aloxaf/fzf-tab "$zsh_custom/plugins/fzf-tab" || true
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k" || true

    # oh-my-zsh drops a template ~/.zshrc; configuration is owned by the dotfiles repo (GNU Stow).
    # Move it out of the way so `stow .` can place its symlink without colliding.
    if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
        mkdir -p "$HOME/.config_backups"
        mv -n "$HOME/.zshrc" "$HOME/.config_backups/.zshrc"
    fi
}

configure_tmux() {
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm || true > /dev/null
}

configure_bat() {
    # On Debian/Ubuntu the binary is installed as `batcat` (name clash with an
    # unrelated `bat` package), so expose it under the expected `bat` name.
    if ! command -v bat &> /dev/null; then
        sudo ln -s /usr/bin/batcat /usr/bin/bat
    fi
}

main() {
    install_packages "${PACKAGES[@]}"
    configure_bat
    install_font
    configure_zsh
    configure_tmux

    # Set zsh as the default login shell (no exec — let the script finish first).
    if [[ "$SHELL" != *zsh ]]; then
        chsh -s "$(which zsh)" || echo "⚠️  Could not change default shell; run 'chsh -s $(which zsh)' manually."
    fi

    cat <<'EOF'

✅ System setup complete.

Next step — apply your configuration with GNU Stow (explicit --target is
required because the repo lives under ~/projects, not directly in $HOME):

    cd ~/projects/dotfiles && stow -t "$HOME" --no-folding .

Then open a new terminal (or run 'zsh') to load the configured shell.
EOF
}

main "$@"