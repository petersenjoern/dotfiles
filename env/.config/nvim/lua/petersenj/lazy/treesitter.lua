return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            -- Install parsers
            require("nvim-treesitter").install({
                "vimdoc", "javascript", "typescript", "c", "lua",
                "rust", "python", "jsdoc", "bash", "templ"
            })

            -- Enable highlighting per filetype with your customizations
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    local buf = args.buf
                    local ft = vim.bo[buf].filetype

                    -- Disable for HTML
                    if ft == "html" then
                        print("disabled")
                        return
                    end

                    -- Disable for large files (>100KB)
                    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
                    if ok and stats and stats.size > 100 * 1024 then
                        vim.notify(
                            "File larger than 100KB treesitter disabled for performance",
                            vim.log.levels.WARN,
                            { title = "Treesitter" }
                        )
                        return
                    end

                    -- Enable treesitter highlighting (silently skip if no parser exists)
                    local ok = pcall(vim.treesitter.start)
                    if not ok then
                        return
                    end

                    -- Enable treesitter indentation
                    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

                    -- Additional vim regex highlighting for markdown
                    if ft == "markdown" then
                        vim.bo[buf].syntax = "on"
                    end
                end,
            })

            -- Register templ filetype
            vim.treesitter.language.register("templ", "templ")
        end
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            require("treesitter-context").setup({
                enable = true,
                multiwindow = false,
                max_lines = 0,
                min_window_height = 0,
                line_numbers = true,
                multiline_threshold = 20,
                trim_scope = "outer",
                mode = "cursor",
                separator = nil,
                zindex = 20,
                on_attach = nil,
            })
        end
    },

    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            local ts_select = require("nvim-treesitter-textobjects.select")
            local ts_move = require("nvim-treesitter-textobjects.move")

            -- Selection keymaps (visual and operator-pending modes)
            local select_maps = {
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",
                ["aa"] = "@parameter.outer",
                ["ia"] = "@parameter.inner",
            }

            for key, query in pairs(select_maps) do
                vim.keymap.set({ "x", "o" }, key, function()
                    ts_select.select_textobject(query, "textobjects", { lookahead = true })
                end, { desc = "Select " .. query })
            end

            -- Movement keymaps
            local move_maps = {
                ["]m"] = { query = "@function.outer", func = ts_move.goto_next_start },
                ["]c"] = { query = "@class.outer", func = ts_move.goto_next_start },
                ["]M"] = { query = "@function.outer", func = ts_move.goto_next_end },
                ["]C"] = { query = "@class.outer", func = ts_move.goto_next_end },
                ["[m"] = { query = "@function.outer", func = ts_move.goto_previous_start },
                ["[c"] = { query = "@class.outer", func = ts_move.goto_previous_start },
                ["[M"] = { query = "@function.outer", func = ts_move.goto_previous_end },
                ["[C"] = { query = "@class.outer", func = ts_move.goto_previous_end },
            }

            for key, opts in pairs(move_maps) do
                vim.keymap.set({ "n", "x", "o" }, key, function()
                    opts.func(opts.query, "textobjects")
                end, { desc = "Go to " .. opts.query })
            end
        end,
    },
}
