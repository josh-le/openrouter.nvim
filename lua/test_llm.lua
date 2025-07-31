local M = {}

M.requesting = false

function M.setup()
    vim.api.nvim_create_user_command('OpenRouter', M.complete, { range = true })
end

M.complete = function(opts)
    opts = opts or {}
	--    if M.requesting then
	-- vim.notify('Request already in progress', vim.log.levels.WARN)
	-- return
	--    end

    local lines = {
	"what is the color of the sky",
	"respond in one sentence",
    }
    local prompt = table.concat(lines, '\n')

    local api_key = os.getenv('OPENROUTER_API_KEY')
    if not api_key then
	vim.notify('Error: OPENROUTER_API_KEY not set', vim.log.levels.ERROR)
	return
    end

    local model = 'moonshotai/kimi-k2:free'
    local url = 'https://openrouter.ai/api/v1/chat/completions'

    local payload = {
	model = model,
	messages = { { role = 'user', content = prompt } }
    }
    local json_payload = vim.json.encode(payload)

    vim.notify("Sending request...", vim.log.levels.INFO)

    local curl_cmd = {
	'curl',
	'-s',
	'-X', 'POST',
	'-H', 'Authorization: Bearer ' .. api_key,
	'-H', 'Content-Type: application/json',
	'-d', json_payload,
	url
    }

    vim.system(curl_cmd, {
	stdout = function(_, chunk)
	    if chunk then
		local ok, result = pcall(vim.json.decode, chunk)
		if ok then
		    M.handle_response(result)
		else
		    vim.notify('JSON parsing error', vim.log.levels.ERROR)
		end
	    end
	end,

	stderr = function(_, err)
	    if err then
		vim.notify('Curl Error: ' .. err, vim.log.levels.ERROR)
	    end
	end,

	on_exit = function(_, exit_code)
	    if exit_code ~= 0 then
		vim.notify('Request failed with exit code: ' .. exit_code, vim.log.levels.ERROR)
	    end
	end
    }):wait()
end

M.handle_response = function(data)
    local content = data.choices and data.choices[1].message.content
    if not content then
	vim.notify('No response received', vim.log.levels.WARN)
	return
    end

    local response_lines = vim.split(content, '\n')

    print(response_lines[1])
    -- vim.notify("printed response", vim.log.levels.INFO)
end

M.complete()

return M
