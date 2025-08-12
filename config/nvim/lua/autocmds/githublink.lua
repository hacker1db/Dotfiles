local function get_github_link()
    local filepath = vim.fn.expand("%:.") -- relative path to git root
    local line = vim.fn.line(".")
    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    local remote_url = vim.fn.systemlist("git config --get remote.origin.url")[1]

    if not remote_url or remote_url == "" then
        print("No remote origin found")
        return
    end

    -- Convert SSH or HTTPS remote URL to GitHub web URL
    local github_url = remote_url
        :gsub("^git@github.com:", "https://github.com/")
        :gsub("%.git$", "")
        :gsub("^https://github.com/", "https://github.com/")

    -- Get current branch
    local branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]

    local url = string.format("%s/blob/%s/%s#L%s", github_url, branch, filepath, line)
    vim.fn.setreg("+", url) -- copy to clipboard
    print("Copied GitHub URL to clipboard:\n" .. url)
end

vim.api.nvim_create_user_command("GitHubLink", get_github_link, {})
