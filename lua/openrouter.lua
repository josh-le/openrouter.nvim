local M = {}

local state = {
    display = {
	chat = {
	    buf = -1,
	    win = -1,
	}
    }
}
local options = {}

M.setup = function(opts)
    opts = opts or {}
    options = opts
    vim.keymap.set("n", "<leader>or", ":Openrouter<CR>")
end

local window_configurations = function()
    local width = vim.o.columns
    local height = vim.o.lines

    -- Default size to 80% of screen if not provided
    local win_width = math.floor(width * 0.9)
    local win_height = math.floor(height * 0.8)

    -- Calculate center position
    local row = math.floor((height - win_height) / 3)
    local col = math.floor((width - win_width) / 2)

    local chat = {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded", -- Change to "single" or "double" if preferred
    }

    return {
	chat = chat
    }
end
local winconfig = window_configurations()

local function create_floating_window(opts, enter)
    enter = enter or false
    local config = opts.config or {}
    -- Create a new buffer if necessary
    local buf = opts.buf or vim.api.nvim_create_buf(false, true)

    -- Open the floating window
    local win = vim.api.nvim_open_win(buf, enter, config)

    return { buf = buf, win = win }
end

local open_chat_window = function()
    if not vim.api.nvim_buf_is_valid(state.display.chat.buf) then
	local opts = {
	    buf = nil,
	    config = winconfig.chat
	}
	state.display.chat = create_floating_window(opts, true)
    else
	local opts = {
	    buf = state.display.chat.buf,
	    config = winconfig.chat
	}
	state.display.chat = create_floating_window(opts, true)
    end
end

local toggle_session = function()
    if not vim.api.nvim_win_is_valid(state.display.chat.win) then
	open_chat_window()
    else
	vim.api.nvim_win_hide(state.display.chat.win)
    end
end

vim.api.nvim_create_user_command("Openrouter", toggle_session, {})

return M
