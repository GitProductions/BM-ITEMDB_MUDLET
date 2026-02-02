itemdb.inventory.window = Adjustable.Container:new({
    name = "myWindow",
    x = "75%",
    y = "2%",
    width = "22%",
    height = "35%",
    titleText = "Inventory v2",
    titleTxtColor = "#c8d6e5",
    adjLabelstyle = [[
        background-color: rgb(20, 22, 28);
        border: 1px solid rgb(80, 90, 110);
        border-radius: 4px;
    ]]

})

itemdb.inventory.window.box = Geyser.Label:new({
    name = "itemdb.inventory.window.box",
    x = 0,
    y = 0,
    width = "100%",
    height = "100%"
}, itemdb.inventory.window)

-- local rows = {{
--     name = "Health",
--     cond = "OK"
-- }, {
--     name = "Mana",
--     cond = "Low"
-- }, {
--     name = "Stamina",
--     cond = "Full"
-- }, {
--     name = "Energy",
--     cond = "Good"
-- }}

-- 

local rows = {{
    name = "dagger",
    condition = "excellent",
    quantity = 15,
    desc = nil
}, {
    name = "sword",
    condition = "excellent",
    quantity = 1,
    desc = nil
}}

for i, item in ipairs(rows) do
    local yOff = (i - 1) * 30 -- offset in px

    cecho("The offset is " .. yOff .. "\n")

    -- left label
    itemdb.inventory.window.box.label = Geyser.Label:new({
        name = "itemdb.inventory.window.label." .. i,
        x = "0px",
        y = yOff,
        width = "60%",
        height = "25px",
        message = item.name .. " ( " .. item.condition .. " )"
    }, itemdb.inventory.window.box)

    itemdb.inventory.window.box.label:setStyleSheet([[
        background-color: #2b2b2b;
        padding-left: 10px;
        font-weight: 600
    ]])

    -- right button
    itemdb.inventory.window.box.label = Geyser.Button:new({
        name = "itemdb.inventory.window.button." .. i,
        msg = "<center>Select Item</center>",
        clickCommand = "look " .. item.name,
        x = "60%",
        y = yOff,
        width = "40%",
        height = "25px",
        style = [[ margin: 1px; background-color: black; border: 1px solid white; ]]
    }, itemdb.inventory.window.box)
end

-- for i, info in ipairs(rows) do
--     local yOff = (i - 1) * 30 -- offset in px

--     cecho("The offset is " .. yOff .. "\n")

--     -- left label
--     itemdb.inventory.window.box.label = Geyser.Label:new({
--         name = "itemdb.inventory.window.label." .. i,
--         x = "0px",
--         y = yOff,
--         width = "60%",
--         height = "25px",
--         message = info.name .. " / " .. info.cond
--     }, itemdb.inventory.window.box)

--     itemdb.inventory.window.box.label:setStyleSheet([[
--         background-color: #2b2b2b;
--         padding-left: 10px;
--         font-weight: 600
--     ]])

--     -- right button
--     itemdb.inventory.window.box.label = Geyser.Button:new({
--         name = "itemdb.inventory.window.button." .. i,
--         msg = "<center>Select Item</center>",
--         clickCommand = "look " .. info.name,
--         x = "60%",
--         y = yOff,
--         width = "40%",
--         height = "25px",
--         style = [[ margin: 1px; background-color: black; border: 1px solid white; ]]
--     }, itemdb.inventory.window.box)
-- end

