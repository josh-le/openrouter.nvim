local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local M = {}
--[[
local colors = function(opts)
    opts = opts or {}
    pickers.new(opts, {
	prompt_title = "colors",
	-- finder = finders.new_oneshot_job({ "find" }, opts )  <-- this executes the find command and calls entry_maker on the results
	finder = finders.new_table {
	    results = {
		{ "red", "#ff0000" },
		{ "green", "#00ff00" },
		{ "blue", "#0000ff" },
	    },
	    entry_maker = function(entry)
		return {
		    value = entry,
		    display = entry[1], -- this is what is shown in the picker
		    ordinal = entry[1], -- this is what we are searching on
		    -- also 'path' to set absolute path and 'lnum' to specify line number
		}
	    end,
	},
	sorter = conf.generic_sorter(opts),
	attach_mappings = function(prompt_bufnr, map)
	    actions.select_default:replace(function()
		actions.close(prompt_bufnr)
		local selection = action_state.get_selected_entry()
		vim.api.nvim_put({ selection[1] }, "", false, true)
	    end)
	    return true
	end,
    }):find()
end

-- colors(require("telescope.themes").get_dropdown{})
colors()

--]]

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
      -- print(model.id, model.name, model.context_length, model.pricing.prompt, model.pricing.completion)
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

--[[
local model_picker = function(opts)
    opts = opts or {}
    local model_list = fetch_models()
    pickers.new(opts, {
	prompt_title = "colors",
	-- finder = finders.new_oneshot_job({ "find" }, opts )  <-- this executes the find command and calls entry_maker on the results
	finder = finders.new_table {
	    results = model_list,
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
		vim.api.nvim_put({ selection[1] }, "", false, true)
	    end)
	    return true
	end,
    }):find()
end
--]]

local model_picker = function(opts)
    opts = opts or {}
    local model_list = fetch_models()
    pickers.new(opts, {
	prompt_title = "choose a model",
	-- finder = finders.new_oneshot_job({ "find" }, opts )  <-- this executes the find command and calls entry_maker on the results
	finder = finders.new_table {
	    results = model_list,
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
		print(vim.inspect(selection))
	    end)
	    return true
	end,
    }):find()
end

model_picker()
