local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node

local template_dir = vim.fn.expand("~/notes/SecondBrain/4.Resources/Templates")

--- Read a template file and return its lines with {{title}} replaced by a placeholder marker
local function read_template(filename)
    local path = template_dir .. "/" .. filename
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

--- Build a snippet that reads a template file at expansion time,
--- replaces {{title}} with an insert node and {{date:*}} with today's date
local function template_snippet(trig, name, filename)
    return s({ trig = trig, name = name, desc = "Insert " .. name .. " from templates folder" }, {
        d(1, function()
            local content = read_template(filename)
            if not content then
                return sn(nil, { t("ERROR: Could not read " .. filename) })
            end

            -- Replace date placeholders with today's date
            content = content:gsub("{{date:%s*(.-)%s*}}", function(fmt)
                -- Convert Obsidian date format to Lua os.date format
                local lua_fmt = fmt
                    :gsub("YYYY", "%%Y")
                    :gsub("yyyy", "%%Y")
                    :gsub("MM", "%%m")
                    :gsub("MMMM", "%%B")
                    :gsub("dddd", "%%A")
                    :gsub("DD", "%%d")
                    :gsub("dd", "%%d")
                    :gsub(" d,", " %%d,")
                return os.date(lua_fmt)
            end)
            content = content:gsub("{{date}}", os.date("%%Y-%%m-%%d"))

            -- Strip Templater code blocks (<%* ... %>)
            content = content:gsub("<%*.-%%>", "")
            -- Strip Templater includes
            content = content:gsub("<%.-%%>", "")

            -- Split {{title}} handling: replace first occurrence with insert node
            local before, after = content:match("^(.-){{title}}(.*)$")
            if before then
                local before_lines = vim.split(before, "\n", { plain = true })
                local after_lines = vim.split(after, "\n", { plain = true })

                -- The last line of 'before' and first line of 'after' are on the same line as the insert node
                local last_before = table.remove(before_lines)
                local first_after = table.remove(after_lines, 1)

                local nodes = {}
                if #before_lines > 0 then
                    table.insert(nodes, t(before_lines))
                end
                if last_before and last_before ~= "" then
                    if #before_lines > 0 then
                        -- Add the last before line joined with previous
                        table.insert(nodes, t({ "", last_before }))
                    else
                        table.insert(nodes, t(last_before))
                    end
                elseif #before_lines > 0 then
                    table.insert(nodes, t({ "" }))
                end

                table.insert(nodes, i(1, "Title"))

                if first_after and first_after ~= "" then
                    table.insert(nodes, t(first_after))
                end
                if #after_lines > 0 then
                    local remaining = {}
                    for _, line in ipairs(after_lines) do
                        table.insert(remaining, line)
                    end
                    table.insert(nodes, t({ "" }))
                    if #remaining > 0 then
                        table.insert(nodes, t(remaining))
                    end
                end

                return sn(nil, nodes)
            else
                -- No {{title}} placeholder, just insert the whole file
                local lines = vim.split(content, "\n", { plain = true })
                return sn(nil, { t(lines) })
            end
        end),
    })
end

return {
    template_snippet("blogpost", "Blog Post", "Blog Post Template.md"),
    template_snippet("dailynote", "Daily Note", "Daily Note Template.md"),
    template_snippet("meeting", "Meeting Notes", "Meeting Notes Template.md"),
    template_snippet("codereview", "Code Review", "Code Review Template 🔐.md"),
    template_snippet("journal", "Journal", "Journal template.md"),
    template_snippet("booknote", "Book Note", "Book Note Template.md"),
    template_snippet("secchampion", "Security Champion Meeting", "Security Champion Meeting Template.md"),
    template_snippet("issuefeature", "Issue Feature", "Issue Template feature.md"),
    template_snippet("issuestory", "Issue Story", "Issue Template Story.md"),
}
