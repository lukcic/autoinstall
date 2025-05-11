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
    "tldr")

CONFIG_DIR="$(pwd)/config"
FONT_DIR="$(pwd)/font"

install_packages() {
    echo "Installing packages..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux detected. Installing packages using the appropriate package manager."

        if command -v apt &> /dev/null; then
            sudo apt update > /dev/null
            sudo apt install -y "$@"
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y "$@"
        elif command -v pacman &> /dev/null; then
            sudo pacman -Syu --noconfirm "$@"
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
        brew install "$@" > /dev/null
    else
        echo "Unsupported OS. Please install the packages manually."
        exit 1
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

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || true > /dev/null
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || true > /dev/null
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k || true > /dev/null
    echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=false' >> ~/.zshrc
}

configure_tmux() {
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm || true > /dev/null
}

setup_aliases() {
    echo "Setting up custom aliases..."
    cp "$CONFIG_DIR/.custom_aliases" "$HOME"/.config/.custom_aliases

    if ! grep -q "source $HOME/.config/.custom_aliases" "$HOME/.zshrc"; then
        echo -e "\n# Load custom aliases" >> "$HOME/.zshrc"
        echo "source $HOME/.config/.custom_aliases" >> "$HOME"/.zshrc
    fi
}

configure_bat() {
    if ! command -v bat &> /dev/null; then
        sudo ln -s /usr/bin/batcat /usr/bin/bat
    fi
}

link_dotfiles() {
    mkdir -p "$HOME"/.config
    cp -r "$CONFIG_DIR"/ "$HOME"/.config/

    shopt -s dotglob # required to include hidden files
    for file in "$HOME"/.config/*; do
        target="$HOME/$(basename "$file")"
        if [[ -e "$target" ]]; then
            mkdir -p "$HOME/.config_backups"
            mv -n "$target" "$HOME/.config_backups/$(basename "$target")"
            ln -sf "$file" "$target"
        else
            ln -sf "$file" "$target"
        fi
    done
    shopt -u dotglob
}

main() {
    install_packages "${PACKAGES[@]}"
    configure_bat
    configure_zsh
    link_dotfiles
    install_font
    setup_aliases
    configure_tmux
    exec zsh
    chsh -s $(which zsh)
}

main "$@"