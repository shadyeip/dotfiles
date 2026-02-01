-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 8
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.updatetime = 250
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.wrap = false
vim.opt.cursorline = true

-- Leader
vim.g.mapleader = " "

-- Plugins
require("lazy").setup({
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({})

      -- Incremental selection keymaps
      vim.keymap.set("n", "<C-Space>", function()
        require("nvim-treesitter.incremental_selection").init_selection()
      end, { desc = "Start treesitter selection" })
      vim.keymap.set("v", "<C-Space>", function()
        require("nvim-treesitter.incremental_selection").node_incremental()
      end, { desc = "Expand treesitter selection" })
      vim.keymap.set("v", "<BS>", function()
        require("nvim-treesitter.incremental_selection").node_decremental()
      end, { desc = "Shrink treesitter selection" })
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
})
