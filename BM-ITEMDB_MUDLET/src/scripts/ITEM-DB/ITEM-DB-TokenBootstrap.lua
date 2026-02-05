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
    cecho("<spring_green>-------------------- ItemDB - Uninstalled --------------------\n\n")

    cecho("<wheat>Thanks for using ItemDB!\n")

    cecho("<light_blue>Re-install in one click:\n")

    local reinstallUrl = "https://github.com/GitProductions/BM-ITEMDB_MUDLET/releases/latest/download/BM-ITEMDB.mpackage"

    -- Option 1: Direct install link (preferred - Mudlet will download & install automatically)
    cecho("<light_blue>→ ")
    echoLink(
        "Re-Install ItemDB now!",
        [[installPackage("]] .. reinstallUrl .. [[")]],
        "Click to automatically download and reinstall ItemDB",
        true
    )
    cecho("\n\n")

    -- Option 2: Fallback - copy/open the URL if they prefer manual install
    cecho("<light_blue>→ Or click here to open/download the .mpackage file: ")
    echoLink(
        "" .. reinstallUrl,
        reinstallUrl,
        "Opens the direct download link in your browser",
        true
    )
    cecho("\n\n")

    cecho("<gray>(Mudlet will handle the install automatically if you use the first link)\n\n")

    cecho("<spring_green>------------------------------------------------------------\n")

    -- Cleanup flags as before
    itemdb.tokenWelcomeShown = false
    itemdb.tokenBootPrompted = false
end


if not itemdb.tokenUninstallHandlerRegistered then
    registerNamedEventHandler("itemdb.token", "itemdbTokenUninstall", "sysUninstall", handleUninstallEvent)
    itemdb.tokenUninstallHandlerRegistered = true
end


-- handle install event
-- registerNamedEventHandler("itemdb.welcome", "itemdbWelcomeMessage", "sysInstall", showWelcomeMessage)


