-- alias: ITEM-DB token setter
local token = matches[2] or ""
token = token:gsub("^%s+", ""):gsub("%s+$", "")

if token == "" then
    itemdb.sendStatusMessage("Token required. Usage: itemdb.setToken YOUR_TOKEN", "red")
    return
end

itemdb.setToken(token)
