return {
  "neovim/nvim-lspconfig",
  config = function()
    local has_lspconfig, lspconfig = pcall(require, "lspconfig")
    if not has_lspconfig then
      return
    end

    local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    local capabilities = has_cmp
        and cmp_nvim_lsp.default_capabilities()
        or vim.lsp.protocol.make_client_capabilities()

    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }

    local function on_attach(client, bufnr)
      client.server_capabilities.semanticTokensProvider = nil
      -- disable semantic tokens if you don't need them
      -- (some people turn it off to reduce flicker)

      local opts = { noremap = true, silent = true, buffer = bufnr }
      vim.keymap.set("n", "<leader>dd", "<Cmd>Telescope diagnostics bufnr=0<CR>", opts)
      vim.keymap.set("n", "<leader>dD", "<Cmd>Telescope diagnostics<CR>", opts)
      vim.keymap.set("n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)
      vim.keymap.set("n", "gi", "<Cmd>lua vim.lsp.buf.implementation()<CR>", opts)
      vim.keymap.set("n", "gr", "<Cmd>lua vim.lsp.buf.declaration()<CR>", opts)
      vim.keymap.set("n", "<leader>ca", "<Cmd>lua vim.lsp.buf.code_action()<CR>", opts)
      vim.keymap.set("n", "<leader>D", "<Cmd>lua vim.diagnostic.open_float()<CR>", opts)
      vim.keymap.set("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
      vim.keymap.set("i", "<C-b>", "<Cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
      vim.keymap.set("n", "<leader>rn", "<Cmd>lua vim.lsp.buf.rename()<CR>", opts)
      vim.keymap.set("n", "gk", "<Cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
      vim.keymap.set("n", "gj", "<Cmd>lua vim.diagnostic.goto_next()<CR>", opts)
    end

    -- Disable duplicate gopls setup by using a guard:
    if not vim.g.gopls_initialized then
      vim.g.gopls_initialized = true

      lspconfig["gopls"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = function(fname)
          return lspconfig.util.root_pattern("go.mod")(fname)
              or lspconfig.util.find_git_ancestor(fname)
        end,
      })
    end


    -- Typescript (ts_ls) — disable formatting so none-ls (Prettier) takes over:
    if not vim.g.ts_ls_initialized then
      vim.g.ts_ls_initialized = true

      lspconfig["ts_ls"].setup({
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          -- disable ts_ls formatting (none-ls will do Prettier)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
          on_attach(client, bufnr)
        end,
        root_dir = function(fname)
          return lspconfig.util.root_pattern(
                "tsconfig.json",
                "jsconfig.json",
                "package.json",
                ".git"
              )(fname)
              or lspconfig.util.find_git_ancestor(fname)
        end,
      })
    end

    -- HTML:
    lspconfig["html"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { "html", "templ" },
    })

    -- CSS:
    lspconfig["cssls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- Tailwind (make sure to pass lowercase `capabilities`, not `Capabilities`):
    lspconfig.tailwindcss.setup({
      capabilities = capabilities,
      filetypes = {
        "css", "scss", "sass", "postcss", "html",
        "javascript", "javascriptreact", "typescript", "typescriptreact",
        "svelte", "vue", "rust", "templ",
      },
      init_options = {
        userLanguages = { rust = "html", templ = "html" },
      },
      root_dir = lspconfig.util.root_pattern(
        "tailwind.config.js", "tailwind.config.ts",
        "postcss.config.js", "postcss.config.ts", "windi.config.ts"
      ),
    })

    -- htmx:
    lspconfig["htmx"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { "html", "templ" },
    })

    -- Templ (your .templ files):
    lspconfig["templ"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.templ",
      callback = function() vim.lsp.buf.format() end,
    })

    -- Rust:
    lspconfig.rust_analyzer.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      cmd = { "rustup", "run", "stable", "rust-analyzer" },
      settings = {
        ["rust-analyzer"] = {
          cargo = { allFeatures = true },
        },
      },
    })
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.rs",
      callback = function() vim.lsp.buf.format() end,
    })

    -- Python:
    lspconfig["pylsp"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- Svelte:
    lspconfig["svelte"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- YAML:
    lspconfig["yamlls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = { yaml = { keyOrdering = false } },
    })

    -- JSON:
    lspconfig["jsonls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- Docker:
    lspconfig["dockerls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- C/C++:
    lspconfig["clangd"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.cpp", "*.c", "*.h" },
      callback = function() vim.lsp.buf.format() end,
    })

    -- Perl:
    lspconfig.perlnavigator.setup({
      cmd = { "perlnavigator", "--stdio" },
      capabilities = capabilities,
      on_attach = on_attach,
    })
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.pl",
      callback = function() vim.lsp.buf.format() end,
    })

    -- Lua:
    lspconfig["lua_ls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          workspace = {
            library = {
              [vim.fn.expand("$VIMRUNTIME/lua")] = true,
              [vim.fn.stdpath("config") .. "/lua"] = true,
            },
          },
        },
      },
    })
  end,
}
