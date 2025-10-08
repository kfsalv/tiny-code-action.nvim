local M = {}

local Job = require("plenary.job")
local BaseBackendFiles = require("tiny-code-action.base.backend").BaseBackendFiles
local GitBackend = BaseBackendFiles:new("git")
local debug_enabled = false
local function debu(obj)
  if debug_enabled then
    local msg = vim.inspect(obj, {
      depth = 2,
      newline = "\n",
    })
    vim.notify(msg)
  end
end

---comment
---@param bufnr number
---@param old_lines table
---@param new_lines table
---@param opts table
---@return table Table Of diff lines
function M.get_diff(bufnr, old_lines, new_lines, opts)
  local old_file, new_file = GitBackend:prepare_files(bufnr, old_lines, new_lines)
  local diff = {}
  local args = {
    "diff",
  }

  vim.list_extend(args, opts.backend_opts.git.args)

  -- if vim.o.background == "dark" then
  --   table.insert(args)
  -- end

  vim.list_extend(args, {
    "--no-index",
    "--color=always",
    "--",
  })

  table.insert(args, old_file)
  table.insert(args, new_file)
  debu(args)

  local git_output = Job:new({
    command = GitBackend.command,
    args = args,
  }):sync()

  Job:new({
    command = "delta",
    args = {
      -- "--hunk-header-decoration-style=omit",
      "--no-gitconfig",
      -- "--line-numbers=omit",
    },
    writer = git_output,
    on_exit = function(j)
      diff = j:result()
    end,
  }):sync()

  GitBackend:cleanup_files(old_file, new_file)
  return GitBackend:process_diff(diff, opts.backend_opts.git.header_lines_to_remove)
end

---comment
---@param lines table
---@return boolean
function M.is_diff_content(lines)
  -- return true
  return GitBackend:is_diff_content(lines)
end

return M
