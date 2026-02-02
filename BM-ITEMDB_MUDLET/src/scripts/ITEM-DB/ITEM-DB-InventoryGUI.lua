-- ------------------------------------------------------------
-- Inventory Window
-- ------------------------------------------------------------


------- Issues..
-- 1.  Sometimes the ui needs to be moved/adjusted for it to initially populate the data its been given.
-- 2. After reloading the module, it causes the old labels/buttons to still remain and cover parts of the screen until restarting the users profile
-- 3. Contents are not scrollable and overflow if too long for window height.  - adding overflow to container doesnt help


itemdb.inventory.window = itemdb.inventory.window or  Adjustable.Container:new({
    name = "myWindow",
    x = "75%",
    y = "2%",
    width = "22%",
    height = "35%",
    titleText = "Inventory - v2",
    titleTxtColor = "#c8d6e5",
    adjLabelstyle = [[
        background-color: rgb(20, 22, 28);
        border: 1px solid rgb(80, 90, 110);
        border-radius: 4px;
    ]]

})


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

    for i, item in ipairs(itemdb.inventory.data) do
        local yOff = (i - 1) * 30

        -- build label text safely
        local label_text = item.name .. " (" .. item.condition .. ")"

        if item.quantity and item.quantity >= 2 then
            label_text = label_text .. " [" .. item.quantity .. "]"
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
            background-color: #2b2b2b;
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
                background-color: black;
                border: 1px solid white;
            ]]
        }, itemdb.inventory.window)
    end
end



