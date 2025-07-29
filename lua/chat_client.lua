-- Simple OpenRouter chat client using lua-openai SDK
-- Run with :luafile % in Neovim

local openai = require("openai")

-- Get API key from environment variable
local api_key = os.getenv("OPENROUTER_API_KEY")
if not api_key then
    print("Error: OPENROUTER_API_KEY environment variable not set")
    return
end

-- Create OpenAI client configured for OpenRouter
local client = openai.new(api_key, {
    base_url = "https://openrouter.ai/api/v1"
})

-- Function to send a message to OpenRouter
local function send_message(prompt)
    print("Sending message to OpenRouter...")

    local status, response = client:chat({
        {role = "system", content = "You are a helpful assistant. Please answer thoughtfully but succinctly."},
        {role = "user", content = prompt},
    }, {
        model = "mistralai/mistral-7b-instruct:free",
        temperature = 0.7
    })

    if status == 200 then
        local reply = response.choices[1].message.content
        print("Response:")
        print(reply)
        return reply
    else
        print("Error: " .. status)
        if response and response.error then
            print("Error message: " .. response.error.message)
        end
        return nil
    end
end

-- Example usage
-- Uncomment the line below to test the function
local M = {}
M.send_message = send_message
return M
-- send_message("What is the capital of France?")

-- print("Chat client loaded. To test, uncomment the example usage line and run :luafile %")
