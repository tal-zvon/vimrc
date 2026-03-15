#!/usr/bin/env bash

set -Eeuo pipefail
trap 'echo "ERROR: Script failed at line $LINENO" >&2; exit 1' ERR

#####################
# Force run as Root #
#####################

# Too many commands need to be run as root for us to go through the
# trouble of using sudo everywhere

if [[ "$(id -u)" != 0 ]]
then
    echo "ERROR: Must run as root" >&2
    exit 1
fi

#######################
# Parse CLI Arguments #
#######################

NEOVIM_INSTALL_MODE="auto"  # auto|skip|force

print_help() {
    cat <<'EOF'
Usage: install.sh [--skip-neovim] [--force-neovim] [-h|--help]

  --skip-neovim     Never attempt to install Neovim via the package manager.
  --force-neovim    Always attempt to install Neovim via the package manager.
                   (Overrides auto-detect.)
  -h, --help        Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-neovim|--no-neovim)
            NEOVIM_INSTALL_MODE="skip"
            shift
            ;;
        --force-neovim)
            NEOVIM_INSTALL_MODE="force"
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "ERROR: Unknown argument: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
    esac
done

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

USERS=(root)
if [[ -n "${SUDO_USER:-}" ]]; then
    USERS+=("$SUDO_USER")
fi

get_home_dir() {
    local username="$1"

    if [[ -z "$username" ]]; then
        echo "ERROR: get_home_dir: empty username" >&2
        return 1
    fi

    # Linux
    if command -v getent >/dev/null 2>&1; then
        local home_dir
        home_dir="$(getent passwd "$username" 2>/dev/null | awk -F: '{print $6}' || true)"
        if [[ -n "$home_dir" ]]; then
            printf '%s\n' "$home_dir"
            return 0
        fi
    fi

    # macOS
    if command -v dscl >/dev/null 2>&1; then
        local home_dir
        home_dir="$(dscl . -read "/Users/$username" NFSHomeDirectory 2>/dev/null | awk '{print $2}' || true)"
        if [[ -n "$home_dir" ]]; then
            printf '%s\n' "$home_dir"
            return 0
        fi
    fi

    # Fallback (tilde expansion)
    local expanded_home_dir
    expanded_home_dir="$(eval "printf '%s\n' ~$username" 2>/dev/null || true)"
    if [[ -n "$expanded_home_dir" ]]; then
        printf '%s\n' "$expanded_home_dir"
        return 0
    fi

    echo "ERROR: Could not determine home directory for user '$username'" >&2
    return 1
}

##########################
# Detect Package Manager #
##########################

if command -v brew >/dev/null 2>&1; then
    PACKAGE_MANAGER="brew"
    if [[ -n "${SUDO_USER:-}" ]]
    then
        INSTALL_COMMAND=( sudo -u "$SUDO_USER" brew install )
    else
        INSTALL_COMMAND=( brew install )
    fi
elif command -v apt-get >/dev/null 2>&1; then
    PACKAGE_MANAGER="apt"
    INSTALL_COMMAND=( apt-get -y install )
elif command -v dnf >/dev/null 2>&1; then
    PACKAGE_MANAGER="dnf"
    INSTALL_COMMAND=( dnf -y install )
elif command -v yum >/dev/null 2>&1; then
    PACKAGE_MANAGER="yum"
    INSTALL_COMMAND=( yum -y install )
elif command -v pacman >/dev/null 2>&1; then
    PACKAGE_MANAGER="pacman"
    INSTALL_COMMAND=( pacman --noconfirm -S )
elif command -v apk >/dev/null 2>&1; then
    PACKAGE_MANAGER="apk"
    INSTALL_COMMAND=( apk add --no-cache )
else
    echo "ERROR: Package manager not found" >&2
    exit 1
fi

echo "Using package manager: $PACKAGE_MANAGER"

####################################
# Decide Whether to Install Neovim #
####################################

if command -v nvim >/dev/null 2>&1; then
    NVIM_ALREADY_INSTALLED=true
else
    NVIM_ALREADY_INSTALLED=false
fi

INSTALL_NEOVIM=false
case "$NEOVIM_INSTALL_MODE" in
    force)
        INSTALL_NEOVIM=true
        ;;
    skip)
        INSTALL_NEOVIM=false
        ;;
    auto)
        if [[ "$NVIM_ALREADY_INSTALLED" == false ]]; then
            INSTALL_NEOVIM=true
        fi
        ;;
    *)
        echo "ERROR: Invalid NEOVIM_INSTALL_MODE: $NEOVIM_INSTALL_MODE" >&2
        exit 2
        ;;
esac

########################
# Install Requirements #
########################

echo
echo "***************************"
echo "* Installing Requirements *"
echo "***************************"
echo

case "$PACKAGE_MANAGER" in
    apt)
        PACKAGES=(
            git fzf lazygit
            fd-find curl ripgrep
            wget luarocks
        )
        ;;
    dnf|yum)
        PACKAGES=(
            git fzf lazygit
            fd-find curl ripgrep
            wget luarocks
        )
        ;;
    pacman)
        PACKAGES=(
            git fzf lazygit
            fd curl ripgrep
            wget luarocks
        )
        ;;
    apk)
        PACKAGES=(
            git fzf
            fd curl ripgrep
            wget luarocks
        )
        ;;
    brew)
        PACKAGES=(
            git fzf lazygit
            fd ripgrep
            wget luarocks
        )
        ;;
esac

if [[ "$INSTALL_NEOVIM" == true ]]; then
    PACKAGES=( neovim "${PACKAGES[@]}" )
else
    echo "Skipping Neovim install (mode=$NEOVIM_INSTALL_MODE, nvim_present=$NVIM_ALREADY_INSTALLED)"
fi

for pkg in "${PACKAGES[@]}"
do
    echo "Installing $pkg..."

    if ! "${INSTALL_COMMAND[@]}" "$pkg" >/dev/null 2>&1; then
        if [[ "$pkg" == "neovim" ]]; then
            echo "ERROR: Failed to install neovim" >&2
            exit 1
        fi
        echo "  -> Skipped $pkg"
    fi
done

echo
echo Done

#################################
# Check if Neovim was Installed #
#################################

if command -v nvim >/dev/null 2>&1
then
    NVIM_INSTALLED=true
else
    NVIM_INSTALLED=false
fi

###########################
# Verify Critical Tools   #
###########################

if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git is required but was not installed." >&2
    exit 1
fi

#######################
# Make Neovim Default #
#######################

if [[ "$NVIM_INSTALLED" == true ]] && [[ ! -e "/usr/local/bin/vim" ]]
then
    echo
    echo "*************************"
    echo "* Making Neovim Default *"
    echo "*************************"

    ln -sf "$(command -v nvim)" /usr/local/bin/vim

    echo
    echo Done
fi

###############################
# Replace Vimdiff with Neovim #
###############################

if [[ "$NVIM_INSTALLED" == true ]] && [[ ! -e "/usr/local/bin/vimdiff" ]]
then
    echo
    echo "*********************************"
    echo "* Replacing vimdiff with Neovim *"
    echo "*********************************"

    printf '%s\n' '#!/usr/bin/env bash' '' 'nvim -d "$@"' > /usr/local/bin/vimdiff
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

for user in "${USERS[@]}"
do
    HOME_DIR="$(get_home_dir "$user")"

    if [[ -z "$HOME_DIR" || ! -d "$HOME_DIR" ]]; then
        echo "ERROR: Invalid HOME_DIR for user '$user': '$HOME_DIR'" >&2
        exit 1
    fi

    rm -f "$HOME_DIR/.vimrc"
    rm -rf "$HOME_DIR/.vim"
    rm -rf "$HOME_DIR/.config/nvim"
    rm -rf "$HOME_DIR/.local/share/nvim"
    rm -rf "$HOME_DIR/.local/state/nvim"
    echo "Done for $HOME_DIR"
done

#########################
# Install Neovim Config #
#########################

echo
echo "****************************"
echo "* Installing Neovim Config *"
echo "****************************"
echo

for user in "${USERS[@]}"
do
    HOME_DIR="$(get_home_dir "$user")"
    NVIM_DIR="$HOME_DIR/.config/nvim"

    if [[ -z "$HOME_DIR" || ! -d "$HOME_DIR" ]]; then
        echo "ERROR: Invalid HOME_DIR for user '$user': '$HOME_DIR'" >&2
        exit 1
    fi

    echo "Installing config for $HOME_DIR..."

    sudo -u "$user" mkdir -p "$HOME_DIR/.config"

    if [[ -d "$NVIM_DIR/.git" ]]; then
        echo "ERROR: Expected fresh reinstall, but found existing git repo at $NVIM_DIR" >&2
        exit 1
    fi

    if ! sudo -u "$user" git clone \
        https://github.com/tal-zvon/vimrc.git \
        "$NVIM_DIR"
    then
        echo "ERROR: Failed to clone config for user '$user' into '$NVIM_DIR'" >&2
        exit 1
    fi

    if ! sudo -u "$user" test -f "$NVIM_DIR/init.lua"; then
        echo "ERROR: Clone succeeded but '$NVIM_DIR/init.lua' is missing; repo layout unexpected." >&2
        exit 1
    fi

    echo "Done for $HOME_DIR"
done

#############################################
# Attempt to Install Plugins using Lockfile #
#############################################

if [[ "$NVIM_INSTALLED" == true ]]
then
    echo
    echo "*********************************"
    echo "* Installing Neovim Plugins... *"
    echo "*********************************"
    echo

    for user in "${USERS[@]}"
    do
        HOME_DIR="$(get_home_dir "$user")"

        if [[ -z "$HOME_DIR" || ! -d "$HOME_DIR" ]]; then
            echo "ERROR: Invalid HOME_DIR for user '$user': '$HOME_DIR'" >&2
            exit 1
        fi

        sudo -u "$user" nvim --headless "+Lazy! restore" +qall >/dev/null 2>&1 || true
        echo "Done for $HOME_DIR"
    done
fi

###########################
# Warn If Nvim is Missing #
###########################

if [[ "${NEOVIM_INSTALL_MODE:-auto}" == "skip" ]]; then
    if ! command -v nvim >/dev/null 2>&1; then
        echo
        echo "***************************************"
        echo "* NOTE: Neovim not found in root PATH *"
        echo "* (you passed --skip-neovim)          *"
        echo "***************************************"
        echo
    fi
else
    if ! command -v nvim >/dev/null 2>&1; then
        echo
        echo "*************************************"
        echo "* WARNING: FAILED TO INSTALL NEOVIM *"
        echo "*************************************"
        echo
    fi
fi
