local M = {}

M.api_key = os.getenv('OPENROUTER_API_KEY')
if not M.api_key then
    error('Error: OPENROUTER_API_KEY not set')
    return
end
M.url = 'https://openrouter.ai/api/v1/chat/completions'

M.complete = function(model, conversation)
    local payload = {
	model = model,
	messages = conversation,
    }
    local json_payload = vim.json.encode(payload)

    vim.notify("Sending request...", vim.log.levels.INFO)

    local curl_cmd = {
	'curl',
	'-s',
	'-X', 'POST',
	'-H', 'Authorization: Bearer ' .. M.api_key,
	'-H', 'Content-Type: application/json',
	'-d', json_payload,
	M.url
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
end

return M
