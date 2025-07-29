--[[
local M = {}

function M.setup_client()
    -- Try to load the lua-openai module
    local ok, openai = pcall(require, "openai")
    if not ok then
        print("Warning: lua-openai module not found!")
        print("To install it, run: luarocks install lua-openai")
        print("Falling back to curl-based implementation...")
        return nil
    end

    local api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key then
        print("Error: OPENROUTER_API_KEY environment variable not set")
        return nil
    end

    local client = openai.new(api_key, {
        base_url = "https://openrouter.ai/api/v1"
    })
    
    return client
end

-- Example usage:
-- local client = M.setup_client()
-- if client then
--     local status, response = client:chat({
--         {role = "system", content = "please answer thoughtfully but succinctly"},
--         {role = "user", content = "what color is the sky"},
--     }, {
--         model = "moonshotai/kimi-k2:free",
--         temperature = 0.5
--     })
--
--     if status == 200 then
--         print(response.choices[1].message.content)
--     end
-- end
--]]
local Job = require('plenary.job')

local function send_openrouter_prompt(prompt, on_complete)
    local api_key = os.getenv("OPENROUTER_API_KEY") -- Replace or securely load
    local url = "https://openrouter.ai/api/v1/chat/completions"
    local headers = {
	["Authorization"] = "Bearer " .. api_key,
	["Content-Type"] = "application/json",
	["HTTP-Referer"] = "https://github.com/josh-le/openrouter.nvim", -- required by OpenRouter
    }
    local body = vim.fn.json_encode({
	model = "moonshotai/kimi-k2:free", -- or any OpenRouter-supported model
	messages = {
	    { role = "system", content = "respond succinctly" },
	    { role = "user", content = prompt },
	},
    })
    Job:new({
	command = "curl",
	args = {
	    "-s", "-X", "POST", url,
	    "-H", "Authorization: Bearer " .. api_key,
	    "-H", "Content-Type: application/json",
	    "-H", "HTTP-Referer: https://github.com/yourname/yourplugin",
	    "-d", body,
	},
	on_exit = function(j, return_val)
	    local response = table.concat(j:result(), "\n")
	    local data = vim.defer_fn(function()
		vim.fn.json_decode(response)
	    end, 0)
	    if data and data.choices and data.choices[1] then
		on_complete(data.choices[1].message.content)
	    else
		print(data.choices)
		on_complete("[No response or error!]")
	    end
	end,
    }):start()
end

send_openrouter_prompt("what color is the sky", print)
