inventory = inventory or {}

-- Sample in game inventory
-- You are carrying:
--  a scroll of identify (excellent)
--  a grass skirt festooned with beads and feathers (excellent)
--  a bottle (excellent) [2]
--  a godstone shard of Makilor  (excellent)..It hums powerfully
--  a water skin (excellent)
--  a long wooden planked box (excellent)
--  a backpack (excellent)
--  a bag (excellent)

inventory.colors = {
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
-- that stays open while we're reading inventory lines, then
-- closes itself when we hit an empty line or prompt
-- ------------------------------------------------------------
inventory.capture = inventory.capture or {
    active = false,
    lines  = {},
}

-- ------------------------------------------------------------
-- HELPER: Detect if a line is a prompt
-- Matches pattern like "< 597 465 108 >"
-- ------------------------------------------------------------
-- local function isPrompt(text)
--     local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
--     return trimmed:match("^<") and trimmed:match("%d") and trimmed:match(">$")
-- end

-- ------------------------------------------------------------
-- PARSER
-- Handles:
--   a scroll of identify (excellent)
--   a bottle (excellent) [2]
--   a godstone shard of Makilor  (excellent)..It hums powerfully
-- ------------------------------------------------------------
function inventory.parseLine(line)
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
-- The actual trigger handler is in triggers/ITEM-DB/Inventory-Capture.lua
-- Note: Trigger "Inventory Capture" is defined in triggers.json
-- It fires on "You are carrying:" and calls inventory.onInventoryLine()
-- ------------------------------------------------------------


-- Inventory Capture trigger handlers

-- Inventory capture functions for the trigger system
function inventory.startCapture()
    cecho("<yellow>[Inventory] Starting capture...\n")
    inventory.capture.active = true
    inventory.capture.lines  = {}
    setTriggerStayOpen("Inventory Capture", 99)
end

function inventory.onInventoryLine()
    cecho("onInventoryLine calleed!")
    if not inventory.capture.active then
        return
    end
    
    local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
    
    -- Skip the header line and blank lines
    if trimmed == "" or trimmed == "You are carrying:" then
        return
    end
    
    cecho("<cyan>[Capture] " .. line .. "\n")
    table.insert(inventory.capture.lines, line)

    cecho("Is it a prompt?" .. isPrompt())
    setTriggerStayOpen("Inventory Capture", 1)
end

function inventory.endCapture()
    if not inventory.capture.active then
        return
    end
    
    cecho("<yellow>[Inventory] Ending capture - processing " .. #inventory.capture.lines .. " lines\n")
    setTriggerStayOpen("Inventory Capture", 0)
    inventory.capture.active = false

    -- parse everything we collected
    local items = {}
    for _, l in ipairs(inventory.capture.lines) do
        local parsed = inventory.parseLine(l)
        if parsed then
            -- cecho("<green>[Parsed] " .. parsed.name .. " x" .. parsed.quantity .. " (" .. (parsed.condition or "?") .. ")\n")
            table.insert(items, parsed)
        end
    end

    inventory.capture.lines = {}

    if #items > 0 then
        cecho("<green>[Inventory] Loaded " .. #items .. " items\n")
        inventory.setData(items)
    else
        cecho("<orange>[Inventory] No items parsed!\n")
    end
end


-- -- Inventory capture functions for the trigger system
-- function inventory.startCapture()
--     cecho("<yellow>[Inventory] Starting capture...\n")
--     inventory.capture.active = true
--     inventory.capture.lines  = {}
--     setTriggerStayOpen("Inventory Capture", 99)
-- end

-- function inventory.onInventoryLine()
--     if not inventory.capture.active then
--         return
--     end
    
--     local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
    
--     -- Skip the header line and blank lines
--     if trimmed == "" or trimmed == "You are carrying:" then
--         return
--     end
    
--     cecho("<cyan>[Capture] " .. line .. "\n")
--     table.insert(inventory.capture.lines, line)
--     setTriggerStayOpen("Inventory Capture", 1)
-- end

-- function inventory.endCapture()
--     if not inventory.capture.active then
--         return
--     end
    
--     cecho("<yellow>[Inventory] Ending capture - processing " .. #inventory.capture.lines .. " lines\n")
--     setTriggerStayOpen("Inventory Capture", 0)
--     inventory.capture.active = false

--     -- parse everything we collected
--     local items = {}
--     for _, l in ipairs(inventory.capture.lines) do
--         local parsed = inventory.parseLine(l)
--         if parsed then
--             cecho("<green>[Parsed] " .. parsed.name .. " x" .. parsed.quantity .. " (" .. (parsed.condition or "?") .. ")\n")
--             table.insert(items, parsed)
--         end
--     end

--     inventory.capture.lines = {}

--     if #items > 0 then
--         cecho("<green>[Inventory] Loaded " .. #items .. " items\n")
--         inventory.setData(items)
--     else
--         cecho("<orange>[Inventory] No items parsed!\n")
--     end
-- end

-- TRIGGER SCRIPT

-- ------------------------------------------------------------
-- Adjustable.Container
-- ------------------------------------------------------------
inventory.container = inventory.container or Adjustable.Container:new({
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

inventory.container:show()

-- ------------------------------------------------------------
-- Body label
-- ------------------------------------------------------------
inventory.body = inventory.body or Geyser.Label:new({
    name   = "inventory.body",
    x      = 0,
    y      = 0,
    width  = "100%",
    height = "100%",
}, inventory.container)

inventory.body:setStyleSheet([[
    background-color: rgb(20, 22, 28);
]])

-- ------------------------------------------------------------
-- DATA + ROWS
-- ------------------------------------------------------------
inventory.data = inventory.data or {}
inventory.rows = inventory.rows or {}

local function buildRows()
    if #inventory.data == 0 then
        -- placeholder when empty
        inventory.rows[1] = Geyser.Label:new({
            name   = "inventory.row.empty",
            x      = 0,
            y      = 0,
            width  = "100%",
            height = "100%",
        }, inventory.body)

        inventory.rows[1]:setStyleSheet([[
            background-color: rgb(20, 22, 28);
            padding-left: 12px;
        ]])

        inventory.rows[1]:echo('<span style="color:#6a7a8a; font-size:11px; font-family:sans-serif; font-style:italic;">Type "i" to load the inventory</span>')
        return
    end

    local rowCount = #inventory.data
    local rowH     = math.floor(100 / rowCount)

    for i, item in ipairs(inventory.data) do
        local yPos  = tostring((i - 1) * rowH) .. "%"
        local hPos  = tostring(rowH) .. "%"
        local rowBg = (i % 2 == 0) and inventory.colors.bgRowAlt or inventory.colors.bgRow

        inventory.rows[i] = Geyser.Label:new({
            name   = "inventory.row." .. i,
            x      = 0,
            y      = yPos,
            width  = "100%",
            height = hPos,
        }, inventory.body)

        inventory.rows[i]:setStyleSheet([[
            background-color: ]] .. rowBg .. [[;
            border-bottom: 1px solid rgb(60, 65, 78);
            padding-left: 8px;
        ]])

        local qtyStr  = (item.quantity > 1) and (" x" .. tostring(item.quantity)) or ""
        local condStr = item.condition and (" (" .. item.condition .. ")") or ""
        local descStr = item.desc and (" - " .. item.desc) or ""

        inventory.rows[i]:echo(string.format(
            '<span style="color:%s; font-size:11px; font-family:sans-serif;">%s</span>'
            .. '<span style="color:%s; font-size:11px; font-family:monospace; font-weight:bold;">%s</span>'
            .. '<span style="color:%s; font-size:10px; font-family:sans-serif;">%s</span>'
            .. '<span style="color:%s; font-size:9px; font-family:sans-serif;">%s</span>',
            inventory.colors.textName,  item.name,
            inventory.colors.textQty,   qtyStr,
            inventory.colors.textCond,  condStr,
            inventory.colors.textDesc,  descStr
        ))
    end
end

-- ------------------------------------------------------------
-- PUBLIC: refresh
-- ------------------------------------------------------------
function inventory.refresh()
    for _, row in ipairs(inventory.rows) do
        row:hide()
        Geyser.Widget.delete(row)
    end
    inventory.rows = {}
    buildRows()
end

-- ------------------------------------------------------------
-- PUBLIC: setData
-- ------------------------------------------------------------
function inventory.setData(newData)
    inventory.data = newData or {}
    inventory.refresh()
end

-- ------------------------------------------------------------
-- INITIAL BUILD
-- ------------------------------------------------------------
buildRows()