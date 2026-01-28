return {
    "milanglacier/minuet-ai.nvim",
    enabled = false, -- Disabled LLM autocomplete
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        require("minuet").setup({
            provider = "claude",
            provider_options = {
                claude = {
                    model = "claude-haiku-4-5-20251001",
                    max_tokens = 512,
                },
            },
            virtualtext = {
                auto_trigger_ft = { "*" },
                keymap = {
                    accept = "<Tab>",
                    dismiss = "<C-]>",
                },
            },
        })
    end,
}
