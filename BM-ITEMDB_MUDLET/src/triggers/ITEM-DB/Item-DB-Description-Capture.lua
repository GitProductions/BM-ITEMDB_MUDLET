-- trigger: Item-DB-Description-Capture

---- this was preivously used to attach a clickable link/button for the user to 'select' the item which we then took the item line and sent it for end processing

-- if itemdb.state and itemdb.state.selectingInventoryItem then
--     local itemLine = line

--     cechoLink("<yellow>[SELECT]", function()
--         cecho("<cyan>Selected: " .. itemLine .. "\n")
--         itemdb.submitCapturedItem(itemLine)
--     end, "Click to select this item", true)
-- end
