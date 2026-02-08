-- Item DB - Token bootstrapper
itemdb = itemdb or {}
itemdb.tokenBootPrompted = itemdb.tokenBootPrompted or false
itemdb.tokenStartupHandlerRegistered = itemdb.tokenStartupHandlerRegistered or false
itemdb.tokenInstallHandlerRegistered = itemdb.tokenInstallHandlerRegistered or false

itemdb.tokenWelcomeShown = itemdb.tokenWelcomeShown or false
itemdb.tokenUninstallHandlerRegistered = itemdb.tokenUninstallHandlerRegistered or false

local function promptForToken()
    cecho("\n<spring_green>┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <gold>BlackMUD ItemDB - First Time Setup<reset>\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <white>To submit items, edits, or help grow the database,\n")
    cecho("<spring_green>┃ <white>you need to set your authentication token.\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <yellow>Quick start guide:\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃  1. <light_cyan>Sign up or log in<reset> to get your token:\n")
    
    -- Clickable link with hover tooltip
    cecho("<spring_green>┃     ")
    cechoLink(
        "<light_cyan>https://bm-itemdb.gitago.dev/account",
        [[openUrl("https://bm-itemdb.gitago.dev/account")]],
        "Click to open the account page in your browser",
        true
    )
    cecho("\n<spring_green>┃\n")
    
    cecho("<spring_green>┃  2. Copy your <white>API Token<reset> from the account page.\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃  3. In-game, type:\n")
    cecho("<spring_green>┃     <white>itemdb.set YOUR_TOKEN_HERE\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <dim_grey>Until the token is set, submissions are disabled.\n")
    cecho("<spring_green>┃ <dim_grey>It only takes a minute - thanks for helping build the DB!\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┃ <light_blue>><white> Be sure to type the command <yellow>itemdb <dim_grey> for more commands\n")
    cecho("<spring_green>┃\n")
    cecho("<spring_green>┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n\n")
    
    itemdb.tokenBootPrompted = true
end



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


