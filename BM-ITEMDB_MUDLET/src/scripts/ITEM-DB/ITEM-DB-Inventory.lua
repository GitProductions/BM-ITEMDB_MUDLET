-- -- itemdb.inventory = itemdb.itemdb.inventory or {}
-- itemdb.inventory = itemdb.inventory or {}



local savePath = itemdb.packagePath .. "/" ..itemdb.packageName .. "/" .. itemdb.configFile

-- Sample in game itemdb.inventory
-- You are carrying:
--  a scroll of identify (excellent)
--  a grass skirt festooned with beads and feathers (excellent)
--  a bottle (excellent) [2]
--  a godstone shard of Makilor  (excellent)..It hums powerfully
--  a water skin (excellent)
--  a long wooden planked box (excellent)
--  a backpack (excellent)
--  a bag (excellent)

itemdb.inventory.colors = {
    bgPanel    = "rgb(20, 22, 28)",
    bgRow      = "rgb(28, 30, 36)",
    bgRowAlt   = "rgb(36, 39, 46)",
    border     = "rgb(80, 90, 110)",
    textName   = "#e0e6f0",
    textQty    = "#7ec8e3",
    textCond   = "#8a9bb5",
    textDesc   = "#6a7a8a",
}

-- ------------------------------------------------------------
-- CAPTURE STATE
-- Uses the setTriggerStayOpen pattern — single named trigger
-- that stays open while we're reading itemdb.inventory lines, then
-- closes itself when we hit an empty line or prompt
-- ------------------------------------------------------------
itemdb.inventory.capture = itemdb.inventory.capture or {
    active = false,
    lines  = {},
}

-- ------------------------------------------------------------
-- PARSER
-- Handles:
--   a scroll of identify (excellent)
--   a bottle (excellent) [2]
--   a godstone shard of Makilor  (excellent)..It hums powerfully
-- ------------------------------------------------------------
function itemdb.inventory.parseLine(line)
    local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")

    if trimmed == "" or trimmed:match("^You are carrying:") then
        return nil
    end

    local name      = trimmed
    local condition = nil
    local quantity  = 1
    local desc      = nil

    -- pull trailing description after ..
    local descMatch = name:match("%.%.(.+)$")
    if descMatch then
        desc = descMatch:gsub("^%s+", "")
        name = name:gsub("%s*%.%.+$", "")
    end

    -- pull quantity [n]
    local qtyMatch = name:match("%[(%d+)%]")
    if qtyMatch then
        quantity = tonumber(qtyMatch)
        name     = name:gsub("%s*%[%d+%]", "")
    end

    -- pull condition (word) at end
    local condMatch = name:match("%((%w+)%)%s*$")
    if condMatch then
        condition = condMatch
        name      = name:gsub("%s*%(%w+%)%s*$", "")
    end

    -- clean up whitespace
    name = name:gsub("%s+$", "")

    -- strip leading article for cleaner display
    local cleanName = name:gsub("^[Aa]n? ", ""):gsub("^[Tt]he ", "")

    return {
        name      = cleanName,
        condition = condition,
        quantity  = quantity,
        desc      = desc,
    }
end

-- ------------------------------------------------------------
-- TRIGGER SCRIPT
-- Note: Trigger "InventoryCapture" is defined in triggers.json
-- It fires on "You are carrying:" and calls itemdb.inventory.onInventoryLine()
-- ------------------------------------------------------------

-- Inventory capture functions for the trigger system
function itemdb.inventory.startCapture()
    cecho("<yellow>[Inventory] Starting capture...\n")
    itemdb.inventory.capture.active = true
    itemdb.inventory.capture.lines  = {}
    setTriggerStayOpen("Inventory Capture", 99)
end

function itemdb.inventory.onInventoryLine()
    -- cecho("onInventoryLine calleed!")
    if not itemdb.inventory.capture.active then
        return
    end
    
    local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
    
    -- Skip the header line and blank lines
    if trimmed == "" or trimmed == "You are carrying:" then
        return
    end
    
    -- cecho("<cyan>[Captured] " .. line .. "\n")
    cecho("<cyan>[Captured]\n")
    table.insert(itemdb.inventory.capture.lines, line)

    -- cecho("Is it a prompt?" .. isPrompt())

    -- cecho("<red>CAPTURED LINE: ")
    setTriggerStayOpen("Inventory Capture", 1)
end

function itemdb.inventory.endCapture()
    if not itemdb.inventory.capture.active then
        cecho("<red> capture not active\n")
        return
    end
    
    if itemdb.inventory.debug then
        cecho("<yellow>[Inventory] Ending capture - processing " .. #itemdb.inventory.capture.lines .. " lines\n")
    end

    setTriggerStayOpen("Inventory Capture", 0)
    itemdb.inventory.capture.active = false

    -- parse everything we collected
    local items = {}
    for _, l in ipairs(itemdb.inventory.capture.lines) do
        local parsed = itemdb.inventory.parseLine(l)
        if parsed then
            -- cecho("<green>[Parsed] " .. parsed.name .. " x" .. parsed.quantity .. " (" .. (parsed.condition or "?") .. ")\n")
            table.insert(items, parsed)
        end
    end


  

    itemdb.inventory.capture.lines = {}

    if #items > 0 then
        cecho("<green>[Inventory] Loaded " .. #items .. " items\n")
        cecho("Items are ")
        itemdb.inventory.setData(items)

        
    else
        cecho("<orange>[Inventory] No items parsed!\n")
    end
end



function itemdb.inventory.setData(newData)
    itemdb.inventory.data = newData or {}
    itemdb.inventory.refresh()
end



function itemdb.inventory.updateNow()
    itemdb.inventory.setData({})               -- clear old data + show placeholder
    itemdb.inventory.refresh()                 -- redraw immediately
    send("inv")                           -- or whatever your itemdb.inventory command is
    -- The trigger will fire, capture fresh lines, parse, and setData() automatically
end




-- ------------------------------------------------------------
-- Adjustable.Container
-- ------------------------------------------------------------

-- itemdb.inventory.container = itemdb.inventory.container or Adjustable.Container:new({
--     name          = "inventoryContainer",
--     x             = "75%",
--     y             = "2%",
--     width         = "22%",
--     height        = "35%",
--     titleText     = "Inventory",
--     titleTxtColor = "#c8d6e5",
--     adjLabelstyle = [[
--         background-color: rgb(20, 22, 28);
--         border: 1px solid rgb(80, 90, 110);
--         border-radius: 4px;
--     ]],
-- })

-- itemdb.inventory.container:show()

-- -- ------------------------------------------------------------
-- -- Body label
-- -- ------------------------------------------------------------
-- itemdb.inventory.body = itemdb.inventory.body or Geyser.Label:new({
--     name   = "itemdb.inventory.body",
--     x      = 0,
--     y      = 0,
--     width  = "100%",
--     height = "100%",
-- }, itemdb.inventory.container)

-- itemdb.inventory.body:setStyleSheet([[
--     background-color: rgb(20, 22, 28);
-- ]])

-- -- ------------------------------------------------------------
-- -- DATA + ROWS
-- -- ------------------------------------------------------------
-- itemdb.inventory.data = itemdb.inventory.data or {}
-- itemdb.inventory.rows = itemdb.inventory.rows or {}

-- local function buildRows()
--     cecho("Clearing ROWS!")
--     if #itemdb.inventory.data == 0 then
--         -- placeholder when empty
--         itemdb.inventory.rows[1] = Geyser.Label:new({
--             name   = "itemdb.inventory.row.empty",
--             x      = 0,
--             y      = 0,
--             width  = "100%",
--             height = "100%",
--         }, itemdb.inventory.body)

--         itemdb.inventory.rows[1]:setStyleSheet([[
--             background-color: rgb(20, 22, 28);
--             padding-left: 12px;
--         ]])

--         itemdb.inventory.rows[1]:echo('<span style="color:#6a7a8a; font-size:11px; font-family:sans-serif; font-style:italic;">Type "i" to load the itemdb.inventory</span>')
--         return
--     end

--     local rowCount = #itemdb.inventory.data
--     local rowH     = math.floor(100 / rowCount)

--     for i, item in ipairs(itemdb.inventory.data) do
--         local yPos  = tostring((i - 1) * rowH) .. "%"
--         local hPos  = tostring(rowH) .. "%"
--         local rowBg = (i % 2 == 0) and itemdb.inventory.colors.bgRowAlt or itemdb.inventory.colors.bgRow

--         itemdb.inventory.rows[i] = Geyser.Label:new({
--             name   = "itemdb.inventory.row." .. i,
--             x      = 0,
--             y      = yPos,
--             width  = "100%",
--             height = hPos,
--         }, itemdb.inventory.body)

--         itemdb.inventory.rows[i]:setStyleSheet([[
--             background-color: ]] .. rowBg .. [[;
--             border-bottom: 1px solid rgb(60, 65, 78);
--             padding-left: 8px;
--         ]])

--         local qtyStr  = (item.quantity > 1) and (" x" .. tostring(item.quantity)) or ""
--         local condStr = item.condition and (" (" .. item.condition .. ")") or ""
--         local descStr = item.desc and (" - " .. item.desc) or ""

--         itemdb.inventory.rows[i]:echo(string.format(
--             '<span style="color:%s; font-size:11px; font-family:sans-serif;">%s</span>'
--             .. '<span style="color:%s; font-size:11px; font-family:monospace; font-weight:bold;">%s</span>'
--             .. '<span style="color:%s; font-size:10px; font-family:sans-serif;">%s</span>'
--             .. '<span style="color:%s; font-size:9px; font-family:sans-serif;">%s</span>',
--             itemdb.inventory.colors.textName,  item.name,
--             itemdb.inventory.colors.textQty,   qtyStr,
--             itemdb.inventory.colors.textCond,  condStr,
--             itemdb.inventory.colors.textDesc,  descStr
--         ))
--     end
-- end

-- -- ------------------------------------------------------------
-- -- PUBLIC: refresh
-- -- ------------------------------------------------------------
-- function itemdb.inventory.refresh()
--     cecho("Inventory refresh triggered\n" .. tostring(#itemdb.inventory.data) .. " items\n")
--     for _, row in ipairs(itemdb.inventory.rows) do
--         cecho("Hiding the row " .. tostring(row.name) .. "\n")
--         row:hide()
--         Geyser.Widget.delete(row)
--     end
--     itemdb.inventory.rows = {}
--     cecho("Inventory Cleared!!\n")
--     buildRows()
-- end

-- -- ------------------------------------------------------------
-- -- PUBLIC: setData
-- -- ------------------------------------------------------------
-- function itemdb.inventory.setData(newData)
--     itemdb.inventory.data = newData or {}
--     itemdb.inventory.refresh()
-- end


-- -- ------------------------------------------------------------
-- -- INITIAL BUILD
-- -- ------------------------------------------------------------
-- buildRows()

--  END REMOVED OLD ATTEMPTED



-- ------------------------------------------------------------
-- Inventory Window
-- ------------------------------------------------------------
itemdb.inventory.container = itemdb.inventory.container or Adjustable.Container:new({
    name          = "inventoryContainer",
    x             = "75%",
    y             = "2%",
    width         = "22%",
    height        = "35%",
    titleText     = "Inventory",
    titleTxtColor = "#c8d6e5",
    adjLabelstyle = [[
        background-color: rgb(20, 22, 28);
        border: 1px solid rgb(80, 90, 110);
        border-radius: 4px;
    ]],

})

itemdb.inventory.container:show()


-- How do we put the itemdb.inventory into a scroll box incase user shrinks window??
-- itemdb.inventory.scrollbox = Adjustable.ScrollBox:new({
--     name   = "itemdb.inventory.scrollbox",
--     x      = 0,
--     y      = 0,
--     width  = "100%",
--     height = "100%",
-- }, itemdb.inventory.container)

-- ------------------------------------------------------------
-- Single persistent content label (no dynamic rows!)
-- ------------------------------------------------------------
itemdb.inventory.contentLabel = itemdb.inventory.contentLabel or Geyser.Label:new({
    name   = "itemdb.inventory.content",
    x      = 0,
    y      = 0,
    width  = "100%",
    height = "100%",
}, itemdb.inventory.container)

itemdb.inventory.contentLabel:setStyleSheet([[
    background-color: rgb(20, 22, 28);
    padding: 8px;
    qproperty-alignment: 'AlignTop | AlignLeft';
]])

-- ------------------------------------------------------------
-- DATA (keep as table for easy sorting/filtering later if needed)
-- ------------------------------------------------------------
itemdb.inventory.data = itemdb.inventory.data or {}

-- ------------------------------------------------------------
-- Refresh: build ONE big formatted string and echo it
-- ------------------------------------------------------------
function itemdb.inventory.refresh()
    cecho("Inventory refresh triggered - " .. tostring(#itemdb.inventory.data) .. " items\n")
 

    if #itemdb.inventory.data == 0 then
        local placeholder = [[
            <span style="color:#6a7a8a; font-size:11px; font-style:italic;">
            Type "i" to load the itemdb.inventory
            </span>]]
        itemdb.inventory.contentLabel:echo(placeholder)
        return
    end

    local text = ""
    for i, item in ipairs(itemdb.inventory.data) do
        local rowBg = (i % 2 == 0) and itemdb.inventory.colors.bgRowAlt or itemdb.inventory.colors.bgRow
        
        -- Items Quanity Styling
        local qtyStr  = (item.quantity > 1) and 
            (" <span style='color:" .. itemdb.inventory.colors.textQty .. "; font-family:monospace; font-weight:bold;'>x" .. item.quantity .. "</span>") 
            or ""
        
        -- Items Condition Styling
        local condStr = item.condition and 
            (" <span style='color:" .. itemdb.inventory.colors.textCond .. "; font-size:10px;'>(" .. item.condition .. ")</span>") 
            or ""
        
        -- Items Short Description styling
        local descStr = item.desc and 
            (" <span style='color:" .. itemdb.inventory.colors.textDesc .. "; font-size:9px;'>- " .. item.desc .. "</span>") 
            or ""

        -- how to make button attached to item row to allow users to click and 'look item.name'?  in future maybe we can reference the itemDB and find precise keywords for various actions and controls
        -- attempted it but it 
        

        -- Each item on its own "row" with line break + padding simulation
        text = text .. [[
            <div style="background-color:]] .. rowBg .. [[; padding: 4px 8px; border-bottom: 1px solid rgb(60,65,78); margin: 0; line-height: 1.4;">
            <span style="color:]] .. itemdb.inventory.colors.textName .. [[; font-size:11px; font-family:sans-serif;">]] .. item.name .. [[</span>]] ..
            qtyStr .. condStr .. descStr .. [[
            </div>]]
    end

    -- Wrap everything in a container for better spacing
    text = [[<div style="padding: 4px 0;">]] .. text .. [[</div>]]

    itemdb.inventory.contentLabel:echo(text)
end

-- ------------------------------------------------------------
-- setData (unchanged, but calls refresh)
-- ------------------------------------------------------------
function itemdb.inventory.setData(newData)
    itemdb.inventory.data = newData or {}
    itemdb.inventory.refresh()
end



-- called when sysExitEvent
function itemdb.inventory.save()
    cecho("<yellow>Attempting a save\n")
    if itemdb.inventory.data then
        cecho("<yellow>Saving to " .. savePath .. "\n")
        table.save(savePath, itemdb.inventory.data)
    end
end
-- ------------------------------------------------------------
-- INITIAL BUILD
-- ------------------------------------------------------------


-- called on sysLoadEvent and sysInstall, but will only run once
function itemdb.inventory.initialize()
    table.load(savePath, itemdb.inventory.data)
    itemdb.inventory.refresh() 
end




-- itemdb.inventory.initialize()


registerNamedEventHandler("BM-ITEMDB", "itemdb.sysLoadEvent", "sysLoadEvent", itemdb.inventory.initialize)
registerNamedEventHandler("BM-ITEMDB", "itemdb.sysInstall", "sysInstall", itemdb.inventory.initialize)

registerNamedEventHandler("BM-ITEMDB", "itemdb.sysExitEvent", "sysExitEvent", itemdb.inventory.save)
