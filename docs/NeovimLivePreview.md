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
local preview_buf = nil

local function render_preview()
  local preview = vim.b.preview_name
  if not preview or preview == "" then
    return
  end

  vim.fn.jobstart(
    {"swift", "run", "SwifTeaPreviewDemo", "--preview", preview},
    {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if not preview_buf or not vim.api.nvim_buf_is_valid(preview_buf) then
          vim.cmd("botright vsplit | enew")
          preview_buf = vim.api.nvim_get_current_buf()
          vim.bo[preview_buf].buftype = "nofile"
          vim.bo[preview_buf].bufhidden = "wipe"
          vim.bo[preview_buf].swapfile = false
          vim.bo[preview_buf].modifiable = true
        else
          vim.bo[preview_buf].modifiable = true
        end
        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, {}) -- clear
        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, data)
        vim.bo[preview_buf].modifiable = false
      end,
      on_stderr = function(_, data)
        if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
          vim.bo[preview_buf].modifiable = true
          vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, data)
          vim.bo[preview_buf].modifiable = false
        end
      end,
    }
  )
end

vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
  pattern = {"*.swift"},
  callback = render_preview,
})

-- Optional: leader shortcut to focus the preview pane
vim.keymap.set("n", "<leader>pp", function()
  if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
    vim.api.nvim_set_current_buf(preview_buf)
  else
    vim.notify("Preview buffer not ready", vim.log.levels.WARN)
  end
end, {desc = "Focus preview buffer"})
```

How it works:
- Every edit in a Swift buffer triggers `render_preview`.
- The job runs `swift run SwifTeaPreviewDemo --preview <buffer name>`.
- Output replaces all lines in the preview split, so the pane stays “fresh”.
- If compilation fails mid-edit, the stderr callback prints the compiler error in the same split. As soon as the code compiles again, the next edit replaces it with the rendered frame.

### 3. Usage Notes

- For now you must set `vim.b.preview_name` for each file you want to preview (or add logic that inspects the file path and derives a default).
- The preview split is read-only; use `<leader>pp` to switch focus to it quickly.
- Because this runs `swift run` behind the scenes, you’ll see build errors if the file is in an intermediate state—just keep editing and the preview will refresh automatically once it compiles again.
