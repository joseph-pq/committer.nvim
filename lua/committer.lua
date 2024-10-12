local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values


-- map table
local prefix_map = {
    [':bug:'] = 'fix',
    [':sparkles:'] = "feat",
    [':zap:'] = "perf",
    [':recycle:'] = "refactor",
    [':lipstick:'] = "style",
    [':construction:'] = "chore",
    [':white_check_mark:'] = "test",
    [':books:'] = "docs",
    [':wrench:'] = "config",
    [':hammer:'] = "build",
    [':arrow_up:'] = "ci",
    [':fire:'] = "remove",
    [':lock:'] = "security",
    [':pencil2:'] = "update",
    [':rewind:'] = "revert",
    [':truck:'] = "move",
}

-- Function to handle the selection
local function handle_selection(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if selection then
    vim.t.commit_type = selection[1]
    print('You selected: ' .. selection[1])
  else
    print('No selection made')
  end
end

-- Function to create a popup with two options
function ChooseCommitType()
  pickers.new({}, {
    prompt_title = 'Choose commit type',
    finder = finders.new_table {
      results = { 'gitmoji', 'standard' }
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      map('i', '<CR>', handle_selection)
      map('n', '<CR>', handle_selection)
      return true
    end
  }):find()
end

local function setup_telescope_gitmoji(commit_type)
    local telescope = require('telescope')
    telescope.setup({
        extensions = {
            gitmoji = {
                action = function(entry)
                    -- entry = {
                    --   display = "🐛 Fix a bug.",
                    --   index = 4,
                    --   ordinal = "Fix a bug.",
                    --   value = {
                    --     description = "Fix a bug.",
                    --     text = ":bug:",
                    --     value = "🐛"
                    --   }
                    -- }
                    local emoji = entry.value.value
                    if commit_type == 'standard' then
                        emoji = prefix_map[entry.value.text] or emoji
                    end
                    -- Just insert the text instead of commiting
                    local pos = vim.api.nvim_win_get_cursor(0)[2]
                    local line = vim.api.nvim_get_current_line()
                    local nline = line:sub(0, pos) .. emoji .. line:sub(pos + 1)
                    vim.api.nvim_set_current_line(nline)
                end,
            },
        },
    })
    telescope.load_extension("gitmoji")
    vim.keymap.set('n', '<leader>m', telescope.extensions.gitmoji.gitmoji)
end


function SetCommitType(commit_type)
    local git_path = vim.fn.system('git rev-parse --show-toplevel')
    if git_path == '' then
        -- Not a git repository
        return
    end
    -- ChooseCommitType()
    -- check if commit_type is 'gitmoji' or 'standard'
    if commit_type ~= 'gitmoji' and commit_type ~= 'standard' then
        print("Invalid commit type")
        return
    end
    -- save option
    local file = io.open(vim.fn.stdpath('config') .. '/committer.json', 'r')
    if file == nil then
        print("Error reading committer.json file")
        return
    end
    local content = file:read('*a')
    file:close()
    local data = vim.json.decode(content)
    data[git_path] = commit_type
    file = io.open(vim.fn.stdpath('config') .. '/committer.json', 'w')
    if file == nil then
        print("Error writing committer.json file")
        return
    end
    file:write(vim.json.encode(data))
    file:close()

    setup_telescope_gitmoji(commit_type)
end


local function setup()
    -- Check if this is a git repository
    local git_path = vim.fn.system('git rev-parse --show-toplevel')
    if git_path == '' then
        -- Not a git repository
        return
    end
    local commit_type = ''


    -- Create a json file in ~/.config/nvim/committer.json if it doesn't exist
    local file = io.open(vim.fn.stdpath('config') .. '/committer.json', 'r')
    if file == nil then
        file = io.open(vim.fn.stdpath('config') .. '/committer.json', 'w')
        -- check file nil
        if file == nil then
            print("Error creating committer.json file")
            return
        end
        file:write(vim.json.encode({}))
        file:close()
    else -- read
        local content = file:read('*a')
        file:close()
        local data = vim.json.decode(content)
        -- check data nil
        if data == nil then
            print("Error reading committer.json file")
            return
        end
        -- load git_path from data if it exists, otherwise load ''
        commit_type = data[git_path] or ''
        -- if commit_type is not 'gitmoji' or 'standard', set it to ''
        if commit_type ~= 'gitmoji' and commit_type ~= 'standard' then
            commit_type = ''
        end
    end

    -- Set the commit type
    if commit_type == '' then
        commit_type = 'standard'
    end

    setup_telescope_gitmoji(commit_type)

    -- call SetCommitType using :SetCommitType
    vim.cmd('command! SetCommitType lua SetCommitType(vim.fn.input("Commit type: "))')
end


return { setup = setup }
