return {
  "hrsh7th/nvim-cmp",
  dependencies = {

    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    -- snippets
    {
      "L3MON4D3/LuaSnip",
      -- follow latest release.
      version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
      -- install jsregexp (optional!).
      build = "make install_jsregexp",
    },
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    "rafamadriz/friendly-snippets", -- useful snippets
    -- managing & installing lsp servers, linters & formatters

    -- configuring lsp servers
    "hrsh7th/cmp-nvim-lsp", -- for autocompletion
    -- additional functionality for typescript server (e.g. rename file & update imports)
    "onsails/lspkind.nvim", -- vs-code like icons for autocompletion
    "kristijanhusak/vim-dadbod-completion", -- add this line for dadbod completion
  },
  config = function()
    -- import nvim-cmp plugin safely
    local cmp_status, cmp = pcall(require, "cmp")
    if not cmp_status then
      return
    end
    -- import luasnip plugin safely
    local luasnip_status, luasnip = pcall(require, "luasnip")
    if not luasnip_status then
      return
    end
    -- import lspkind plugin safely
    local lspkind_status, lspkind = pcall(require, "lspkind")
    if not lspkind_status then
      return
    end
    local source_mapping = {
      buffer = "[Buffer]",
      nvim_lsp = "[LSP]",
      nvim_lua = "[Lua]",
      copilot = "[COP]",
      path = "[Path]",
      luasnip = "[SNP]",
      vim_dadbod_completion = "[DB]", -- add this line for dadbod mapping
    }
    -- load vs-code like snippets from plugins (e.g. friendly-snippets)
    require("luasnip/loaders/from_vscode").lazy_load()
    vim.opt.completeopt = "menu,menuone,noselect"

    cmp.setup({
      completion = {
        completeopt = "noselect",
        autocomplete = false, -- make sure completion is manual
      },

      preselect = cmp.PreselectMode.None,
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<Tab>"] = cmp.mapping.select_next_item(), -- next suggestion
        ["<C-d>"] = cmp.mapping.complete(),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        -- ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
        ["<C-e>"] = cmp.mapping.abort(), -- close completion window
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
      }),
      -- sources for autocompletion
      sources = cmp.config.sources({
        { name = "copilot", max_item_count = 3, score = 5 },
        { name = "nvim_lsp", max_item_count = 20, score = 8 }, -- lsp
        { name = "luasnip", max_item_count = 10, score = 3 }, -- snippets
        { name = "buffer", max_item_count = 10 }, -- text within current buffer
        { name = "path" }, -- file system paths
        { name = "vim-dadbod-completion" }, -- add this line for dadbod source
      }),
      -- -- configure lspkind for vs-code like icons
      formatting = {
        format = function(entry, vim_item)
          -- if you have lspkind installed, you can use it like
          -- in the following line:
          vim_item.kind = lspkind.symbolic(vim_item.kind, { mode = "symbol" })
          vim_item.menu = source_mapping[entry.source.name]
          if entry.source.name == "copilot" then
            vim_item.kind = ""
          end
          local maxwidth = 50
          vim_item.abbr = string.sub(vim_item.abbr, 1, maxwidth)
          return vim_item
        end,
      },
      window = {
        completion = { pumheight = 5 },
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "sql", "mysql", "plsql", "pgsql", "postgres", "postgresql" },
      callback = function()
        cmp.setup.buffer({
          sources = {
            { name = "vim-dadbod-completion" },
            { name = "buffer" },
            { name = "luasnip" },
          },
        })
      end,
    })

    vim.g.copilot_no_tab_map = true
    vim.g.copilot_assume_mapped = true
    vim.g.copilot_tab_fallback = ""
  end,
}
