return {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },

    config = function()
        require("Comment").setup({
            -- Add a space between comment and line
            padding = true,
            -- Whether cursor should stay at its position
            sticky = true,
            -- Lines to be ignored while (un)comment
            ignore = "^$", -- ignore empty lines
            -- LHS of toggle mappings in NORMAL mode
            toggler = {
                line = "gcc",  -- Line-comment toggle
                block = "gbc", -- Block-comment toggle
            },
            -- LHS of operator-pending mappings in NORMAL and VISUAL mode
            opleader = {
                line = "gc",  -- Line-comment
                block = "gb", -- Block-comment
            },
            -- LHS of extra mappings
            extra = {
                above = "gcO", -- Add comment on the line above
                below = "gco", -- Add comment on the line below
                eol = "gcA",   -- Add comment at end of line
            },
            -- Enable keybindings
            mappings = {
                basic = true,
                extra = true,
            },
        })
    end,
}
