------------- Item Submission Function & Handlers  ------------

local function handleSubmitError(event, errMsg, respUrl)

    cecho("<yellow>[ITEMDB] <gray>- <red>Submission failed: " .. (errMsg or "unknown") .. "\n")
    cecho("<yellow>[ITEMDB] <gray>- <red>Make sure your token is set correctly and try again.\n")
end

local function handleSubmitSuccess(event, respUrl, body)
    local ok, data = pcall(yajl.to_value, body)
    if not ok or type(data) ~= "table" or type(data.itemUrls) ~= "table" or #data.itemUrls == 0 then
        itemdb.sendStatusMessage("Failed to parse submission results or no URL returned.", "red")
        return
    end

    if itemdb.state.debugMode then
        cecho(string.format("\n<white>Submission response body: <dark_green>%s", body))
        cecho(string.format("\n<white>Submission response url: <dark_green>%s", respUrl))
        cecho(string.format("\n<white>Submission response data: <dark_green>%s", tostring(data)))
    end

    -- default title is success, but could be a "Item Submission DUPLICATE!"
    local title = "Submission: Success!" 
    local description = "New item submitted! Here's your links:"

    local itemURL = data.itemUrls and data.itemUrls[1] or "unknown"
    local submissionURL = data.submissionUrls and data.submissionUrls[1] or "unknown"


    -- If the item is duplicate, then we need to adjust our messaging and links accordingly
    local isDuplicate = data.duplicateOf 
        and type(data.duplicateOf) == "table" 
        and data.duplicateOf[1] 
        and type(data.duplicateOf[1]) == "string" 
        and data.duplicateOf[1] ~= ""
        and data.duplicateOf[1] ~= "null"   -- extra safety if server ever sends string "null"

            

    if itemdb.state.debugMode then
        cecho("Our submissionURL is: " .. submissionURL .. "\n")
        cecho(string.format("\n<white>Is Duplicate: <dark_green>%s\n", tostring(isDuplicate)))
        cecho(string.format("\n<white>Duplicate ID: <dark_green>%s\n", tostring(duplicateID)))
    end

    -- Override default message
    if isDuplicate then
        title = "Item Submission: DUPLICATE!"
        description = "Item already exists in database!"
    end

    -- Sending "Success" message with links to view item or view submission
    -- If duplicate, the submissionURL will actually be the existing item URL, so we can just use that for both links and adjust messaging accordingly
    itemdb.ui.makeHeader(title, "spring_green", "spring_green", "white", 80)
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <light_blue>" .. description .. "\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <light_blue>Item URL: <light_cyan>" .. itemURL .. "\n")
    cecho("<spring_green>┃ <light_blue>Submission URL: <light_cyan>" .. submissionURL .. "\n")
    cecho("<spring_green>┃\n")
    
    -- Button row
    cecho("<spring_green>┃ ")

    -- Open Website button
    cechoLink("<light_blue>[<wheat> Open in Browser <light_blue>]  ", function()
        openUrl(submissionURL)
    end, "Open this item in your web browser", true)

    -- Share in OOC button
    cechoLink("<light_blue>[<wheat> Share in OOC <light_blue>]  ", function()
        send('ooc ' .. itemdb.state.userOOCPrefix .. ' ' .. submissionURL)
    end, "Send this link to the OOC channel", true)

    -- Copy button (if supported)
    if clipboard then
        cechoLink("<light_blue>[<wheat> Copy URL <light_blue>]", function()
            clipboard.set(submissionURL)
            cecho("<spring_green>\n[URL copied to clipboard!]\n")
        end, "Copy the URL to your clipboard", true)
    end

    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃\n")
    itemdb.ui.makeFooter("spring_green", 80)
end

local function registerSubmissionHandlers()
    -- if itemdb.state.submitHandlersRegistered then
    --     return
    -- end

    registerNamedEventHandler("itemdb.submit", "itemdbSubmitSuccess", "sysPostHttpDone", handleSubmitSuccess)
    registerNamedEventHandler("itemdb.submit", "itemdbSubmitError", "sysPostHttpError", handleSubmitError)

    -- itemdb.state.submitHandlersRegistered = true
end

function itemdb.submitSAMPLEDATA()
    registerSubmissionHandlers()
    cecho("Submitting sample data...\n")
    local sampledata =
        "TEST COLLAR56 (excellent)\nObject 'TEST COLLAR56', Item type: worn\nThis item's ego is of trifling proportions.\nThis item can always be repaired.\nItem is: metal\nWetest: 1\nAffects:\nType:  mana  Value: 46\nType: save_all  Value: 35\nType: mana_regen  Value: 3"

    -- local url = "http://localhost:3000/api/items"
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. itemdb.token
    }

    local body = yajl.to_string({
        raw = sampledata
    })

    postHTTP(body, itemdb.BASE_URL .. "/api/items", headers)
end

function itemdb.submitCapturedItem(itemLine)
    if not itemdb.token then
        -- cecho("<gray>[ITEM-DB]: Token missing. Set it with: <white>itemdb.setToken YOUR_TOKEN\n")
        itemdb.sendStatusMessage("Token missing. Set it with: <white>itemdb.setToken YOUR_TOKEN", "red")
    end

    if not itemdb.state.selectingInventoryItem then
        if itemdb.state.debugMode then
            cecho("Selecting " .. itemLine .. "\n")
        end

        itemdb.sendStatusMessage("No item selection in progress. Please identify an item first.", "red")
        -- This is when we can either hide the buttons or prompt the user to identify an item first?
        return
    end

    if not itemdb.state.captureLines or #itemdb.state.captureLines == 0 then
        itemdb.sendStatusMessage("No identify data captured! Please identify an item first.", "red")
        return
    end

    -- Registering Callbacks for submission results
    registerSubmissionHandlers()

    local identifyOutput = table.concat(itemdb.state.captureLines, "\n")
    local completeData = itemLine .. "\n" .. identifyOutput

    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. itemdb.token
    }

    local body = yajl.to_string({
        raw = completeData
    })

    postHTTP(body, itemdb.BASE_URL .. "/api/items", headers)

    -- assuring cleanup
    itemdb.clearItemSelection(true)

    -- check if itemdb.window.option is hide, or minimze...
    if itemdb.state.windowAutoOption == "hide" then
        itemdb.inventory.window:hide()
    elseif itemdb.state.windowAutoOption == "minimize" then
        itemdb.inventory.window:minimize()
    end

end