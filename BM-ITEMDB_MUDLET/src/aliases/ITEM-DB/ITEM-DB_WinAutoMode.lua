-- alias: ITEM-DB Set User OOC Prefix
local autoMode = matches[2] or ""
newMessage = newMessage:gsub("^%s+", ""):gsub("%s+$", "")

if autoMode == "" then
    itemdb.sendStatusMessage("New window auto mode required. Usage: itemdb.winAutoMode hide|minimize|none", "red")
    return
end


itemdb.setWindowAutoMode(autoMode)
