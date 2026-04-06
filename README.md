# My neovim config

Automatically installs LazyVim, and any plugins I need before configuring
them.

## Install

```bash
curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/tal-zvon/vimrc/master/install.sh | sudo bash -s --
```

## Install without Neovim

If you've already installed neovim manually (ex from tar.gz if your
distro's package manager has a version that's too old), you can run this instead:

```bash
curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/tal-zvon/vimrc/master/install.sh | sudo bash -s -- --skip-neovim
```

## Install local plugins

If you want to install plugins locally that you don't want to commit to
the git repo, you can add spec files to `lua/local_plugins/`. They look
and work exactly the same as the specs in `lua/plugins/`, but are ignored
by `.gitignore`. That's the only difference.

You'll also need to run:

```bash
git update-index --skip-worktree lazy-lock.json
```

So when your lock file changes, your auto-updater doesn't freak out
that your directory is dirty

## Code organization

- `lua/config/` contains core editor configuration modules.
- `lua/startup_scripts/` contains startup-time scripts/services.
- `lua/plugins/` contains plugin spec files.
- `lua/plugins/utils/` contains larger helper functions used by plugin specs.

## Install Tree-sitter on older Linux Servers

If Mason fails to install Tree-sitter on an older server, like Rocky Linux,
because your GLIBC is too old, you can install it manually:

```bash
cargo install tree-sitter-cli
```

Cargo will compile it for your system. Mason will automatically detect it,
and won't try to install it anymore.

## Updates

Auto updates are handled by a custom script: `update_git_repo.lua`.
It runs at most once per hour, on vim startup.
To see debug messages from it, run:

```bash
NVIM_VIMRC_AUTO_UPDATE_DEBUG=1 nvim
```

OR

```
:lua vim.g.vimrc_auto_update_debug = true
:lua require("startup_scripts.update_git_repo").check_for_updates()
```

To force updates without waiting an hour, delete its state file:

```bash
rm -f ~/.local/state/nvim/vimrc_auto_update.json
```

Then run neovim again

## Formatting

Run:

```bash
find . -iname "*.lua" \
    -exec ~/.local/share/nvim/mason/bin/stylua \
    --indent-type=spaces \
    --indent-width=2 {} \;
```
