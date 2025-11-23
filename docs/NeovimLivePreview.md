## Neovim Live Preview Flow

This is a lightweight workflow so you can edit a view in one Neovim pane while a second pane continuously re-renders the matching preview using `SwifTeaPreviewDemo`. It does not require saving the file—edits trigger previews immediately.

### 1. Seed Buffer-Local Preview Names

Set the preview name once per Swift buffer (e.g., in `after/ftplugin/swift.lua`):

```lua
-- after/ftplugin/swift.lua
vim.b.preview_name = "Hello World"   -- or "Counter Demo"
```

You can change the string per file, or add a tiny helper to look at the file path and pick a default when the buffer opens.

### 2. Neovim Lua Snippet

Add this to `init.lua` (or a plugin) to keep a dedicated preview split updated on every edit:

```lua
local M = {}

local preview_buf = nil
local preview_win = nil
local preview_job = nil
local pending_timer = nil

local function project_root()
    local bufname = vim.api.nvim_buf_get_name(0)
    local start = bufname ~= "" and vim.fs.dirname(bufname) or vim.fn.getcwd()
    local found = vim.fs.find("Package.swift", {
        path = start,
        upward = true,
        stop = vim.loop.os_homedir(),
    })
    if #found > 0 then
        return vim.fs.dirname(found[1])
    end
    return vim.fn.getcwd()
end

local function paths()
    local root = project_root()
    local shadow_root = vim.fs.joinpath(root, ".swiftea-preview")
    local scratch_path = vim.fs.joinpath(shadow_root, ".build-nvim")
    return root, shadow_root, scratch_path
end

local function sync_shadow_package()
    local root, shadow_root = paths()
    if vim.fn.isdirectory(shadow_root) == 0 then
        vim.fn.mkdir(shadow_root, "p")
    end

    -- Keep the shadow copy in sync on every render so other file changes are picked up.
    vim.fn.system({
        "rsync",
        "-a",
        "--delete",
        "--include",
        "Package.swift",
        "--include",
        "Package.resolved",
        "--include",
        "Sources/***",
        "--include",
        "Tests/***",
        "--include",
        "Examples/***",
        "--include",
        "docs/***",
        "--exclude",
        ".git",
        "--exclude",
        ".build",
        "--exclude",
        ".build-nvim",
        "--exclude",
        ".swiftea-preview",
        "--exclude",
        "*",
        root .. "/",
        shadow_root .. "/",
    })
end

local function write_buffer_snapshot()
    local root, shadow_root = paths()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname == "" then
        return nil
    end

    local abs = vim.fn.fnamemodify(bufname, ":p")
    if abs:sub(1, #root) ~= root then
        return nil
    end
    local rel = abs:sub(#root + 2) -- drop leading slash

    local target = vim.fs.joinpath(shadow_root, rel)
    vim.fn.mkdir(vim.fs.dirname(target), "p")
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    vim.fn.writefile(lines, target)
    return target
end

local function ensure_preview_window()
    -- If a terminal buffer from a previous run is still around, wipe it so we
    -- can write into a fresh scratch buffer.
    if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
        local buftype = vim.api.nvim_buf_get_option(preview_buf, "buftype")
        if buftype == "terminal" then
            pcall(vim.api.nvim_buf_delete, preview_buf, { force = true })
            preview_buf = nil
        end
    end

    -- If the window still exists, just reuse it.
    if preview_win and vim.api.nvim_win_is_valid(preview_win) then
        if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
            if vim.api.nvim_win_get_buf(preview_win) ~= preview_buf then
                vim.api.nvim_win_set_buf(preview_win, preview_buf)
            end
            return preview_buf, preview_win
        end
    end

    -- Recreate the buffer if it was wiped.
    preview_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[preview_buf].bufhidden = "hide"
    vim.bo[preview_buf].swapfile = false
    vim.bo[preview_buf].modifiable = true

    -- Recreate the window if it was closed.
    vim.cmd("botright vsplit")
    preview_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(preview_win, preview_buf)

    return preview_buf, preview_win
end

local function start_preview_job(preview_name)
    local shadow_root, scratch_path
    do
        local _, sroot, spath = paths()
        shadow_root = sroot
        scratch_path = spath
    end

    if preview_job then
        local old = preview_job
        vim.fn.jobstop(old)
        vim.fn.jobwait({ old }, 500) -- wait briefly so SwiftPM build lock clears
        preview_job = nil
    end

    local prev_win = vim.api.nvim_get_current_win() -- remember active window
    local buffer, win = ensure_preview_window()

    -- Temporarily focus the preview window to run termopen there.
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_buf_set_option(buffer, "modifiable", true)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {})
    vim.api.nvim_buf_set_option(buffer, "modified", false)

    sync_shadow_package()
    write_buffer_snapshot()

    preview_job = vim.fn.termopen({
        "swift",
        "run",
        "--package-path",
        shadow_root,
        "--scratch-path",
        scratch_path,
        "--skip-update", -- avoid re-fetching dependencies on each refresh
        "SwifTeaPreviewDemo",
        "--preview",
        preview_name,
    }, {
        on_exit = function()
            preview_job = nil
        end,
    })

    vim.cmd("startinsert")
    if vim.api.nvim_win_is_valid(prev_win) then
        vim.api.nvim_set_current_win(prev_win) -- return focus to original pane
    end
end

local function render_preview()
    local preview = vim.b.preview_name
    if not preview or preview == "" then
        return
    end
    start_preview_job(preview)
end

function M.setup()
    -- Render on write to avoid thrashing during fast edits.
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        pattern = { "*.swift" },
        callback = render_preview,
    })

    vim.keymap.set("n", "<leader>pp", function()
        if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
            vim.api.nvim_set_current_buf(preview_buf)
        else
            vim.notify("Preview buffer not ready", vim.log.levels.WARN)
        end
    end, { desc = "Focus preview buffer" })
end

return M```

How it works:
- Every edit in a Swift buffer triggers `render_preview`.
- The job runs `swift run SwifTeaPreviewDemo --preview <buffer name>`.
- Output replaces all lines in the preview split, so the pane stays “fresh”.
- If compilation fails mid-edit, the stderr callback prints the compiler error in the same split. As soon as the code compiles again, the next edit replaces it with the rendered frame.

### 3. Usage Notes

- For now you must set `vim.b.preview_name` for each file you want to preview (or add logic that inspects the file path and derives a default).
- The preview split is read-only; use `<leader>pp` to switch focus to it quickly.
- Because this runs `swift run` behind the scenes, you’ll see build errors if the file is in an intermediate state—just keep editing and the preview will refresh automatically once it compiles again.
