-- Claude Code scratchpads (see env/.local/scripts/claude-scratch).
--
-- :Scratch      telescope over every scratchpad session of the current project
-- :ScratchLast  open the file Claude wrote most recently
--
-- Both render from the script's `meta` output, which is the same newest-first
-- list `pick` feeds to fzf. Letting telescope re-glob the dirs itself looked
-- equivalent but sorted alphabetically, so the top hit was whatever came first
-- in the directory -- in one project, a .parquet dump.

local ROOT = vim.env.CLAUDE_SCRATCH_ROOT or ("/tmp/claude-" .. (vim.uv or vim.loop).getuid())

local function claude_scratch(args)
    local out = vim.fn.systemlist(vim.list_extend({ "claude-scratch" }, args))
    if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
        vim.notify("no Claude scratchpad for " .. vim.fn.getcwd(), vim.log.levels.WARN)
        return nil
    end
    return out
end

local function entries()
    local out = claude_scratch({ "meta" })
    if not out then return nil end
    local list = {}
    for _, line in ipairs(out) do
        local when, size, session, name, path = line:match("^(.-)\t(.-)\t(.-)\t(.-)\t(.+)$")
        if path then
            list[#list + 1] = {
                value = path,
                path = path,
                display = string.format("%-11s %6s  %-8s  %s", when, size, session, name),
                ordinal = name, -- match on the name only, like fzf's --nth=4
            }
        end
    end
    return list
end

vim.api.nvim_create_user_command("Scratch", function()
    local list = entries()
    if not list or #list == 0 then return end
    local conf = require("telescope.config").values
    require("telescope.pickers")
        .new({}, {
            prompt_title = "Claude scratch",
            finder = require("telescope.finders").new_table({
                results = list,
                entry_maker = function(entry) return entry end,
            }),
            -- No sorter shuffling on an empty prompt, so the list opens newest-first.
            sorter = conf.generic_sorter({}),
            previewer = conf.file_previewer({}),
        })
        :find()
end, { desc = "Pick a Claude scratch file" })

vim.api.nvim_create_user_command("ScratchLast", function()
    local out = claude_scratch({ "newest" })
    if out then
        vim.cmd.edit(vim.fn.fnameescape(out[1]))
    end
end, { desc = "Open the newest Claude scratch file" })

-- Claude rewrites these files while they are open; follow the file on disk
-- instead of showing a stale buffer.
vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("ClaudeScratch", {}),
    pattern = ROOT .. "/*",
    callback = function(event)
        vim.bo[event.buf].autoread = true
        vim.cmd("silent! checktime")
    end,
})

vim.keymap.set("n", "<leader>cs", "<cmd>Scratch<CR>", { desc = "Claude scratch files" })
vim.keymap.set("n", "<leader>cS", "<cmd>ScratchLast<CR>", { desc = "Newest Claude scratch file" })
