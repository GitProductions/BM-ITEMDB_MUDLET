-- Item DB - Token bootstrapper
itemdb = itemdb or {}
itemdb.tokenBootPrompted = itemdb.tokenBootPrompted or false
itemdb.tokenStartupHandlerRegistered = itemdb.tokenStartupHandlerRegistered or false
itemdb.tokenInstallHandlerRegistered = itemdb.tokenInstallHandlerRegistered or false

itemdb.tokenWelcomeShown = itemdb.tokenWelcomeShown or false
itemdb.tokenUninstallHandlerRegistered = itemdb.tokenUninstallHandlerRegistered or false

local function promptForToken()
    cecho("\n<red>[ITEM DB] Authentication token is not set. Submissions will be blocked!\n")
    cecho("<yellow>  Type <white>itemdb.set YOUR_TOKEN<yellow> and press Enter to save it.\n")
    cechoLink("[<cyan>Signup for Account]", [[openUrl("https://bm-itemdb.gitago.dev/account")]],
        "Account is required for Mudlet submissions]\n\n", true)
    itemdb.tokenBootPrompted = true
end

cechoLink("<spring_green>Don't have a token yet? ",
    "<spring_green><u>Sign up here → https://bm-itemdb.gitago.dev/account</u>\n\n", function()
        openUrl("https://bm-itemdb.gitago.dev/account")
    end, "Click to open the signup page")

local function ensureTokenPrompted()
    if itemdb.token and itemdb.token ~= "" then
        itemdb.tokenBootPrompted = false
        return true
    end

    if not itemdb.tokenBootPrompted then
        promptForToken()
    end

    return false
end

local function showWelcomeMessage()
    if itemdb.tokenWelcomeShown then
        return
    end

    cechoLink("<spring_green>Don't have a token yet? ",
        "<spring_green><u>Sign up here → https://bm-itemdb.gitago.dev/account</u>\n\n", function()
            openUrl("https://bm-itemdb.gitago.dev/account")
        end, "Click to open the signup page")

    itemdb.tokenWelcomeShown = true
end

local function handleStartupEvent()
    ensureTokenPrompted()
end

local function handleInstallEvent(...)
    showWelcomeMessage()
    ensureTokenPrompted()
end

showWelcomeMessage()
ensureTokenPrompted()

if not itemdb.tokenStartupHandlerRegistered then
    registerNamedEventHandler("itemdb.token", "itemdbTokenStartup", "sysConnectionEvent", handleStartupEvent)
    itemdb.tokenStartupHandlerRegistered = true
end

if not itemdb.tokenInstallHandlerRegistered then
    registerNamedEventHandler("itemdb.token", "itemdbTokenInstall", "sysInstallEvent", handleInstallEvent)
    itemdb.tokenInstallHandlerRegistered = true
end

local function handleUninstallEvent(...)
    cecho("<spring_green>[ITEM DB] Goodbye! The helper package has been removed.\n")
    cecho("<spring_green>  Reinstall and run <white>itemdb.set YOUR_TOKEN<spring_green> to re-enable submissions.\n")
    itemdb.tokenWelcomeShown = false
    itemdb.tokenBootPrompted = false
end

if not itemdb.tokenUninstallHandlerRegistered then
    registerNamedEventHandler("itemdb.token", "itemdbTokenUninstall", "sysUninstall", handleUninstallEvent)
    itemdb.tokenUninstallHandlerRegistered = true
end
