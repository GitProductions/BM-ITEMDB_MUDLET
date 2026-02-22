
-- ============================================================
-- ITEM SEARCH - HANDLE USER QUERIES, DISPLAY RESULTS
-- ============================================================

local function keywordsToSlug(keywords)
    if not keywords or keywords == "" then
        return "item"
    end

    local slug = keywords:lower() -- to lowercase
    :gsub("[^a-z0-9]+", "-") -- any sequence of non-alphanumeric → single -
    :gsub("^%-+", "") -- remove leading dashes
    :gsub("%-+$", "") -- remove trailing dashes
    :gsub("%-+", "-") -- collapse multiple dashes into one

    return slug ~= "" and slug or "item"
end

local function handleSearchSuccess(event, respUrl, body)
    if respUrl ~= itemdb.state.searchCurrentUrl then
        return
    end

    -- resetting current search url to prevent any stray responses from hitting this handler after this point
    itemdb.state.searchCurrentUrl = nil

    local query = itemdb.state.searchCurrentQuery or "unknown"
    -- cecho(string.format("<spring_green>-------------------- Results for '%s' --------------------\n\n", query))
    itemdb.ui.makeHeader("Search Results for: " .. query, "spring_green", "spring_green", "white", 70)

    local ok, data = pcall(yajl.to_value, body)
    if not ok or type(data) ~= "table" or type(data.items) ~= "table" then
        cecho("<spring_green>┃ <gray>- <red>Failed to parse results.\n")
        return
    end

    -- If no items found, just send a basic close message, including footer.
    if #data.items == 0 then
        cecho("<spring_green>┃\n")
        cecho("<spring_green>┃ <khaki>No items found for <white>" .. query .. "\n")
        cecho("<spring_green>┃\n")
        itemdb.ui.makeFooter("spring_green", 70)
        return
    end

    -- If items are found, we list them with their details and links to the website
    cecho("\n")
    for i, item in ipairs(data.items) do
        local name = item.name or "<unknown>"

        -- Items keywords + index
        cecho(string.format("<light_blue>    [%d] <wheat>%s \n", i, name))

        -- Loop thru each item in raw output returned.
        if type(item.raw) == "table" and #item.raw > 0 then
            for _, line in ipairs(item.raw) do
                cecho(string.format("<light_blue>  <white>%s\n", line))
            end
        else
            cecho("<light_blue>  <khaki>(No data available)\n")
        end

        -- Gathering contributors into a single string for display
        local contributors = table.concat(item.contributors or {}, " | ")
        cecho(
            string.format("\n<light_blue>  Contributors: <white>[ %s ]\n", contributors ~= "" and contributors or "none"))

        -- Creating Item URL to website
        local slug = keywordsToSlug(item.keywords)
        local itemURL = itemdb.BASE_URL .. "/items/" .. item.id .. "/" .. slug


        -- Button row
        cecho("<spring_green>  Item URL: <light_cyan>" .. itemURL .. "\n\n")
     
        cechoLink("<light_blue>  [<wheat> Open in Browser <light_blue>]  ", function()
            openUrl(itemURL)
        end, "Open in browser", true)
        cechoLink("<light_blue>  [<wheat> Send to OOC <light_blue>]  ", function()
            send('ooc ' .. itemURL)
        end, "Send to OOC", true)
        if clipboard then
            cechoLink("<light_blue>  [<wheat> Copy URL <light_blue>]", function()
                clipboard.set(itemURL);
                cecho("<spring_green>\n→ Copied!\n")
            end, "Copy URL", true)
        end

        cecho("\n<spring_green>\n")
        itemdb.ui.makeFooter("spring_green", 70)
    end

    -- local displayText = "<light_cyan>" .. itemURL

    -- -- Left-click action: open URL
    -- local leftClickCmd = function()
    --     openUrl(itemURL)
    -- end

    -- -- Right-click menu options
    -- local popupCommands = {leftClickCmd, -- left-click = Opens URL
    -- function()
    --     send('ooc Found this item: ' .. itemURL) -- sends to OOC channel
    -- end}

    -- local popupHints = {"Open in browser (Left Click)", "Send to OOC chat (Right Click)"}

    -- -- Now the popup link 
    -- cecho("<spring_green>Item URL: ")
    -- cechoPopup(displayText, popupCommands, popupHints, true) -- true = use current format/underline


end

local function handleSearchError(event, errMsg, respUrl)
    if respUrl ~= itemdb.state.searchCurrentUrl then
        return
    end
    -- cecho("<yellow>[ITEMDB] <gray>- <red>Search failed: " .. (errMsg or "unknown") .. "\n")
    itemdb.sendMessage("Search failed: " .. (errMsg or "unknown"), "error")

end

local function registerSearchHandlers()
    -- if itemdb.state.searchHandlersRegistered then
    --     return
    -- end

    registerNamedEventHandler("itemdb.search", "itemdbSearchSuccess", "sysGetHttpDone", handleSearchSuccess)
    registerNamedEventHandler("itemdb.search", "itemdbSearchError", "sysGetHttpError", handleSearchError)

    -- itemdb.state.searchHandlersRegistered = true
end

function itemdb.searchItems(query)
    query = (query or ""):trim()
    if query == "" then
        cecho("<yellow>[ITEMDB] <gray>- <orange>Usage: search-db <item name / keyword>\n")
        return
    end

    local encoded = query:gsub("([^%w ])", function(c)
        return string.format("%%%02X", c:byte())
    end):gsub(" ", "+")

    -- local url = ITEMDB_URL .. "?q=" .. encoded
    local url = itemdb.BASE_URL .. "/api/items?q=" .. encoded
    itemdb.state.searchCurrentUrl = url
    itemdb.state.searchCurrentQuery = query

    registerSearchHandlers()

    cecho(string.format("\n<yellow>[ITEMDB] <gray>- <gray>Searching for '<wheat>%s<gray>'...\n", query))
    tempTimer(0.05, function()
        getHTTP(url)
    end)
end