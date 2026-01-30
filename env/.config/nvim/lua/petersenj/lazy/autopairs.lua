return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = {
        "hrsh7th/nvim-cmp",
    },

    config = function()
        local autopairs = require("nvim-autopairs")
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        local cmp = require("cmp")

        autopairs.setup({
            check_ts = true, -- Use treesitter to check for pairs
            ts_config = {
                lua = { "string", "source" }, -- Don't add pairs in lua string treesitter nodes
                javascript = { "string", "template_string" },
                python = { "string" },
            },
            disable_filetype = { "TelescopePrompt", "spectre_panel" },
            fast_wrap = {
                map = "<M-e>", -- Alt+e to fast wrap
                chars = { "{", "[", "(", '"', "'" },
                pattern = [=[[%'%"%>%]%)%}%,]]=],
                end_key = "$",
                before_key = "h",
                after_key = "l",
                cursor_pos_before = true,
                keys = "qwertyuiopzxcvbnmasdfghjkl",
                manual_position = true,
                highlight = "Search",
                highlight_grey = "Comment",
            },
        })

        -- Integrate with nvim-cmp: insert `(` after selecting function/method
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
}
