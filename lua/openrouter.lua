local M = {}

local state = {
    sn = 0, -- session number (which chat session we are on)
    display = {
	chats = {},
    },
    chats = {},
}
local options = {}

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
        border = "rounded",
    }

    return {
	chat = chat
    }
end

local function create_floating_window(opts, enter)
    enter = enter or false
    local config = opts.config or {}

    local buf = opts.buf or vim.api.nvim_create_buf(false, true)

    local win = vim.api.nvim_open_win(buf, enter, config)

    return { buf = buf, win = win }
end

local setup_chat_window = function(sn)
    local title = "chat with " .. state.chats[state.sn].model

    vim.api.nvim_buf_set_lines(state.display.chats[sn].buf, 0, -1, false, { title })
    state.chats[sn].buf_line = state.chats[sn].buf_line + 1
end

local update_chat_window = function(sn)
    for i = state.chats[sn].conversation_position + 1, #state.chats[sn].conversation do
	local chat = state.chats[sn].conversation[i]

	if chat.role == "model" then
	    vim.api.nvim_buf_set_lines(state.display.chats[sn].buf, state.chats[sn].buf_line, -1, false, { "model" })
	    state.chats[sn].buf_line = state.chats[sn].buf_line + 1
	else
	    vim.api.nvim_buf_set_lines(state.display.chats[sn].buf, state.chats[sn].buf_line, -1, false, { "user" })
	    state.chats[sn].buf_line = state.chats[sn].buf_line + 1
	end

	vim.api.nvim_buf_set_lines(state.display.chats[sn].buf, state.chats[sn].buf_line, -1, false, { chat.content })
	state.chats[sn].buf_line = state.chats[sn].buf_line + 1
    end
    state.chats[sn].conversation_position = #state.chats[sn].conversation
end

local open_chat_window = function()
    local winconfig = window_configurations()
    if not vim.api.nvim_buf_is_valid(state.display.chats[state.sn].buf) then
	local opts = {
	    buf = nil,
	    config = winconfig.chat
	}
	state.display.chats[state.sn] = create_floating_window(opts, true)
	vim.bo[state.display.chats[state.sn].buf].filetype = "markdown"
	setup_chat_window(state.sn)
	update_chat_window(state.sn)
    else
	local opts = {
	    buf = state.display.chats[state.sn].buf,
	    config = winconfig.chat
	}
	state.display.chats[state.sn] = create_floating_window(opts, true)
    end
end

local create_new_chat = function()
    table.insert(state.chats, {
	model = "qwen/qwen3-235b-a22b-2507:free",
	conversation = {
	    {
		role = "model",
		content = "hi i am a model",
	    },
	    {
		role = "user",
		content = "hi i am a user. what color is the sky",
	    },
	    {
		role = "model",
		content = "blue",
	    },
	},
	buf_line = 0, -- next line in the buffer to draw the chat to
	conversation_position = 0,
    })
    table.insert(state.display.chats, {
	buf = -1,
	win = -1,
    })
end

local toggle_session = function()
    if state.sn == 0 or not vim.api.nvim_win_is_valid(state.display.chats[state.sn].win) then
	if #state.chats == 0 then
	    state.sn = 1
	    create_new_chat()
	end
	open_chat_window()
    else
	vim.api.nvim_win_hide(state.display.chats[state.sn].win)
    end
end

M.setup = function(opts)
    opts = opts or {}
    options = opts
    vim.keymap.set("n", "<leader>or", toggle_session)
end

vim.api.nvim_create_user_command("Openrouter", toggle_session, {})

return M
