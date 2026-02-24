return {
    "lewis6991/gitsigns.nvim",
    config = function()
        require("gitsigns").setup({
            signs = {
                add          = { text = "│" },
                change       = { text = "│" },
                delete       = { text = "_" },
                topdelete    = { text = "‾" },
                changedelete = { text = "~" },
            },
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns
                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end
                -- Navigation between hunks
                map("n", "]c", gs.next_hunk)
                map("n", "[c", gs.prev_hunk)
                -- Preview hunk inline
                map("n", "<leader>hp", gs.preview_hunk)
                -- Blame current line
                map("n", "<leader>hb", gs.blame_line)
            end,
        })
    end,
}
