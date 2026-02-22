--  Current issue is when re-installing the module it seems we completely lose our token, despite doing the best we can to save it
-- seems that the cause may be due to mudlet completely deleting the table when uninstalling??
-- SO we may have to consider saving to documents folder if its possible?

-- ============================================================
-- Item DB - Core helpers and shared state
-- ============================================================
itemdb = itemdb or {}
itemdb.token = itemdb.token or "FRESH INSTALL"
itemdb.tokenVerified = itemdb.tokenVerified or false
itemdb.ui = itemdb.ui or {}

-- our token gets verified too "late" causing the our welcome message to show improperly
-- where it should wait a moment and it should be able to know its been online before

-- itemdb.packageName = "BM-ITEMDB"  -- no longer being used.. we dont save in the packages folder to make sure it persists through reinstalls

itemdb.configFile = "bmud_itemdb_config.lua"
itemdb.packagePath = getMudletHomeDir()
itemdb.savePath = itemdb.packagePath .. "/" .. itemdb.configFile

-- itemdb.savePath = itemdb.packagePath .. "/" .. itemdb.packageName .. "/" .. itemdb.configFile


itemdb.update = itemdb.update or {}
itemdb.version = "1.0.3"

-- Handler registration flags (persisted to prevent double-registration)
itemdb.tokenStartupHandlerRegistered = itemdb.tokenStartupHandlerRegistered or false
itemdb.tokenInstallHandlerRegistered = itemdb.tokenInstallHandlerRegistered or false
itemdb.tokenUninstallHandlerRegistered = itemdb.tokenUninstallHandlerRegistered or false

-- Session-only flags (always reset on load)
itemdb.tokenBootPrompted = false

itemdb.inventory = {
    name = "Open Inventory....",
    condition = "",
    quantity = 1,
    desc = nil
}

local defaultState = {
    userOOCPrefix = "New Item Submitted:",
    freshStart = true,
    debugMode = false,
    submissionTimeout = 20, -- seconds until we reset the item submission state in case something goes wrong and we don't get a response from the user or the ItemDB after submission
    windowAutoOption = "hide", -- options: hide / minimize / none - automatically hides the window by default after submissions. hide 

    captureActive = false,
    captureLines = {},
    captureName = nil,
    selectingInventoryItem = false,
    submitTimer = nil,
    searchCurrentUrl = nil,
    searchCurrentQuery = nil,
    searchHandlersRegistered = false

}

itemdb.state = itemdb.state or defaultState

itemdb.BASE_URL = "https://bm-itemdb.gitago.dev"
-- itemdb.BASE_URL = "http://localhost:3000"

-- ============================================================
-- FOR DEVELOPMENT USE ONLY
-- ============================================================

local function killMDK()
    for pkgName, _ in pairs(package.loaded) do
        if pkgName:find("MDK") then
            debugc("Uncaching lua package " .. pkgName)
            package.loaded[pkgName] = nil
        end
    end
end
local function create_helper()
    if MDKhelper then
        MDKhelper:stop()
    end
    MDKhelper = Muddler:new({
        path = "C:\\Users\\GitPC\\Documents\\GitHub\\BM-ITEMDB_MUDLET\\BM-ITEMDB_MUDLET",
        watch = true,

        postremove = killMDK
    })
end
if not MDKhelper then
    registerAnonymousEventHandler("sysLoadEvent", create_helper)
end

-- ============================================================
-- UTIL FUNCTIONS
-- ============================================================

local function versionToNum(v)
    local a, b, c = v:match("(%d+)%.(%d+)%.(%d+)")
    if not a then
        return 0
    end
    return tonumber(a) * 10000 + tonumber(b) * 100 + tonumber(c)
end

local function hasMpackageAsset(assets)
    if type(assets) ~= "table" then
        return false
    end
    for _, asset in ipairs(assets) do
        if type(asset.name) == "string" and asset.name:match("%.mpackage$") then
            return true
        end
    end
    return false
end

-- ============================================================
-- MESSAGE DISPLAYS
-- ============================================================

local function makeHeader(title, borderColor, titleBracketColor, titleTextColor, boxWidth)
    borderColor = borderColor or "spring_green"
    titleBracketColor = titleBracketColor or "orange_red"
    titleTextColor = titleTextColor or "yellow"
    boxWidth = boxWidth or 60

    local leftTag = "[ ItemDB ]"
    local rightTag = "[ " .. title .. " ]"
    local dashes = boxWidth - #leftTag - #rightTag
    local middle = string.rep("━", math.max(dashes, 1))

    cecho("\n<" .. borderColor .. ">┏━<" .. borderColor .. ">[ <white>ItemDB <" .. borderColor .. ">]<" ..
              borderColor .. ">━" .. middle .. "━<" .. titleBracketColor .. ">[ <" .. titleTextColor .. ">" .. title ..
              " <" .. titleBracketColor .. ">]<" .. borderColor .. ">━┓\n")
end

local function makeFooter(borderColor, boxWidth)
    borderColor = borderColor or "spring_green"
    boxWidth = boxWidth or 60
    local line = string.rep("━", boxWidth + 4)
    cecho("<" .. borderColor .. ">┗" .. line .. "┛\n\n")
end

function itemdb.ui.makeHeader(title, borderColor, titleBracketColor, titleTextColor, boxWidth)
    makeHeader(title, borderColor, titleBracketColor, titleTextColor, boxWidth)
end
function itemdb.ui.makeFooter(borderColor, boxWidth)
    makeFooter(borderColor, boxWidth)
end

local function showHelpMessage()
    makeHeader("Available Commands", "light_blue", "light_blue", "white", 80)
    cecho("<light_blue>┃\n")

    local commands = {{
        display = "itemdb.setToken <green><token>",
        plain = "itemdb.setToken <token>",
        desc = "Set your user token for submissions"
    }, -- { display = "itemdb.show",
    -- plain = "itemdb.show",               
    -- desc = "Show your current user token"                  },
    {
        display = "itemdb.search <green><text>",
        plain = "itemdb.search <text>",
        desc = "Search items by name or keyword"
    }, {
        display = "itemdb.setMessage <green><prefix>",
        plain = "itemdb.setMessage <prefix>",
        desc = "Set custom OOC prefix for sharing submissions"
    }, {
        display = "itemdb.setTimeout <green><seconds>",
        plain = "itemdb.setTimeout <seconds>",
        desc = "Set custom timeout seconds for submission requests" ..
            (itemdb.state.submissionTimeout and (" <green>(" .. itemdb.state.submissionTimeout .. "s)") or "")
    }, {
        display = "itemdb.debug",
        plain = "itemdb.debug",
        desc = "Toggle debug mode for error logging" .. (itemdb.state.debugMode and " <green>(ON)" or " <red>(OFF)")
    }, {
        display = "itemdb.welcome",
        plain = "itemdb.welcome",
        desc = "Show the welcome message"
    }, {
        display = "itemdb.reset",
        plain = "itemdb.reset",
        desc = "Reset the ItemDB configuration"
    }, {
        display = "itemdb",
        plain = "itemdb",
        desc = "Show this help menu"
    }}

    local maxLen = 0
    for _, entry in ipairs(commands) do
        maxLen = math.max(maxLen, #entry.plain)
    end

    local headerGap = string.rep(" ", (maxLen + 4) - #"Command")
    cecho("<light_blue>┃  <dim_grey>Command" .. headerGap .. "<gray>│ <dim_grey>Description\n")
    cecho("<light_blue>┃  <dim_grey>" .. string.rep("─", maxLen + 4) .. "<gray>┼<dim_grey>" ..
              string.rep("─", 41) .. "\n")

    for _, entry in ipairs(commands) do
        local padding = string.rep(" ", (maxLen + 4) - #entry.plain)
        cecho("<light_blue>┃  <yellow>" .. entry.display .. padding .. "<gray>│ <wheat>" .. entry.desc .. "\n")
    end

    cecho("<light_blue>┃\n")
    makeFooter("light_blue", 80)
end

function itemdb.showFirstTimeSetup()
    makeHeader("First Time Setup", "spring_green", "spring_green", "white")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <gold>BlackMUD ItemDB " .. tostring(itemdb.version or "?") ..
              " - First Time Setup<reset>\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <white>To submit items, edits, or help grow the database,\n")
    cecho("<spring_green>┃ <white>you need to set your authentication token.\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <yellow>Quick start guide:\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃  1. <light_cyan>Sign up or log in<reset> to get your token:\n")
    cecho("<spring_green>┃     ")
    cechoLink("<light_cyan>https://bm-itemdb.gitago.dev/account", [[openUrl("https://bm-itemdb.gitago.dev/account")]],
        "Click to open the account page in your browser", true)
    cecho("\n<spring_green>┃\n")
    cecho("<spring_green>┃  2. Copy your <white>API Token<reset> from the account page.\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃  3. In-game, type:\n")
    cecho("<spring_green>┃     <white>itemdb.setToken YOUR_TOKEN_HERE\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <dim_grey>Until the token is set, submissions are disabled.\n")
    cecho("<spring_green>┃ <dim_grey>It only takes a minute - thanks for helping build the DB!\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <light_blue>><white> Type <yellow>itemdb <white>for a list of commands.\n")
    cecho("<spring_green>┃\n")
    if itemdb.update.available then
        cecho("<spring_green>┃ <red>► Update available! <white>V" .. tostring(itemdb.update.latestVersion) ..
                  " <gray>is ready to install.\n")
        cecho("<spring_green>┃\n")
    end
    makeFooter("spring_green")

    itemdb.state.freshStart = false
    itemdb.tokenBootPrompted = true
end

function showStartupMessage()
    -- cecho("\n<spring_green>┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n")
    makeHeader("Welcome Back!", "spring_green", "grey", "white")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <gold>BlackMUD ItemDB V" .. tostring(itemdb.version or "?") .. " - Ready<reset>\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <white>Welcome back! Your token is active.\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <light_blue>><white> Type <yellow>itemdb <white>for a list of commands.\n")
    cecho("<spring_green>┃\n")
    if itemdb.update.available then
        cecho("<spring_green>┃ <red>► Update available! <white>V" .. tostring(itemdb.update.latestVersion) ..
                  " <gray>is ready to install.\n")
        cecho("<spring_green>┃\n")
    end
    makeFooter("spring_green")
end

local function showPatchNotes()
    if itemdb.update.patchNotes and itemdb.update.patchNotes ~= "" then
        -- cecho("\n<spring_green>┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n")
        makeHeader("Latest Patch Notes", "spring_green", "yellow", "light_blue")
        cecho("<spring_green>┃\n")
        cecho("<spring_green>┃ <yellow>[ITEMDB] <gray>- <light_blue>Latest Patch Notes:\n\n")
        cecho("<white> ┃" .. itemdb.update.patchNotes .. "\n\n")
        cecho("<spring_green>┃\n")
        makeFooter("spring_green")
    end
end

local function showUpdateAvailable(latestVersion, currentVersion)
    makeHeader("Update Available", "spring_green", "spring_green", "white")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <gold>Update Available!<reset>\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <white>Your version:   <red>" .. currentVersion .. "<reset>\n")
    cecho("<spring_green>┃ <white>Latest version: <green>" .. latestVersion .. "<reset>\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <yellow>To update, click below or reinstall manually:\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃  ")
    echoLink("► Click here to install the latest update now!",
        -- [[installPackage("https://bm-itemdb.gitago.dev/itemdb.mpackage")]],
        [[installPackage("https://github.com/GitProductions/BM-ITEMDB_MUDLET/releases/latest/download/BM-ITEMDB.mpackage")]],
        "Click to automatically download and install the latest version", true)
    cecho("\n<spring_green>┃\n")

    cecho("<spring_green>┃  ")
    cechoLink("<light_cyan>► View release notes here   ", showPatchNotes, "Click to view the latest patch notes", true)

    cechoLink("    <light_cyan>► View release notes on GitHub",
        [[openUrl("https://github.com/GitProductions/BM-ITEMDB_MUDLET/releases/latest")]],
        "Click to open the release page in your browser", true)

    cecho("\n<spring_green>┃\n")
    cecho("<spring_green>┃ <dim_grey>Mudlet will handle the install automatically.")
    cecho("\n<spring_green>┃\n")
    makeFooter("spring_green")
end

local function showTokenNotSet()
    makeHeader("Token Not Set", "orange_red", "white", "orange_red")
    cecho("<orange_red>┃\n")
    cecho("<orange_red>┃ <red>[ERROR] <white>Token not set.\n")
    cecho("<orange_red>┃\n")
    cecho("<orange_red>┃ <white>Type <yellow>itemdb.setToken YOUR_TOKEN <white>to activate submissions.\n")
    cecho("<orange_red>┃ <white>Type <yellow>itemdb <white>for a full list of commands.\n")
    cecho("<orange_red>┃\n")
    if itemdb.update.available then
        cecho(
            "<orange_red>┃ <dim_grey>──────────────────────────────────────────────────────────\n")
        cecho("<orange_red>┃\n")
        cecho("<orange_red>┃ <yellow>► Update available! <white>V" .. tostring(itemdb.update.latestVersion) ..
                  " is ready to install.\n")
        cecho("<orange_red>┃\n")
    end
    makeFooter("orange_red")
end

local function showUninstallMessage(reinstallUrl)
    makeHeader("Uninstalled", "spring_green", "spring_green", "light_blue")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <wheat>Thanks for using ItemDB!\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <white>To reinstall, click the link below and Mudlet will\n")
    cecho("<spring_green>┃ <white>handle the download and install automatically.\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃  ")
    echoLink("► Click here to reinstall ItemDB", [[installPackage("]] .. reinstallUrl .. [[")]],
        "Click to automatically download and reinstall ItemDB", true)
    cecho("\n<spring_green>┃\n")
    cecho("<spring_green>┃  ")
    cechoLink("<light_blue>► Or open the download page manually", [[openUrl("]] .. reinstallUrl .. [[")]],
        "Opens the download link in your browser", true)
    cecho("\n<spring_green>┃\n")
    makeFooter("spring_green")
end

local function showPatchNotes()
    if itemdb.update.patchNotes and itemdb.update.patchNotes ~= "" then
        -- cecho("\n<spring_green>┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n")
        makeHeader("Latest Patch Notes", "spring_green", "spring_green", "light_blue")
        cecho("<spring_green>┃\n")
        cecho("<spring_green>┃ <yellow>[ITEMDB] <gray>- <light_blue>Latest Patch Notes:\n\n")
        cecho("<white> ┃" .. itemdb.update.patchNotes .. "\n\n")
        cecho("<spring_green>┃\n")
        makeFooter("spring_green")
    end
end

local function showUpdateAvailable(latestVersion, currentVersion)
    -- cecho("\n<spring_green>┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n")
    makeHeader("Update Available", "spring_green", "green", "green")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <gold>BlackMUD ItemDB - Update Available!<reset>\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <white>Your version:   <red>" .. currentVersion .. "<reset>\n")
    cecho("<spring_green>┃ <white>Latest version: <green>" .. latestVersion .. "<reset>\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <yellow>To update, click below or reinstall manually:\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃  ")
    echoLink("► Click here to install the latest update now!",
        [[installPackage("https://bm-itemdb.gitago.dev/itemdb.mpackage")]],
        "Click to automatically download and install the latest version", true)
    cecho("\n<spring_green>┃\n")

    cecho("<spring_green>┃  ")
    cechoLink("<light_cyan>► View release notes here   ", showPatchNotes, "Click to view the latest patch notes", true)

    cechoLink("    <light_cyan>► View release notes on GitHub",
        [[openUrl("https://github.com/GitProductions/BM-ITEMDB_MUDLET/releases/latest")]],
        "Click to open the release page in your browser", true)

    cecho("\n<spring_green>┃\n")
    cecho("<spring_green>┃ <dim_grey>Mudlet will handle the install automatically.")
    cecho("\n<spring_green>┃\n")
    makeFooter("spring_green")
end

-- ============================================================
-- COMMANDS
-- ============================================================

function itemdb.setUserOOC(msg)
    -- this allows users to set a custom OOC prefix for their item submission messages if they want to share the submission in OOC automatically after submission
    if not msg or msg:trim() == "" then
        cecho("<yellow>[ITEMDB] <gray>- <orange>Usage: itemdb.setOOC <prefix text>\n")
        return
    end

    itemdb.state.userOOCPrefix = msg:trim()
    cecho("<yellow>[ITEMDB] <gray>- User OOC prefix set to: <white>" .. itemdb.state.userOOCPrefix .. "\n")
    cecho("<yellow>[ITEMDB] <gray>- Example OOC message after submission: <white>" .. itemdb.state.userOOCPrefix ..
              " https://bm-itemdb.gitago.dev/items/9b7b04/skin-snake-snakeskin-tattered\n")

end

function itemdb.debug()
    cecho("\n<yellow>[ITEMDB] <gray>- Debug mode is " .. (itemdb.state.debugMode and "<red>OFF" or "<green>ON") .. "\n")
    -- debug toggle
    itemdb.state.debugMode = not itemdb.state.debugMode
end

function itemdb.help()
    showHelpMessage()
end

-- ============================================================
-- WHEN USER IDENTIFIES AN ITEM - CAPTURE LINES, ASK TO SUBMIT, HANDLE SELECTION
-- ============================================================

-- Used to reset captured lines after submission or cancellation
local function resetCaptureLines()
    itemdb.state.captureLines = {}
    itemdb.state.captureName = nil
end

-- When an identify line is received, capture it
function itemdb.startIdentifyCapture()
    if itemdb.state.selectingInventoryItem then
        cecho("<yellow>[ITEMDB] <gray>- <orange>[New identify detected - cancelling previous submission]\n")
        itemdb.clearItemSelection(true)
    end

    itemdb.state.captureActive = true
    resetCaptureLines()
    cecho("<yellow>[ITEMDB] <gray>- [Identify capture started...]\n")
    setTriggerStayOpen("IdentifyStart", 99)
end

function itemdb.captureIdentifyLine(line)
    if not (itemdb.state.captureActive and line) then
        return
    end

    local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
    if string.find(line, "You recite a scroll of identify", 1, true) or trimmed:match("^You feel informed:") or trimmed ==
        "" or (trimmed:match("^<") and trimmed:match("%d") and trimmed:match(">$")) or
        (#itemdb.state.captureLines > 0 and trimmed ==
            itemdb.state.captureLines[#itemdb.state.captureLines]:gsub("^%s+", ""):gsub("%s+$", "")) then
        setTriggerStayOpen("IdentifyStart", 1)
        return
    end

    table.insert(itemdb.state.captureLines, line)

    if not itemdb.state.captureName then
        local n = line:match("Object '([^']+)'")
        if n then
            itemdb.state.captureName = n
        end
    end

    setTriggerStayOpen("IdentifyStart", 1)
end

-- After identify has finished we process and display the captured lines 
function itemdb.finishIdentifyCapture()
    if not itemdb.state.captureActive then
        return
    end

    setTriggerStayOpen("IdentifyStart", 0)
    itemdb.state.captureActive = false

    if itemdb.state.debugMode == true then
        local count = #itemdb.state.captureLines
        if count > 0 then
            cecho("<cyan>+----------------- Item Identified -----------------+\n")
            for _, l in ipairs(itemdb.state.captureLines) do
                cecho("<cyan>| <white>" .. l .. "\n")
            end
            cecho("<cyan>+---------------------------------------------------+\n\n")
        else
            cecho("<yellow>[ITEMDB] <orange>No useful lines captured?\n")
        end
    end

    -- expandAlias("capture-item-button")

    -- Ask user initites a button to ask user if they want to submit item..
    -- if selecting yes, the users inventory is opened and parsed and we attach buttons to each line..
    -- we now want to move away from this and instead make the buttons in our UI window appear for the user.. and or we need to show the window
    itemdb.askUser()

    -- resetCaptureLines()
end

function itemdb.askUser()
    cecho("<yellow>[Item-DB]: <light_blue>Submit Item: ")
    cechoLink("<green><b>[ Open Inventory ]</b>", function()
        cecho("Preparing to submit item...\n")
        cecho("<yellow>Select the item from your inventory:\n\n")

        itemdb.startItemSelection(itemdb.state.submissionTimeout)
        send("inv")

        -- Showing the inventory window + restoring just to make 100% sure its available for user
        if itemdb.state.windowAutoOption == "hide" then
            itemdb.inventory.window:show()
            itemdb.inventory.window:restore()
        elseif itemdb.state.windowAutoOption == "minimize" then
            itemdb.inventory.window:show()
            itemdb.inventory.window:restore()
        end

    end, "[Item-DB]: Click to submit item", true)

    cecho("  ") -- spacing

    cechoLink("<red><b>[ CANCEL ]</b>", function()
        cecho("<yellow>Item submission cancelled.\n")
        itemdb.clearItemSelection(true)
    end, "[Item-DB]: Cancel and discard this item", true)
    cecho("\n\n")
end

--  
function itemdb.startItemSelection(timeoutSeconds)

    itemdb.state.selectingInventoryItem = true

    if itemdb.state.submitTimer then
        killTimer(itemdb.state.submitTimer)
    end

    itemdb.state.submitTimer = tempTimer(timeoutSeconds or 15, function()
        if itemdb.state.selectingInventoryItem then
            cecho("\n<yellow>[ITEMDB] - <red>[TIMEOUT] Item submission cancelled automatically.\n")
            itemdb.clearItemSelection(true)
        end
    end)
end


-- this should be moved to inventory.. 
-- but resetCaptureLines needs to go to..
function itemdb.clearItemSelection(clearCapture)
    itemdb.state.selectingInventoryItem = false

    if itemdb.state.submitTimer then
        killTimer(itemdb.state.submitTimer)
        itemdb.state.submitTimer = nil
    end

    if clearCapture then
        resetCaptureLines()
    end
end

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

    local query = itemdb.state.searchCurrentQuery or "unknown"
    -- cecho(string.format("<spring_green>-------------------- Results for '%s' --------------------\n\n", query))
    makeHeader("Search Results for: " .. query, "spring_green", "spring_green", "white", 70)

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
        makeFooter("spring_green", 70)
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

        cecho("<spring_green>  Item URL: <light_cyan>" .. itemURL .. "\n")
        
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
        makeFooter("spring_green", 70)
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

-- ============================================================
-- STARTUP FLOW
-- ============================================================

local function handleStartupHandler(event, respUrl, body)
    if respUrl ~= "https://api.github.com/repos/GitProductions/BM-ITEMDB_MUDLET/releases/latest" then
        cecho("<yellow>[ITEMDB] <gray>- <red>Unexpected HTTP response during startup: " .. tostring(respUrl) .. "\n")
        return
    end

    local ok, data = pcall(yajl.to_value, body)
    if ok and type(data) == "table" and type(data.tag_name) == "string" then
        local latestVersion = data.tag_name
        local releaseReady = hasMpackageAsset(data.assets)

        itemdb.update.available = releaseReady and versionToNum(latestVersion) >
                                      versionToNum(tostring(itemdb.version or "0.0.0"))
        itemdb.update.latestVersion = latestVersion
        itemdb.update.patchNotes = data.body or ""
    end

    -- we have a reace condition against checking for the actual token, waiting for response and then showing startup message...

    -- Now show the appropriate message with update info baked in
    tempTimer(3, function()
        if not itemdb.tokenVerified then

            if itemdb.state.freshStart then
                itemdb.showFirstTimeSetup()
            else
                showStartupMessage()
            end

        else
            showTokenNotSet()
            if itemdb.update.available then
                showUpdateAvailable(itemdb.update.latestVersion, itemdb.version)
            end

        end
    end)

end

local function runStartupFlow()
    if itemdb.state.debugMode then
        cecho("Startup flow initiated...\n")
    end

    -- Register the HTTP response handler
    registerNamedEventHandler("itemdb.startup", "itemdbStartupHandler", "sysGetHttpDone", handleStartupHandler, true)

    -- Kick off the startup flow by checking for latest release
    getHTTP("https://api.github.com/repos/GitProductions/BM-ITEMDB_MUDLET/releases/latest")
end

-- ============================================================
-- EVENT HANDLERS
-- ============================================================

local function handleInstallEvent(...)
    itemdb.sendStatusMessage("Installing BlackMUD ItemDB Helper", "gold")

    -- Fresh install only — freshStart will be false
    runStartupFlow()
end

local function handleStartupEvent()
    -- Fires on every Mudlet load/reconnect
    runStartupFlow()
end

local function handleUninstallEvent(...)
    local reinstallUrl = "https://bm-itemdb.gitago.dev/itemdb.mpackage"
    showUninstallMessage(reinstallUrl)

    -- Reset everything so reinstall feels fresh
    itemdb.state.freshStart = true
    itemdb.tokenBootPrompted = false
    itemdb.tokenStartupHandlerRegistered = false
    itemdb.tokenInstallHandlerRegistered = false
    itemdb.tokenUninstallHandlerRegistered = false
end

function itemdb.resetState()
    itemdb.state = defaultState
    cecho("<yellow>[ITEMDB] <gray>- State reset to defaults.\n")

    itemdb.save()
end

-- ============================================================
-- REGISTER HANDLERS
-- ============================================================

-- ============================================================
-- INITIALIZE INVENTORY on sysLoadEvent and sysInstall
-- ============================================================

-- manual save works.. but automatic save results in a fairly tempy list???

-- called when sysExitEvent
function itemdb.save()
    local savedata = {
        inventory = itemdb.inventory.data or {},
        token = itemdb.token or "Where did my token go?!",

        -- We save entire state object
        state = itemdb.state or {"None"}
    }
    cecho("<yellow>Saving to " .. itemdb.savePath .. "\n")
    table.save(itemdb.savePath, savedata)
end

function itemdb.load()
    local savedata = {}

    -- Only attempt to load if the save file exists
    local f = io.open(itemdb.savePath, "r")
    if f then
        io.close(f)
        table.load(itemdb.savePath, savedata)
    end

    -- loading data from previous session
    itemdb.inventory.data = savedata.inventory or {}
    itemdb.token = savedata.token or ""
    itemdb.state = savedata.state or defaultState

    itemdb.inventory.window.initialize()
    -- itemdb.inventory.window.refresh()

    if itemdb.state.debugMode then
        cecho("<yellow>Inventory data loaded.\n" .. tostring(#itemdb.inventory.data) .. " items.\n")
    end
end

registerNamedEventHandler("BM-ITEMDB", "itemdb.sysLoadEvent", "sysLoadEvent", itemdb.load)
registerNamedEventHandler("BM-ITEMDB", "itemdb.sysInstall", "sysInstall", itemdb.load)
registerNamedEventHandler("BM-ITEMDB", "itemdb.sysExitEvent", "sysExitEvent", itemdb.save)

if not itemdb.tokenInstallHandlerRegistered then
    registerNamedEventHandler("itemdb.token", "itemdbTokenInstall", "sysInstallPackage", handleInstallEvent)
    itemdb.tokenInstallHandlerRegistered = true
end

if not itemdb.tokenStartupHandlerRegistered then
    registerNamedEventHandler("itemdb.token", "itemdbTokenStartup", "sysLoadEvent", handleStartupEvent)
    itemdb.tokenStartupHandlerRegistered = true
end

if not itemdb.tokenUninstallHandlerRegistered then
    registerNamedEventHandler("itemdb.token", "itemdbTokenUninstall", "sysUninstall", handleUninstallEvent)
    itemdb.tokenUninstallHandlerRegistered = true
end
