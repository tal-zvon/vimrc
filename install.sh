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

if [[ -n "$SUDO_USER" ]]
then
    USERS="root $SUDO_USER"
    HOME_DIRS="$(eval echo ~root) $(eval echo ~$SUDO_USER)"
else
    USERS="root"
    HOME_DIRS="$(eval echo ~root)"
fi

##########################
# Detect Package Manager #
##########################

if which brew >/dev/null 2>&1; then
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
else
    echo "ERROR: Package manager not found"
    exit 1
fi

########################
# Install Requirements #
########################

echo
echo "********************************************"
echo "* Installing ctags, git, vim and neovim... *"
echo "********************************************"
echo

$INSTALL_COMMAND ctags vim neovim git

echo
echo Installed

#######################
# Make Neovim Default #
#######################

if [[ ! -e "/usr/local/bin/vim" ]]
then
    echo
    echo "*************************"
    echo "* Making Neovim Default *"
    echo "*************************"

    ln -s $(which nvim) /usr/local/bin/vim

    echo
    echo Done
fi

############################################
# Make Neovim use the ~/.vimrc config file #
############################################

echo
echo "******************************"
echo "* Making Neovim Use ~/.vimrc *"
echo "******************************"
echo

for HOME_DIR in $HOME_DIRS
do
    if [[ ! -e "$HOME_DIR/.config/nvim/init.vim" ]]
    then
        mkdir -p "$HOME_DIR/.config/nvim/"
        ln -s "$HOME_DIR/.vimrc" "$HOME_DIR/.config/nvim/init.vim"
    fi

    echo Done for $HOME_DIR
done

###############################
# Replace Vimdiff with Neovim #
###############################

if [[ ! -e "/usr/local/bin/vimdiff" ]]
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

for HOME_DIR in $HOME_DIRS
do
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

for HOME_DIR in $HOME_DIRS
do
    curl -sfLo "$HOME_DIR/.vimrc" https://raw.githubusercontent.com/tal-zvon/vimrc/master/vimrc
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

for user in $USERS
do
    sudo -u $user vim +PlugInstall +qall
    sudo -u $user nvim +PlugInstall +qall
    echo Installed for $user
done
