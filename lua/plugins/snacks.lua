return {
  "folke/snacks.nvim",
  opts = {
    indent = {
      enabled = true,
      filter = function(buf)
        -- Check if 'diff' is active in the current window
        return not vim.wo.diff
      end,
    },
    scope = {
      enabled = true,
      filter = function(buf)
        -- Check if 'diff' is active in the current window
        return not vim.wo.diff
      end,
    },
    picker = {
      sources = {
        --[[
            Snacks Projects does NOT store a list of projects anywhere.
            It will look for them on the fly, every time you open the picker.

            By default, snacks will look for projects in two places:
              1. Recent files
                For any file neovim has recently opened (see vim.v.oldfiles), it will check if the file
                is part of a git repo. If it is, it will add the project to the list of projects.
                Note: patterns are NOT used for this source, it only looks for .git folders.
              2. Dev folders
                You can specify a list of folders where you usually keep your projects.
                Snacks will look for projects in those folders to a depth of max_depth.
                By default, it looks in ~/dev and ~/projects.
                A project is any folder that contains one of the following files: .git, _darcs, .hg, .bzr, .svn, package.json, Makefile, .project.
        --]]
        projects = {
          -- Don't use recent files as a source for projects
          -- I store all useful projects in a short list of folders
          recent = false,
          -- List of folders to look for projects
          dev = { "~/Documents", "~/.config/nvim" },
          -- List of files to look for when identifying a project
          --
          patterns = vim.list_extend(
            -- Default patterns built into snacks
            -- There's no good way to extend the default patterns, so we
            -- have to copy them here
            { ".git", "_darcs", ".hg", ".bzr", ".svn", "package.json", "Makefile" },

            -- My custom addition: I like to use .project files to mark
            -- project roots for projects that aren't git repos
            { ".project" }
          ),
          -- How many levels of subfolders to look into when searching for
          -- projects. Default is 2
          max_depth = 2,
        },
      },
      win = {
        input = {
          keys = {
            -- Key to focus the preview
            ["<c-w>"] = { "focus_preview", mode = { "i", "n" } },
          },
        },
        preview = {
          wo = {
            wrap = true,
            linebreak = true, -- optional, nicer wrapping
          },
        },
      },
    },
  },
}
