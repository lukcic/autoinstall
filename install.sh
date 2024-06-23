#!/bin/bash -u

apt install git curl zsh vim tmux bat gh tldr -y

cd autoinstall

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

ln -s /usr/bin/batcat /usr/bin/bat

mv ~/.zshrc ~/.zshrc.bak || true
cp ./.zshrc ~/.zshrc 
cp ./.p10k.zsh ~/.p10k.zsh
chsh -s $(which zsh)

mv ~/.tmux.conf ~/.tmux.conf.bac || true
cp ./tmux.conf ~/.tmux.conf
tmux source ~/.tmux.conf

#If you want tmux to start by default with every terminal you open, add this to your .bashrc.

# if [[ -z "$TMUX" ]]; then
#     ID=$(/usr/bin/tmux ls | grep -vm1 attached | cut -d: -f1)
#     if [[ -z "${ID}" ]]; then
#         /usr/bin/tmux new-session
#     else
#         /usr/bin/tmux attach-session -t "${ID}"
#     fi
# fi