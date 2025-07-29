CURRENTLY WORKING ON INSTALLING LUASEC WITH LUAROCKS SO WE CAN PING THE API
    nixos is killing me here

# openrouter.nvim
nvim plugin for interacting with LLMs via the openrouter API. very much a WIP
## todo
- menu for llm selection
    - preview window showing llm stats
- dashboard? to show rate limits for different free LLMs
- implement conversation in a tree like structure so you can branch off, rebase etc.
## ideas
- mcp
- regular tool calls that i will use a lot
- structure context well, maybe add some keybinds (dspy?)
- sub-agents?
## questions
- how to store past conversations
    - i don't think we want them to delete once we close the window, how do other plugins do storage of information?
    - we could have an explicit save, and also like a 10 most recent or something
