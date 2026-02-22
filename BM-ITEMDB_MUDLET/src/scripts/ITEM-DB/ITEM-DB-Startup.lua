-- ============================================================
-- STARTUP FLOW
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
                itemdb.showStartupMessage()
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

local function showUninstallMessage(reinstallUrl)
    itemdb.ui.makeHeader("Uninstalled", "spring_green", "spring_green", "light_blue")
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
    itemdb.ui.makeFooter("spring_green")
end


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
    -- Reset everything so reinstall feels fresh
    itemdb.state.freshStart = true
    itemdb.tokenBootPrompted = false
    -- itemdb.tokenStartupHandlerRegistered = false
    -- itemdb.tokenInstallHandlerRegistered = false
    -- itemdb.tokenUninstallHandlerRegistered = false
   
    local reinstallUrl = "https://bm-itemdb.gitago.dev/itemdb.mpackage"
    showUninstallMessage(reinstallUrl)
end






-- ============================================================
-- REGISTRATION
-- ============================================================

-- Handle Saving & Loading Config
registerNamedEventHandler("BM-ITEMDB", "itemdb.sysLoadEvent", "sysLoadEvent", itemdb.load)
registerNamedEventHandler("BM-ITEMDB", "itemdb.sysInstall", "sysInstall", itemdb.load)
registerNamedEventHandler("BM-ITEMDB", "itemdb.sysExitEvent", "sysExitEvent", itemdb.save)

-- Handle Install/Uninstall/Startup Events for showing messages and running startup flow
registerNamedEventHandler("itemdb.installed", "itemdbInstall", "sysInstallPackage", handleInstallEvent)
registerNamedEventHandler("itemdb.startup", "itemdbStartup", "sysLoadEvent", handleStartupEvent)
registerNamedEventHandler("itemdb.uninstalled", "itemdbUninstall", "sysUninstall", handleUninstallEvent)

