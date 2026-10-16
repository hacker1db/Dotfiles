local function get_github_link()
    local abspath = vim.fs.normalize(vim.fn.resolve(vim.fn.expand("%:p")))
    local line = vim.fn.line(".")
    local dir = vim.fs.dirname(abspath)
    local git_root = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })[1]
    if vim.v.shell_error ~= 0 or not git_root or git_root == "" then
        print("Not inside a git repository")
        return
    end
    git_root = vim.fs.normalize(vim.fn.resolve(git_root))
    if abspath:sub(1, #git_root + 1) ~= git_root .. "/" then
        print("Buffer is outside the git root")
        return
    end
    local filepath = abspath:sub(#git_root + 2) -- relative path to git root
    local remote_url = vim.fn.systemlist({ "git", "-C", git_root, "config", "--get", "remote.origin.url" })[1]

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
    local branch = vim.fn.systemlist({ "git", "-C", git_root, "rev-parse", "--abbrev-ref", "HEAD" })[1]

    local url = string.format("%s/blob/%s/%s#L%s", github_url, branch, filepath, line)
    vim.fn.setreg("+", url) -- copy to clipboard
    print("Copied GitHub URL to clipboard:\n" .. url)
end

vim.api.nvim_create_user_command("GitHubLink", get_github_link, {})
