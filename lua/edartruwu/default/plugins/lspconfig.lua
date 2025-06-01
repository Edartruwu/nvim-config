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

    -- Custom go-to-definition that jumps directly without opening lists
    local function goto_definition()
      local params = vim.lsp.util.make_position_params(0, "utf-8")

      vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result)
        if err or not result or vim.tbl_isempty(result) then
          return
        end

        -- If single result, jump directly
        if #result == 1 then
          vim.lsp.util.show_document(result[1], 'utf-8', {focus = true})
        else
          -- Multiple results - filter out duplicates and jump to first unique one
          local unique_locations = {}
          local seen = {}

          for _, location in ipairs(result) do
            local key = location.uri .. ":" .. location.range.start.line .. ":" .. location.range.start.character
            if not seen[key] then
              seen[key] = true
              table.insert(unique_locations, location)
            end
          end

          if #unique_locations == 1 then
            vim.lsp.util.show_document(unique_locations[1], 'utf-8', {focus = true})
          else
            -- Multiple unique locations - use default behavior (show list)
            vim.lsp.buf.definition()
          end
        end
      end)
    end

    -- TypeScript-specific hover that forces ts_ls to respond
    local function typescript_hover()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      local ts_client = nil

      -- Find specifically the TypeScript client
      for _, client in pairs(clients) do
        if client.name == "ts_ls" then
          ts_client = client
          break
        end
      end

      if not ts_client then
        return
      end

      local params = vim.lsp.util.make_position_params(0, "utf-8")

      -- Send hover request specifically to TypeScript LSP
      ts_client.request('textDocument/hover', params, function(err, result, ctx, config)
        if err then
          return
        end

        if not result or not result.contents then
          return
        end

        -- Use the fixed hover handler we set up earlier
        vim.lsp.handlers['textDocument/hover'](err, result, ctx, config)
      end, 0)
    end

    -- FIX HOVER: Override hover handler to fix floating window issues
    local function setup_fixed_hover()
      local original_handler = vim.lsp.handlers['textDocument/hover']

      vim.lsp.handlers['textDocument/hover'] = function(err, result, ctx, config)
        if err or not result or not result.contents then
          return original_handler(err, result, ctx, config)
        end

        -- Fix config to prevent floating window errors
        local fixed_config = config or {}
        fixed_config.border = fixed_config.border or 'rounded'
        fixed_config.max_width = fixed_config.max_width or 80
        fixed_config.max_height = fixed_config.max_height or 20
        fixed_config.focus = false
        fixed_config.close_events = fixed_config.close_events or { "CursorMoved", "BufHidden", "InsertCharPre" }

        -- Remove invalid width/height values
        if fixed_config.width and (type(fixed_config.width) ~= "number" or fixed_config.width <= 0) then
          fixed_config.width = nil
        end
        if fixed_config.height and (type(fixed_config.height) ~= "number" or fixed_config.height <= 0) then
          fixed_config.height = nil
        end

        return original_handler(err, result, ctx, fixed_config)
      end
    end

    -- Apply the hover fix
    setup_fixed_hover()

    local function on_attach(client, bufnr)
      client.server_capabilities.semanticTokensProvider = nil

      local opts = { noremap = true, silent = true, buffer = bufnr }

      -- FIXED DIAGNOSTIC KEYMAPS:
      -- Shift+D (just "D") = inspect current diagnostic
      vim.keymap.set("n", "D", vim.diagnostic.open_float, opts)
      -- <space>dd = show ALL diagnostics in telescope
      vim.keymap.set("n", "<leader>dd", "<Cmd>Telescope diagnostics<CR>", opts)
      -- <space>dD = show diagnostics for current buffer only
      vim.keymap.set("n", "<leader>dD", "<Cmd>Telescope diagnostics bufnr=0<CR>", opts)

      -- LSP NAVIGATION KEYMAPS (FIXED):
      vim.keymap.set("n", "gd", goto_definition, opts)
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
      vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts) -- Now fixed!
      vim.keymap.set("i", "<C-b>", vim.lsp.buf.signature_help, opts)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "gk", vim.diagnostic.goto_prev, opts)
      vim.keymap.set("n", "gj", vim.diagnostic.goto_next, opts)
    end

    -- REMOVE GUARDS - they cause problems with config reloading
    -- Go setup
    lspconfig.gopls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      root_dir = function(fname)
        return lspconfig.util.root_pattern("go.mod")(fname)
            or lspconfig.util.find_git_ancestor(fname)
      end,
    })

    -- TypeScript setup - CLEAN, NO GUARDS
    lspconfig.ts_ls.setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        -- disable ts_ls formatting (none-ls will do Prettier)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false

        -- Set up base keymaps
        local opts = { noremap = true, silent = true, buffer = bufnr }

        -- DIAGNOSTIC KEYMAPS
        vim.keymap.set("n", "D", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "<leader>dd", "<Cmd>Telescope diagnostics<CR>", opts)
        vim.keymap.set("n", "<leader>dD", "<Cmd>Telescope diagnostics bufnr=0<CR>", opts)

        -- LSP NAVIGATION KEYMAPS
        vim.keymap.set("n", "gd", goto_definition, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("i", "<C-b>", vim.lsp.buf.signature_help, opts)
        vim.keymap.set("n", "gk", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "gj", vim.diagnostic.goto_next, opts)

        -- TYPESCRIPT-SPECIFIC HOVER - forces ts_ls to respond
        vim.keymap.set("n", "K", typescript_hover, opts)
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
      filetypes = {
        "typescript",
        "typescriptreact",
        "javascript",
        "javascriptreact"
      },
    })

    -- HTML
    lspconfig.html.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { "html", "templ" },
    })

    -- CSS
    lspconfig.cssls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- Tailwind (disable hover for TypeScript files to avoid conflicts)
    lspconfig.tailwindcss.setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        -- Disable hover for Tailwind on TypeScript files to let ts_ls handle it
        local filetype = vim.bo[bufnr].filetype
        if filetype == "typescript" or filetype == "typescriptreact" or
           filetype == "javascript" or filetype == "javascriptreact" then
          client.server_capabilities.hoverProvider = false
        end
        on_attach(client, bufnr)
      end,
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

    -- htmx (limit to HTML/templ only to avoid TS conflicts)
    lspconfig.htmx.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { "html", "templ" }, -- Remove JS/TS filetypes to avoid conflicts
    })

    -- Templ
    lspconfig.templ.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.templ",
      callback = function() vim.lsp.buf.format() end,
    })

    -- Rust
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

    -- Python
    lspconfig.pylsp.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- Svelte
    lspconfig.svelte.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- YAML
    lspconfig.yamlls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = { yaml = { keyOrdering = false } },
    })

    -- JSON
    lspconfig.jsonls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- Docker
    lspconfig.dockerls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- C/C++
    lspconfig.clangd.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.cpp", "*.c", "*.h" },
      callback = function() vim.lsp.buf.format() end,
    })

    -- Perl
    lspconfig.perlnavigator.setup({
      cmd = { "perlnavigator", "--stdio" },
      capabilities = capabilities,
      on_attach = on_attach,
    })
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.pl",
      callback = function() vim.lsp.buf.format() end,
    })

    -- Lua
    lspconfig.lua_ls.setup({
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

    -- Emergency fallback for TypeScript files
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
      callback = function(args)
        vim.defer_fn(function()
          local buf = args.buf

          -- Ensure TypeScript-specific hover is set
          vim.keymap.set("n", "K", typescript_hover, {
            buffer = buf,
            silent = true,
            desc = "TypeScript hover (fallback)"
          })

          vim.keymap.set("n", "D", vim.diagnostic.open_float, {
            buffer = buf,
            silent = true,
            desc = "Diagnostic float (fallback)"
          })

          -- Alternative hover keymap
          vim.keymap.set("n", "<leader>h", typescript_hover, {
            buffer = buf,
            silent = true,
            desc = "TypeScript hover (alternative)"
          })
        end, 1000)
      end,
    })
  end,
}
