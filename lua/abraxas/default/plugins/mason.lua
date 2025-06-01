return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = {
    {
      "williamboman/mason.nvim",
      config = function()
        local mason_status, mason = pcall(require, "mason")
        if not mason_status then
          return
        end
        mason.setup()
      end,
    },
    {
      -- Changed to none-ls compatible bridge
      "jay-babu/mason-null-ls.nvim", -- Updated plugin name
      config = function()
        local mason_none_ls_status, mason_none_ls = pcall(require, "mason-null-ls")
        if not mason_none_ls_status then
          return
        end

        mason_none_ls.setup({
          ensure_installed = {
            "prettier",
            "stylua",
            "eslint_d",
            "flake8",
            "black",
            "phpcsfixer",
          },
          automatic_installation = true,
        })
      end,
    },
  },
  config = function()
    local mason_lspconfig_status, mason_lspconfig = pcall(require, "mason-lspconfig")
    if not mason_lspconfig_status then
      return
    end

    mason_lspconfig.setup({
      ensure_installed = {
        "html",
        "cssls",
        "tailwindcss",
        "lua_ls",
        "gopls",
        "ts_ls", -- still required; it's reused under the hood
        "rust_analyzer",
        "pylsp",
        "svelte",
        "yamlls",
        "jsonls",
        "dockerls",
        "clangd",
      },
      -- Disable automatic lspconfig.setup for these servers,
      -- so ts_ls (and others) are only configured manually in your lsconfig.lua
      automatic_installation = false,
    })
  end,
}
