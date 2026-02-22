itemdb = itemdb or {}
itemdb.state = itemdb.state or {}

-- ============================================================
-- USER FACING COMMANDS
-- ============================================================

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

-- Allows users to set a custom OOC prefix for their item submission messages if they want to share the submission in OOC automatically after submission
function itemdb.setUserOOC(msg)
    -- need to determine a way to allow them to dynamically place the items title in the message, maybe using {item} as a placeholder that gets replaced with the actual title on submission?
    if not msg or msg:trim() == "" then
        cecho("<yellow>[ITEMDB] <gray>- <orange>Usage: itemdb.setOOC <prefix text>\n")
        return
    end

    itemdb.state.userOOCPrefix = msg:trim()
    cecho("<yellow>[ITEMDB] <gray>- User OOC prefix set to: <white>" .. itemdb.state.userOOCPrefix .. "\n")
    cecho("<yellow>[ITEMDB] <gray>- Example OOC message after submission: <white>" .. itemdb.state.userOOCPrefix ..
              " https://bm-itemdb.gitago.dev/items/9b7b04/skin-snake-snakeskin-tattered\n")

end


function itemdb.debug()
    local debugStatus = itemdb.state.debugMode and "<green>ON" or "<red>OFF"
    cecho("\n<yellow>[ITEMDB] <gray>- Debug mode is " .. debugStatus .. "\n")
    -- debug toggle
    itemdb.state.debugMode = not itemdb.state.debugMode
end


function itemdb.resetState()
    itemdb.state = itemdb.defaultState
    cecho("<yellow>[ITEMDB] <gray>- State reset to defaults.\n")

    itemdb.save()
end



-- ============================================================
-- SAVE & LOAD
-- ============================================================

-- called when sysExitEvent
function itemdb.save()
    local savedata = {
        inventory = itemdb.inventory.data or {},
        token = itemdb.token or "Where did my token go?!",

        -- We save entire state object
        state = itemdb.state or {"None"}
    }
    cecho("<yellow>Saving to " .. itemdb.savePath .. "\n")
    table.save(itemdb.savePath, savedata)
end

function itemdb.load()
    local savedata = {}

    -- Only attempt to load if the save file exists
    local f = io.open(itemdb.savePath, "r")
    if f then
        io.close(f)
        table.load(itemdb.savePath, savedata)
    end

    -- loading data from previous session
    itemdb.inventory.data = savedata.inventory or {}
    itemdb.token = savedata.token or ""
    itemdb.state = savedata.state or itemdb.defaultState

    itemdb.inventory.window.initialize()
    -- itemdb.inventory.window.refresh()

    if itemdb.state.debugMode then
        cecho("<yellow>Inventory data loaded.\n" .. tostring(#itemdb.inventory.data) .. " items.\n")
    end
end
