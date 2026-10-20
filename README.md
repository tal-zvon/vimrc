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

### Plugins

Managed plugins prefer their latest stable SemVer release. Plugins without
stable tags follow their upstream branch. Explicit LazyVim compatibility
branches and pins take precedence, notably for Tree-sitter.

Before updating, save a copy of `lazy-lock.json` outside this repository.
Run `:Lazy update`, then restart Neovim. To reproduce the versions in an
existing lockfile, run `:Lazy restore` instead. For rollback, put the saved
lockfile back, run `:Lazy restore`, restart Neovim, and run `:TSUpdate` so
parsers match the restored Tree-sitter version.

Mason's plugins are included in plugin updates, but its installed language
servers, formatters, and linters are managed separately.

If `lazy-lock.json` is marked `skip-worktree`, Git hides its local changes.
To publish a shared lockfile update, temporarily clear that flag:

```bash
git update-index --no-skip-worktree lazy-lock.json
git diff -- lazy-lock.json
```

After reviewing and committing the intended lockfile changes, restore the flag
if needed for local plugins:

```bash
git update-index --skip-worktree lazy-lock.json
```

### Configuration repository

Config repository auto updates are handled by `update_git_repo.lua`.
These are separate from plugin updates; Lazy's checker only checks for newer
plugins and does not install them automatically.
The repository check runs at most once per hour, on vim startup.
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
