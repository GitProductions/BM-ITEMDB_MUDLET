-- trigger: Item-DB-Description-Capture
if itemdb.state and itemdb.state.selectingInventoryItem then
    local itemLine = line

    cechoLink("<yellow>[SELECT]", function()
        cecho("<cyan>Selected: " .. itemLine .. "\n")
        itemdb.submitCapturedItem(itemLine)
    end, "Click to select this item", true)
end
