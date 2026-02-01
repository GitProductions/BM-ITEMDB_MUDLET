-- alias: ITEM-DB token setter
local token = matches[2] or ""
token = token:gsub("^%s+", ""):gsub("%s+$", "")

if token == "" then
    cecho("<red>ITEM DB: token required. Usage: itemdb.set YOUR_TOKEN")
    return
end

itemdb.setToken(token)
