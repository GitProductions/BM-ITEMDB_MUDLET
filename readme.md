## BlackMUD ItemDB Helper Package

This package was designed for the players of BlackMUD to have an easy way to submit items they have identified into the community item database so that players, new and old are able to quickly look up various items stats and try and determine the high/low for various items due to them having a /random/ stat gen.

This package is new and may have some issues along the way where it may not capture identifies as expected. 


### Installing
Inside of mudlet in the console you can copy/paste this command directly and it will automatically install the package

`lua installPackage("https://github.com/GitProductions/BM-ITEMDB_MUDLET/releases/latest/download/BM-ITEMDB.mpackage")`

### On First Startup

Before you can submit items to the database you will need to create an account via [BlackMUD ItemDB](https://bm-itemdb.gitago.dev/account)

Sign up for an account you can then create an API token which can be used to set up the package.

![Example API Token Request](image.png)

Once you acquire the token from the ItemDB you can hop in Mudlet and type in the command as seen below.
Be sure you are replacing `<TOKEN>` with your actual token from the website.

> `itemdb.set <TOKEN>`


### Whats next?

After thats done, you should have a confirmation message shown and you can begin sending items to the database now directly from Mudlet.. 

You can test it by reciting an identify and await for it to capture. 
You will be prompted with a clickable button/text that will open your inventory. 

When it opens your inventory its going to attach a link to the end of each line.
You will then click the item you just identified and this is how we are capturing the short-description of the item.

After that the submission is complete and you should be able to find it via the website.


---


### Having issues?

Reboot Mudlet, try again!  

If that doesn't work or you have other techincal issues please reach out to Gitago via the discord.





### Developing

`docker run --pull always --rm -it -v "${PWD}:/workspace" -w /workspace demonnic/muddler`cd 





Test add an item to inventory db 

lua inventory.setData({{name = "dagger", condition = "excellent", quantity = 1, desc = nil}})

Check inventory capture length
lua cecho(tostring(#inventory.data))

lua for i, row in ipairs(inventory.rows) do cecho(i .. ": " .. row.name .. " visible=" .. tostring(row:isVisible()) .. "\n") end





-- saving a table 

how bmudlet does it..
configFile = BlackMUDlet_config.lua
packageName = BlackMUDlet

- saving to it like this..
lua table.save(BlackMUDlet.packagePath .. BlackMUDlet.configFile, BlackMUDlet.Config)

- we can overwrite it with ours..
lua table.save(BlackMUDlet.packagePath .. BlackMUDlet.configFile, itemdb)


- we copy exactly as bmudlet and make the same paths mimicing everything.. and we cannot make it save??
unsure what stopping us..
lua table.save(itemdb.packagePath .. itemdb.configFile, itemdb)

we have for variables
configFile = bmud_itemdb.lua
packageName = BM-ITEMDB


<!-- Need to figure out how to create a proper geyser window that can capture iventory data...

sample one liner works fine.. 

and a fairly simple plain window works fine too..


///

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
-- TRIGGER SCRIPT — this is what runs on every line while the
-- trigger is open. Uses the exact pattern from the working
-- multi-line inventory example on the Mudlet blog.
-- ------------------------------------------------------------
function inventory.onInventoryLine()
    local firelen = 1  -- default: keep trigger open for 1 more line

    if line == "You are carrying:" then
        -- header line — start fresh
        inventory.capture.active = true
        inventory.capture.lines  = {}

    elseif line == "" or isPrompt() then
        -- blank line or prompt = end of inventory block
        firelen = 0  -- close the trigger

        if inventory.capture.active then
            inventory.capture.active = false

            -- parse everything we collected
            local items = {}
            for _, l in ipairs(inventory.capture.lines) do
                local parsed = inventory.parseLine(l)
                if parsed then
                    table.insert(items, parsed)
                end
            end

            inventory.capture.lines = {}

            if #items > 0 then
                inventory.setData(items)
            end
        end

    else
        -- a content line while capture is active — grab it
        if inventory.capture.active then
            table.insert(inventory.capture.lines, line)
        end
    end

    setTriggerStayOpen("Inventory Capture", firelen)
end

-- ------------------------------------------------------------
-- CREATE THE TRIGGER — fires on "You are carrying:" and stays
-- open via setTriggerStayOpen until we close it
-- ------------------------------------------------------------
if not exists("Inventory Capture", "trigger") then
    permTrigger("Inventory Capture", "Inventory", "You are carrying:", [[inventory.onInventoryLine()]])
end
enableTrigger("Inventory Capture")

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

        inventory.rows[1]:echo('<span style="color:#6a7a8a; font-size:11px; font-family:sans-serif; font-style:italic;">Type "i" to load inventory</span>')
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
///


 -->