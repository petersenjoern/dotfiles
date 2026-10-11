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
                local gitsigns = require("gitsigns")
                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end
                -- Navigation between hunks
                map("n", "]c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gitsigns.nav_hunk("next")
                    end
                end)
                map("n", "[c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gitsigns.nav_hunk("prev")
                    end
                end)
                -- Preview hunk (floating window)
                map("n", "<leader>hp", gitsigns.preview_hunk)
                -- If you meant inline, you can use this instead:
                -- map("n", "<leader>hp", gitsigns.preview_hunk_inline)

                -- Blame current line
                map("n", "<leader>hb", gitsigns.blame_line)

                -- Counts commits touching this file, not merges on master, so N matches `tig <file>`.
                local function base_n_commits_back(n)
                    local file = vim.api.nvim_buf_get_name(bufnr)
                    if file == "" then return nil end
                    local dir = vim.fn.fnamemodify(file, ":h")
                    local revs = vim.fn.systemlist({
                        "git", "-C", dir, "log", "--format=%H",
                        "-n", tostring(n + 1), "--follow", "--", file,
                    })
                    if vim.v.shell_error ~= 0 or #revs == 0 then return nil end
                    if #revs > n then return revs[#revs] end
                    -- File is younger than N commits, so diff against before it existed
                    local parent = revs[#revs] .. "^"
                    vim.fn.system({ "git", "-C", dir, "rev-parse", "--verify", "--quiet", parent })
                    return vim.v.shell_error == 0 and parent or revs[#revs]
                end

                -- Reviewing in the live buffer means ]c walks only what those commits touched
                map("n", "<leader>hD", function()
                    vim.ui.input({ prompt = "Review last N commits to this file: ", default = "5" }, function(input)
                        local n = tonumber(input)
                        if not n then return end
                        local base = base_n_commits_back(n)
                        if not base then
                            vim.notify("No git history for this file", vim.log.levels.WARN)
                            return
                        end
                        gitsigns.change_base(base)
                        vim.notify(("Diff base: %s (%d commits back)"):format(base:sub(1, 8), n))
                    end)
                end, { desc = "Review last N commits to file" })

                map("n", "<leader>hR", function()
                    gitsigns.change_base(nil)
                    vim.notify("Diff base: index")
                end, { desc = "Reset diff base" })

                map("n", "<leader>hq", function()
                    gitsigns.setqflist()
                end, { desc = "Hunks to quickfix" })
            end,
        })
    end,
}
