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
      "jay-babu/mason-null-ls.nvim",
      config = function()
        local mason_none_ls_status, mason_none_ls = pcall(require, "mason-null-ls")
        if not mason_none_ls_status then
          return
        end

        mason_none_ls.setup({
          ensure_installed = {
            -- Formatters
            "prettier", -- JS/TS/HTML/CSS/JSON formatter
            "stylua", -- Lua formatter
            "black", -- Python formatter
            "phpcsfixer", -- PHP formatter
            "gofumpt", -- Go formatter (better than gofmt)
            "goimports", -- Go imports formatter
            -- Linters (add these gradually after formatters work)
            -- "eslint_d",     -- Fast ESLint
            -- "pylint",       -- Python linter
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
        "ts_ls",
        "rust_analyzer",
        "pylsp",
        "svelte",
        "yamlls",
        "jsonls",
        "dockerls",
        "clangd",
      },
      automatic_installation = false,
    })
  end,
}
