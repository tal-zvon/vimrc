-- Folding is handled by Neovim's native treesitter folds, not nvim-ufo.
--
-- LazyVim already wires native folding (foldmethod=expr +
-- vim.treesitter.foldexpr) via its treesitter setup; nvim-ufo was overriding
-- it with foldmethod=manual. Native (real) folds make recursive fold commands
-- (zo/zO, zc/zC, zr/zm) behave correctly out of the box.
--
-- zO/zC are further customized into a two-tier "outer layer" behavior (operate
-- on the enclosing method, or the class when not inside a method) -- see
-- lua/plugins/utils/folding.lua.
--
-- Related config:
--   * fold options ............. lua/config/options.lua
--   * custom foldtext + zR/zM ... lua/plugins/utils/folding.lua
--   * zR/zM, zO/zC keymaps ...... lua/config/keymaps.lua
return {
  { "kevinhwang91/nvim-ufo", enabled = false },
  { "kevinhwang91/promise-async", enabled = false },
}
