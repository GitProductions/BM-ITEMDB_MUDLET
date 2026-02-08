-- ------------------------------------------------------------
-- Inventory Window
-- ------------------------------------------------------------


------- Issues..
-- 1.  Sometimes the ui needs to be moved/adjusted for it to initially populate the data its been given. (fixed)
-- 2. After reloading the module, it causes the old labels/buttons to still remain and cover parts of the screen until restarting the users profile (fixed)
-- 3. Contents are not scrollable and overflow if too long for window height.  - adding overflow to container doesnt help



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

itemdb.inventory.data = itemdb.inventory.data or {}


itemdb.inventory.window = itemdb.inventory.window or  Adjustable.Container:new({
    name = "itemdb.inventory.window",
    x = "65%",
    y = "2%",
    width = "250",
    height = "300",
    titleText = "Inventory - ItemDB",
    titleTxtColor = "#c8d6e5",
    adjLabelstyle = [[
        background-color: ]] .. itemdb.inventory.colors.bgPanel .. [[;
        border: 1px solid ]] .. itemdb.inventory.colors.border .. [[;
        border-radius: 4px;
    ]],
    docked = true,
    dockPosition = "right"

})

-- Initialize the window with setup message on first load
-- if not itemdb.inventory.initialized then
--     itemdb.inventory.window.initialize()
--     itemdb.inventory.initialized = true
-- end



-- adding padding to this container does not effect the content which resides inside of it?
-- so how do i add room between the outside of the box and the content inside of it? 
-- default color:     background-color: rgb(20, 22, 28);
-- itemdb.inventory.window.box = itemdb.inventory.window.box or Geyser.Label:new({
--     name = "itemdb.inventory.window.box",
--     x = 0,
--     y = 0,
--     width = "100%",
--     height = "100%"
-- }, itemdb.inventory.window)

    -- default color:     background-color: rgb(20, 22, 28);
-- itemdb.inventory.window.box:setStyleSheet([[
--     margin: 20px;
--     background-color: rgb(14, 63, 168);
-- ]])


---- attempted to use scrollable box to prevent content from overflowing when window isnt sized properly.. didnt work :( 
-- itemdb.inventory.window.box.scrollable = itemdb.inventory.window.box.scrollable or Geyser.ScrollBox:new({
--     name = "itemdb.inventory.window.box.scrollable",
--     x = 0,
--     y = 0,
--     width = "100%",
--     height = "100%"
-- }, itemdb.inventory.window.box)



local rows = {{
    name = "daggers",
    condition = "excellent",
    quantity = 15,
    desc = nil
}, {
    name = "sword",
    condition = "excellent",
    quantity = 1,
    desc = nil
}}

function itemdb.inventory.window.refresh()
    -- send("inv")
    
    -- Delete ALL old widgets (both labels and buttons) from previous refreshes
    -- Using deleteLabel which works on all miniconsoles created by Geyser
    for i = 1, 30 do
        local labelName = "itemdb.inventory.window.label." .. i
        local buttonName = "itemdb.inventory.window.button." .. i
        
        pcall(function() deleteLabel(labelName) end)
        pcall(function() deleteLabel(buttonName) end)
    end

    for i, item in ipairs(itemdb.inventory.data) do
        local yOff = (i - 1) * 30

        -- build label text safely - handle items without condition
        local label_text = item.name
        if item.condition then
            label_text = label_text .. " (" .. item.condition .. ")"
        end

        if item.quantity and item.quantity >= 2 then
            label_text = label_text .. " <span style='color: " .. itemdb.inventory.colors.textQty .. "'>" .. "[" .. item.quantity .. "]</span>"
        end

        -- left label
        Geyser.Label:new({
            name = "itemdb.inventory.window.label." .. i,
            x = "0px",
            y = yOff,
            width = "80%",
            height = "25px",
            message = label_text
        }, itemdb.inventory.window):setStyleSheet([[
            background-color: ]] .. itemdb.inventory.colors.bgRow .. [[;
            padding-left: 10px;
            font-weight: 600
        ]])

        -- right button
        Geyser.Button:new({
            name = "itemdb.inventory.window.button." .. i,
            msg = "<center>Select</center>",
            clickCommand = "look " .. item.name,
            clickFunction = function()
                itemdb.submitCapturedItem(item.name)
            end,
            x = "80%",
            y = yOff,
            width = "20%",
            height = "25px",
            style = [[
                margin: 1px;
                background-color: ]] .. itemdb.inventory.colors.bgRow .. [[;
                border: 1px solid white;
            ]]
        }, itemdb.inventory.window)
    end
end



function itemdb.inventory.window.initialize()
    -- Create a setup message that appears on first load
    Geyser.Label:new({
        name = "itemdb.inventory.window.setupMessage",
        x = 0,
        y = 0,
        width = "100%",
        height = "70%",
        message = [[
            <center>
                <b style="font-size: 12px; color: #c8d6e5;">Adjust </b>
                <br><br>
                <span style="color: #8a9bb5; font-size: 10px;">
                    Adjust this window to a preferred location.
                    <br>
                    It will only appear when you identify an item.
                </span>
            </center>
        ]]
    }, itemdb.inventory.window):setStyleSheet([[
        background-color: ]] .. itemdb.inventory.colors.bgPanel .. [[;
        border: 1px solid ]] .. itemdb.inventory.colors.border .. [[;
    ]])


    -- Close button
    Geyser.Button:new({
        name = "itemdb.inventory.window.setupClose",
        msg = "<center>Got it!</center>",
        clickFunction = function()
            deleteLabel("itemdb.inventory.window.setupMessage")
            deleteLabel("itemdb.inventory.window.setupClose")
        end,
        x = "10%",
        y = "70%",
        width = "80%",
        height = "25%",
        style = [[
            background-color: ]] .. itemdb.inventory.colors.bgRow .. [[;
            border: 1px solid ]] .. itemdb.inventory.colors.border .. [[;
            color: #e0e6f0;
            font-weight: 600;
            margin-top: 10px;
        ]]
    }, itemdb.inventory.window)

    cecho("\nbutton made")
end