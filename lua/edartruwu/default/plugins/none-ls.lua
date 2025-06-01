return {
  "nvimtools/none-ls.nvim",
  config = function()
    -- import null-ls plugin safely
    local setup, null_ls = pcall(require, "null-ls")
    if not setup then
      print("Failed to load null-ls")
      return
    end

    vim.diagnostic.config({
      virtual_text = false,
      underline = false,
    })

    -- for conciseness
    local formatting = null_ls.builtins.formatting

    -- to setup format on save
    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

    -- Build sources table with commonly available builtins
    local sources = {}

    -- Prettier - make it less restrictive, work for more projects
    if formatting.prettier then
      table.insert(
        sources,
        formatting.prettier.with({
          filetypes = {
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "json",
            "jsonc",
            "html",
            "css",
            "scss",
            "markdown",
            "yaml",
            "yml",
          },
          -- More permissive condition - run if any common config exists OR if it's a typical web project
          condition = function(utils)
            return utils.root_has_file({
              ".prettierrc",
              ".prettierrc.js",
              ".prettierrc.json",
              "prettier.config.js",
              "package.json",
              "tsconfig.json",
              ".git", -- Run in any git project as fallback
            })
          end,
        })
      )
    end

    -- Go formatter - very important for your Go files
    if formatting.gofmt then
      table.insert(sources, formatting.gofmt)
    elseif formatting.gofumpt then
      table.insert(sources, formatting.gofumpt) -- Better than gofmt
    elseif formatting.goimports then
      table.insert(sources, formatting.goimports) -- Handles imports too
    end

    -- Lua formatter
    if formatting.stylua then
      table.insert(sources, formatting.stylua)
    end

    -- Python formatter
    if formatting.black then
      table.insert(
        sources,
        formatting.black.with({
          extra_args = { "--line-length", "80" },
        })
      )
    end

    -- PHP formatter
    if formatting.phpcsfixer then
      table.insert(
        sources,
        formatting.phpcsfixer.with({
          extra_args = { "--rules", "@Symfony" },
        })
      )
    end

    -- configure null_ls with minimal sources
    null_ls.setup({
      sources = sources,
      -- configure format on save
      on_attach = function(current_client, bufnr)
        if current_client.supports_method("textDocument/formatting") then
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({
                filter = function(client)
                  return client.name == "null-ls"
                end,
                bufnr = bufnr,
              })
            end,
          })
        end
      end,
    })
  end,
}
