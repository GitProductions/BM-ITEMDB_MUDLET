
itemdb.savePath = itemdb.packagePath .. "/" ..itemdb.packageName .. "/" .. itemdb.configFile


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


-- ------------------------------------------------------------
-- PARSER for Inventory
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
    -- cecho("<cyan>[Captured]\n")


    -- erasing line from view
   

    table.insert(itemdb.inventory.capture.lines, line)

    -- Every so often we COULD poll the users inventory to keep the UI up to date... 
    -- but now im realizing this is a terrible idea due to lag during fights which could be determential and terrible idea... 
    -- we have to make sure we NEVER send an action on behalf of the user unless they click a button etc..
    -- So instead, we will do this onStartup, it should be completely fine??? but maybe not yet... not et..
    -- if itemdb.state.startup then
    --     deleteLine()
    -- end


    -- cecho("Is it a prompt?" .. isPrompt())

    -- cecho("<red>CAPTURED LINE: ")
    setTriggerStayOpen("Inventory Capture", 1)
end

function itemdb.inventory.endCapture()
    if not itemdb.inventory.capture.active then
        -- cecho("<red> capture not active\n")
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
        -- cecho("Items are ")
        itemdb.inventory.setData(items)

        
    else
        cecho("<orange>[Inventory] No items parsed!\n")
    end
end



function itemdb.inventory.setData(newData)
    itemdb.inventory.data = newData or {}
    -- itemdb.inventory.refresh()

    itemdb.inventory.window.refresh()
end



-- This is ran via trigger when inventory is captured fully
function itemdb.inventory.updateNow()
    itemdb.inventory.setData({})              
    -- itemdb.inventory.refresh()                 
    send("inv")                          
end





-- ------------------------------------------------------------
-- Inventory Window
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
-- -- Single persistent content label
-- -- ------------------------------------------------------------
-- itemdb.inventory.contentLabel = itemdb.inventory.contentLabel or Geyser.Label:new({
--     name   = "itemdb.inventory.content",
--     x      = 0,
--     y      = 0,
--     width  = "100%",
--     height = "100%",
-- }, itemdb.inventory.container)

-- itemdb.inventory.contentLabel:setStyleSheet([[
--     background-color: rgb(20, 22, 28);
--     padding: 8px;
--     qproperty-alignment: 'AlignTop | AlignLeft';
-- ]])


itemdb.inventory.data = itemdb.inventory.data or {}





-- ------------------------------------------------------------
-- Refresh: building ONE big formatted string and echoing it
-- this looks great, but results in a not so great user experience as the contents isnt scrollable, and we cant use buttons directly
-- ------------------------------------------------------------
-- function itemdb.inventory.refresh()
--     -- cecho("Inventory refresh triggered - " .. tostring(#itemdb.inventory.data) .. " items\n")
 

--     if #itemdb.inventory.data == 0 then
--         local placeholder = [[
--             <span style="color:#6a7a8a; font-size:11px; font-style:italic;">
--             Type "i" to load the itemdb.inventory
--             </span>]]
--         itemdb.inventory.contentLabel:echo(placeholder)
--         return
--     end

--     local text = ""
--     for i, item in ipairs(itemdb.inventory.data) do
--         local rowBg = (i % 2 == 0) and itemdb.inventory.colors.bgRowAlt or itemdb.inventory.colors.bgRow
        
--         -- Items Quanity Styling
--         local qtyStr  = (item.quantity > 1) and 
--             (" <span style='color:" .. itemdb.inventory.colors.textQty .. "; font-family:monospace; font-weight:bold;'>x" .. item.quantity .. "</span>") 
--             or ""
        
--         -- Items Condition Styling
--         local condStr = item.condition and 
--             (" <span style='color:" .. itemdb.inventory.colors.textCond .. "; font-size:10px;'>(" .. item.condition .. ")</span>") 
--             or ""
        
--         -- Items Short Description styling
--         local descStr = item.desc and 
--             (" <span style='color:" .. itemdb.inventory.colors.textDesc .. "; font-size:9px;'>- " .. item.desc .. "</span>") 
--             or ""

--         -- how to make button attached to item row to allow users to click and 'look item.name'?  in future maybe we can reference the itemDB and find precise keywords for various actions and controls
--         -- attempted it but
        

--         -- Each item on its own "row" with line break + padding simulation
--         text = text .. [[
--             <div style="background-color:]] .. rowBg .. [[; padding: 4px 8px; border-bottom: 1px solid rgb(60,65,78); margin: 0; line-height: 1.4;">
--             <span style="color:]] .. itemdb.inventory.colors.textName .. [[; font-size:11px; font-family:sans-serif;">]] .. item.name .. [[</span>]] ..
--             qtyStr .. condStr .. descStr .. [[
--             </div>]]
--     end

--     -- Wrap everything in a container for better spacing
--     text = [[<div style="padding: 4px 0;">]] .. text .. [[</div>]]


--     -- itemdb.window.box.label:echo(text)
--     itemdb.inventory.contentLabel:echo(text)
-- end


-- another example but it just not working properly.. cant make each row only 10px for example
-- everything stretches when the window does.. it looks terrible...
-- function itemdb.inventory.refresh()
--     -- Clear old content properly
--     itemdb.inventory.contentLabel:clear() -- wipes HTML if any
--     -- Hide/destroy previous dynamic children if you tracked them
--     -- For simplicity, we'll recreate everything fresh each time

--     if #itemdb.inventory.data == 0 then
--         itemdb.inventory.contentLabel:echo(placeholder)
--         return
--     end

--     local vbox = Geyser.VBox:new({
--         x = 0,
--         y = 0,
--         width = "100%",
--         height = "100%"
--     }, itemdb.inventory.contentLabel)

--     for i, item in ipairs(itemdb.inventory.data) do
--         local row = Geyser.HBox:new({
--             height = 10
--         }, vbox)

--         -- Name + details label (fills space)
--         local nameLabel = Geyser.Label:new({
--             name = "itemNameLabel" .. i,
--             -- width = "50%",
--             width = 20,
--             -- message = string.format("<span style='color:%s;'>%s</span>%s%s%s", itemdb.inventory.colors.textName,
--                 -- item.name, (item.quantity > 1 and " x" .. item.quantity or ""),
--                 -- (item.condition and " (" .. item.condition .. ")" or ""), (item.desc and " - " .. item.desc or ""))
--             message = item.name .. "(" .. item.condition .. ")" .. " - "
--         }, row)

--         myButton:setStyleSheet([[
--             background-color: blue;
--             color: white;
--             border: 1px solid black;
--         ]])

--         -- The height and width of this never seem to get set properly.. how do we limit this?
--         -- local lookBtn = Geyser.Button:new({
--         --     width = 40,
--         --     height = 20,
--         --     clickCommand="look " .. item.name,
--         --     msg = "<center>Select Item</center>",
--         --     style = [[ margin: 1px; background-color: black; border: 1px solid white; ]], 
--         -- }, row)
--         -- style sheets dont seem to apply to buttons..

--         -- Optional: alternate row bg
--         if i % 2 == 0 then
--             row:setStyleSheet("background-color: #1e1e2e;")
--         end
--     end

--     -- Optional: make contentLabel scrollable if too tall
--     -- or resize it: itemdb.inventory.contentLabel:resizeToFitContents() if supported
-- end


-- ------------------------------------------------------------
-- setData
-- ------------------------------------------------------------
function itemdb.inventory.setData(newData)
    itemdb.inventory.data = newData or {}
    
    -- itemdb.inventory.refresh()
    itemdb.inventory.window.refresh()
end



-- called when sysExitEvent
function itemdb.inventory.save()
    local savedata = {
        inventory = itemdb.inventory.data or {},
        token = itemdb.token or ""
    }
    cecho("<yellow>Saving to " .. itemdb.savePath .. "\n")
    table.save(itemdb.savePath, savedata)
end


-- called on sysLoadEvent and sysInstall, but will only run once
function itemdb.inventory.initialize()
 
    local savedata = {}
    table.load(itemdb.savePath, savedata)

    itemdb.inventory.data = savedata.inventory or {}
    itemdb.token = savedata.token or ""

    cecho("<yellow>Inventory data loaded.\n" .. tostring(#itemdb.inventory.data) .. " items.\n")

    -- itemdb.inventory.refresh()
    itemdb.inventory.window.refresh()
    cecho("<yellow>Inventory data loaded.\n")

end





registerNamedEventHandler("BM-ITEMDB", "itemdb.sysLoadEvent", "sysLoadEvent", itemdb.inventory.initialize)
registerNamedEventHandler("BM-ITEMDB", "itemdb.sysInstall", "sysInstall", itemdb.inventory.initialize)
registerNamedEventHandler("BM-ITEMDB", "itemdb.sysExitEvent", "sysExitEvent", itemdb.inventory.save)
