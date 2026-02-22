
-- Allows user to set their preference for what happens to the itemdb window after submitting an item.
-- Options are: hide, minimize, none (default is hide)
function itemdb.setWindowAutoMode(mode)
    local validOptions = { hide = true, minimize = true, none = true }
    if not validOptions[mode] then
        itemdb.sendStatusMessage("Invalid option: " .. mode .. ". Valid options are: hide, minimize, none", "red")
        return
    end

    itemdb.state.windowAutoOption = mode
end