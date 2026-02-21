-- alias: ITEM-DB Set User OOC Prefix
local newMessage = matches[2] or ""
newMessage = newMessage:gsub("^%s+", ""):gsub("%s+$", "")

if newMessage == "" then
    itemdb.sendStatusMessage("New message required. Usage: itemdb.setMessage Check out this new item", "red")
    return
end

itemdb.setUserOOC(newMessage)
