#!/usr/bin/env bash

#####################
# Force run as Root #
#####################

# Too many commands need to be run as root for us to go through the
# trouble of using sudo everywhere

if [[ "$(id -u)" != 0 ]]
then
    echo "ERROR: Must run as root"
    exit 1
fi

#################
# Set Some Vars #
#################

# Note: Loop through these like:
#   for user in "${!USERS[@]}"
#   do
#       HOME_DIR=${USERS[$user]}
#   done
#
#   Where 'user' is the username, and 'HOME_DIR' is the home directory

if [[ -n "$SUDO_USER" ]]
then
    declare -A USERS=( [root]=$(eval echo ~root) [$SUDO_USER]=$(eval echo ~$SUDO_USER) )
else
    declare -A USERS=( [root]=$(eval echo ~root) )
fi

##########################
# Detect Package Manager #
##########################

if which brew >/dev/null 2>&1; then
    # Homebrew needs to run as local user
    if [[ -n "$SUDO_USER" ]]
    then
        INSTALL_COMMAND="sudo -u $SUDO_USER brew install"
    else
        INSTALL_COMMAND="brew install"
    fi
elif which apt-get >/dev/null 2>&1; then
    INSTALL_COMMAND="apt-get -y install"
elif which dnf >/dev/null 2>&1; then
    INSTALL_COMMAND="dnf -y install"
elif which yum >/dev/null 2>&1; then
    INSTALL_COMMAND="yum -y install"
elif which pacman >/dev/null 2>&1; then
    INSTALL_COMMAND="pacman --noconfirm -S"
else
    echo "ERROR: Package manager not found"
    exit 1
fi

########################
# Install Requirements #
########################

# Note: Even if install fails, we keep going

echo
echo "********************************************"
echo "* Installing ctags, git, vim and neovim... *"
echo "********************************************"
echo

$INSTALL_COMMAND ctags vim neovim git

if [[ "$?" == "0" ]]
then
    echo
    echo Installed
else
    echo
    echo Install FAILED
fi

#################################
# Check if Neovim was Installed #
#################################

if which nvim >/dev/null 2>/dev/null
then
    NVIM_INSTALLED=true
else
    NVIM_INSTALLED=false
fi

#######################
# Make Neovim Default #
#######################

if $NVIM_INSTALLED && [[ ! -e "/usr/local/bin/vim" ]]
then
    echo
    echo "*************************"
    echo "* Making Neovim Default *"
    echo "*************************"

    ln -sf $(which nvim) /usr/local/bin/vim

    echo
    echo Done
fi

############################################
# Make Neovim use the ~/.vimrc config file #
############################################

if $NVIM_INSTALLED
then
    echo
    echo "******************************"
    echo "* Making Neovim Use ~/.vimrc *"
    echo "******************************"
    echo

    for user in "${!USERS[@]}"
    do
        HOME_DIR=${USERS[$user]}

        if [[ ! -e "$HOME_DIR/.config/nvim/init.vim" ]]
        then
            sudo -u $user mkdir -p "$HOME_DIR/.config/nvim/"
            sudo -u $user ln -sf "$HOME_DIR/.vimrc" "$HOME_DIR/.config/nvim/init.vim"
        fi

        echo Done for $HOME_DIR
    done
fi

###############################
# Replace Vimdiff with Neovim #
###############################

if $NVIM_INSTALLED && [[ ! -e "/usr/local/bin/vimdiff" ]]
then
    echo
    echo "*********************************"
    echo "* Replacing vimdiff with Neovim *"
    echo "*********************************"

    echo -e '#!/usr/bin/env bash\n\nnvim -d "$@"' > /usr/local/bin/vimdiff
    chmod a+x /usr/local/bin/vimdiff
    echo Done
fi

#######################
# Remove Old Versions #
#######################

echo
echo "***********************************"
echo "* Removing Old .vimrc and Plugins *"
echo "***********************************"
echo

for user in "${!USERS[@]}"
do
    HOME_DIR=${USERS[$user]}

    rm -f "$HOME_DIR/.vimrc"
    rm -rf "$HOME_DIR/.vim"
    echo Done for $HOME_DIR
done

#################
# Install Vimrc #
#################

echo
echo "********************"
echo "* Installing vimrc *"
echo "********************"
echo

for user in "${!USERS[@]}"
do
    HOME_DIR=${USERS[$user]}

    sudo -u $user curl -sfLo "$HOME_DIR/.vimrc" https://raw.githubusercontent.com/tal-zvon/vimrc/master/vimrc

    # Unless the script specified --with-rust, skip installing coc, or coc-rust-analyzer
    if [[ "$1" == "--with-rust" ]]
    then
        sudo -u $user sed -i 's/"\(Plug.*coc.*\)/\1/g' "$HOME_DIR/.vimrc"
    fi

    echo Done for $HOME_DIR
done

###################
# Install Plugins #
###################

echo
echo "**********************"
echo "* Installing Plugins *"
echo "**********************"
echo

for user in "${!USERS[@]}"
do
    HOME_DIR=${USERS[$user]}
    
    # Create ~/.vim and set its owner, in case it wasn't set
    # Not sure why this is necessary, but it was - my original code was
    # creating ~/.vim as the root user for some reason
    sudo -u $user mkdir -p "$HOME_DIR/.vim"
    sudo chown $user "$HOME_DIR/.vim"

    # Install plugins with vim
    sudo -u $user vim +PlugInstall +qall

    # Install plugins with nvim, if present
    if $NVIM_INSTALLED
    then
        sudo -u $user nvim +PlugInstall +qall
    fi

    # Fix ALL permissions under ~/.vim
    sudo chown -R $user "$HOME_DIR/.vim"

    echo Installed for $user
done

###########################
# Warn If Nvim is Missing #
###########################

if ! $NVIM_INSTALLED
then
    echo
    echo "*************************************"
    echo "* WARNING: FAILED TO INSTALL NEOVIM *"
    echo "*************************************"
    echo
fi
