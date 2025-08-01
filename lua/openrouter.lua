local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local llm_api = require "llm_api"

local M = {}

---@class openrouter.Chat
---@field display openrouter.Display: display for this chat
---@field conversation openrouter.ChatMessage[]: conversation history
---@field buf_line integer: next line in the buffer to draw the conversation to
---@field conversation_position integer: which message to draw next
---@field id string: model's openrouter id
---@field name string: model's name
---@field context_length number: context length of model
---@field input_pricing number: input price per million tokens
---@field output_pricing number: output price per million tokens

---@class openrouter.Display
---@field buf integer: buffer number
---@field win integer: window number

---@class openrouter.ChatMessage
---@field role string: user, system, assisstant, tool
---@field content string: content of the chat message

local state = {
    sn = 0, -- session number (which chat session we are on)
    ---@type openrouter.Chat[]
    chats = {},
}

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

local function create_chat_window(opts, enter)
    enter = enter or false
    local config = opts.config or {}

    local buf = opts.buf
    if opts.buf then
	buf = opts.buf
    else
	buf = vim.api.nvim_create_buf(false, true)
    end

    local win = vim.api.nvim_open_win(buf, enter, config)

    return { buf = buf, win = win }
end

local setup_chat_window = function(sn)
    local title = "chat with " .. state.chats[state.sn].name

    vim.api.nvim_buf_set_lines(state.chats[sn].display.buf, 0, -1, false, { title })
    state.chats[sn].buf_line = state.chats[sn].buf_line + 1
end

local update_chat_window = function(sn)
    for i = state.chats[sn].conversation_position + 1, #state.chats[sn].conversation do
	local message = state.chats[sn].conversation[i]

	if message.role == "model" then
	    vim.api.nvim_buf_set_lines(state.chats[sn].display.buf, state.chats[sn].buf_line, -1, false, { "model" })
	    state.chats[sn].buf_line = state.chats[sn].buf_line + 1
	else
	    vim.api.nvim_buf_set_lines(state.chats[sn].display.buf, state.chats[sn].buf_line, -1, false, { "user" })
	    state.chats[sn].buf_line = state.chats[sn].buf_line + 1
	end

	vim.api.nvim_buf_set_lines(state.chats[sn].display.buf, state.chats[sn].buf_line, -1, false, { message.content })
	state.chats[sn].buf_line = state.chats[sn].buf_line + 1
    end
    state.chats[sn].conversation_position = #state.chats[sn].conversation
end

local open_chat_window = function()
    local winconfig = window_configurations()
    if not vim.api.nvim_buf_is_valid(state.chats[state.sn].display.buf) then
	local opts = {
	    buf = nil,
	    config = winconfig.chat
	}
	state.chats[state.sn].display = create_chat_window(opts, true)
	vim.bo[state.chats[state.sn].display.buf].filetype = "markdown"
	vim.bo[state.chats[state.sn].display.buf].buftype = "nofile"
	vim.bo[state.chats[state.sn].display.buf].modifiable = false
	setup_chat_window(state.sn)
	update_chat_window(state.sn)
    else
	local opts = {
	    buf = state.chats[state.sn].display.buf,
	    config = winconfig.chat
	}
	state.chats[state.sn].display = create_chat_window(opts, true)
    end
end

local fetch_models = function()
    local handle, err = io.popen("curl -s https://openrouter.ai/api/v1/models")
    if not handle then
	error("Failed while fetching list of available models: " .. tostring(err))
    end
    local result = handle:read("*a")
    handle:close()
    local data = vim.fn.json_decode(result)
    local r = {}
    for _, model in ipairs(data.data) do
      table.insert(r, {
	  id = model.id,
	  name = model.name,
	  context_length = model.context_length,
	  input_pricing = model.pricing.prompt,
	  output_pricing = model.pricing.completion,
      })
    end
    return r
end
local model_table = fetch_models()

local model_picker = function(opts)
    opts = opts or {}
    pickers.new(opts, {
	prompt_title = "choose a model",
	finder = finders.new_table {
	    results = model_table,
	    entry_maker = function(entry)
		return {
		    value = entry,
		    display = entry.name, -- this is what is shown in the picker
		    ordinal = entry.name, -- this is what we are searching on
		    -- also 'path' to set absolute path and 'lnum' to specify line number
		}
	    end,
	},
	sorter = conf.generic_sorter(opts),
	attach_mappings = function(prompt_bufnr, map)
	    actions.select_default:replace(function()
		actions.close(prompt_bufnr)
		local selection = action_state.get_selected_entry()
		state.chats[state.sn].id = selection.value.id
		state.chats[state.sn].name = selection.value.name
		state.chats[state.sn].context_length = selection.value.context_length
		state.chats[state.sn].input_pricing = selection.value.input_pricing
		state.chats[state.sn].output_pricing = selection.value.output_pricing
		open_chat_window()
	    end)
	    return true
	end,
    }):find()
end

local create_new_chat = function()
    table.insert(state.chats, {
	conversation = {},
	buf_line = 0,
	conversation_position = 0,
	display = {
	    buf = -1,
	    win = -1,
	}
    })
    model_picker()
end

local toggle_session = function()
    if state.sn == 0 or not vim.api.nvim_win_is_valid(state.chats[state.sn].display.win) then
	if #state.chats == 0 then
	    state.sn = 1
	    create_new_chat()
	else
	    open_chat_window()
	end
    else
	vim.api.nvim_win_hide(state.chats[state.sn].display.win)
    end
end

M.setup = function(opts)
    opts = opts or {}
    vim.keymap.set("n", "<leader>or", toggle_session)
end

vim.api.nvim_create_user_command("Openrouter", toggle_session, {})

return M
