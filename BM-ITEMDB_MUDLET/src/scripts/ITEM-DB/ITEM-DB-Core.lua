-- Item DB - Core helpers and shared state
itemdb = itemdb or {}

itemdb.state = itemdb.state or {
    captureActive = false,
    captureLines = {},
    captureName = nil,
    selectingInventoryItem = false,
    submitTimer = nil,
    searchCurrentUrl = nil,
    searchCurrentQuery = nil,
    searchHandlersRegistered = false
}

-- Used to reset captured lines after submission or cancellation
local function resetCaptureLines()
    itemdb.state.captureLines = {}
    itemdb.state.captureName = nil
end

-- When an identify line is received, capture it
function itemdb.startIdentifyCapture()
    if itemdb.state.selectingInventoryItem then
        cecho("<orange>[New identify detected - cancelling previous submission]\n")
        itemdb.cancelItemSelection(true)
    end

    itemdb.state.captureActive = true
    resetCaptureLines()
    cecho("<gray>[Identify capture started...]\n")
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

    local count = #itemdb.state.captureLines
    if count > 0 then
        cecho("<cyan>+----------------- Item Identified -----------------+\n")
        for _, l in ipairs(itemdb.state.captureLines) do
            cecho("<cyan>| <white>" .. l .. "\n")
        end
        cecho("<cyan>+---------------------------------------------------+\n\n")
    else
        cecho("<orange>No useful lines captured?\n")
    end

    -- expandAlias("capture-item-button")
    itemdb.askUser()
    
    -- resetCaptureLines()
end

function itemdb.askUser()
    cecho("Item-DB:<light_blue>Submit Item: ")
    cechoLink("<green><b>[ Open Inventory ]</b>", function()
        cecho("Preparing to submit item...\n")
        cecho("<yellow>Select the item from your inventory:\n\n")

        itemdb.startItemSelection(15)
        send("i")
    end, "Item-DB: Click to submit item", true)

    cecho("  ") -- spacing

    cechoLink("<red><b>[ CANCEL ]</b>", function()
        cecho("<yellow>Item submission cancelled.\n")
        itemdb.cancelItemSelection(true)
    end, "Item-DB: Cancel and discard this item", true)
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
            cecho("\n<red>[TIMEOUT] Item submission cancelled automatically.\n")
            itemdb.cancelItemSelection(true)
        end
    end)
end

function itemdb.cancelItemSelection(clearCapture)
    itemdb.state.selectingInventoryItem = false

    if itemdb.state.submitTimer then
        killTimer(itemdb.state.submitTimer)
        itemdb.state.submitTimer = nil
    end

    if clearCapture then
        resetCaptureLines()
    end
end

function itemdb.submitCapturedItem(itemLine)
    if not itemdb.state.selectingInventoryItem then
        cecho("<red>No item selection in progress.\n")
        return
    end

    if not itemdb.state.captureLines or #itemdb.state.captureLines == 0 then
        cecho("<red>ERROR: No identify data captured! Please identify an item first.\n")
        return
    end

    if not itemdb.checkToken or not itemdb.checkToken() then
        return
    end

    local identifyOutput = table.concat(itemdb.state.captureLines, "\n")
    local completeData = itemLine .. "\n" .. identifyOutput

    local url = "https://bm-itemdb.gitago.dev/api/items"
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. itemdb.token
    }

    local body = yajl.to_string({
        raw = completeData
    })

    postHTTP(body, url, headers)
    cecho("<cyan>[ITEM DB] Submitted successfully!\n")

    -- assuring cleanup
    resetCaptureLines()
    itemdb.cancelItemSelection(true)
end

-- Search helpers
local function handleSearchSuccess(event, respUrl, body)
    if respUrl ~= itemdb.state.searchCurrentUrl then
        return
    end

    local query = itemdb.state.searchCurrentQuery or "unknown"
    cecho(string.format("<spring_green>-------------------- Results for '%s' --------------------\n\n", query))

    local ok, data = pcall(yajl.to_value, body)
    if not ok or type(data) ~= "table" or type(data.items) ~= "table" then
        cecho("<red>Failed to parse results.\n")
        return
    end

    if #data.items == 0 then
        cecho("<khaki>No items found.\n\n")
        return
    end

    for i, item in ipairs(data.items) do
        local name = item.name or "<unknown>"
        local owner = item.owner or "?"
        cecho(string.format("<light_blue>[%d] <wheat>%s <gray>(submitted by %s)\n", i, name, owner))

        if type(item.raw) == "table" and #item.raw > 0 then
            for _, line in ipairs(item.raw) do
                cecho(string.format("<light_blue>  > <white>%s\n", line))
            end
        else
            cecho("<light_blue>  > <khaki>(No data available)\n")
        end

        cecho("<light_blue>------------------------------------------------------------\n")
    end
end

-- Handles search errors / response failures
local function handleSearchError(event, errMsg, respUrl)
    if respUrl ~= itemdb.state.searchCurrentUrl then
        return
    end
    cecho("<red>Search failed: " .. (errMsg or "unknown") .. "\n")
end

-- Registers HTTP handlers for search functionality
local function registerSearchHandlers()
    if itemdb.state.searchHandlersRegistered then
        return
    end

    registerNamedEventHandler("itemdb.search", "itemdbSearchSuccess", "sysGetHttpDone", handleSearchSuccess)
    registerNamedEventHandler("itemdb.search", "itemdbSearchError", "sysGetHttpError", handleSearchError)

    itemdb.state.searchHandlersRegistered = true
end

-- Performs a search against the Item DB API and displays results
function itemdb.searchItems(query)
    query = (query or ""):trim()
    if query == "" then
        cecho("<orange>Usage: search-db <item name / keyword>\n")
        return
    end

    local encoded = query:gsub("([^%w ])", function(c)
        return string.format("%%%02X", c:byte())
    end):gsub(" ", "+")

    local url = "https://bm-itemdb.gitago.dev/api/items?q=" .. encoded
    itemdb.state.searchCurrentUrl = url
    itemdb.state.searchCurrentQuery = query

    registerSearchHandlers()

    cecho(string.format("<gray>Searching for '<wheat>%s<gray>'...\n", query))
    tempTimer(0.05, function()
        getHTTP(url)
    end)
end




-- EOF ITEM-DB-Core.lua


-- Auto-Updater

--[[

This is the auto-updater for this package. It uses downloads the latest
version of Mupdate and then uses it to download the latest version of the
package, uninstalls the old version, and installs the new version.

If this script has __PKGNAME__ in the name, it will be automatically translated
to the package name when run through muddler. Else, you will have to do
a search/replace for your package name.

This script should be able to be dropped in as-is, but you will need to
customize the settings for Mupdate to work properly.

The Customizable settings are:
  mupdate_url: The URL to download the latest version of Mupdate
  payload: A table of settings for Mupdate
    download_path: The URL to download the latest version of the package
    package_name: The name of the package
    remote_version_file: The name of the file that contains the version
    param_key: (optional) The key to look for in the headers
    param_regex: (optional) The regex to use to extract the filename from the headers
    debug_mode: (optional) Whether to print debug messages

Written by Gesslar@ThresholdRPG 2024-06-24

]]--

local function EscapePath(path)
  -- Escape spaces and other shell-special characters
  return path:gsub("([%s%$%`%!%*%?%[%]%{%}%(%)%|%;&<>])", "\\%1")
end

__PKGNAME__ = __PKGNAME__ or {}
__PKGNAME__.Mupdate = __PKGNAME__.Mupdate or {
  -- System information
  tag = "__PKGNAME__.AutoMupdate",
  package_directory = getMudletHomeDir() .. "/__PKGNAME__",
  local_path = getMudletHomeDir() .. "/__PKGNAME__/Mupdate.lua",
  function_name = "__PKGNAME__:AutoMupdate",
  handler_events = {
    sysDownloadDone = "__PKGNAME__.AutoMupdate.DownloadDone",
    sysDownloadError = "__PKGNAME__.AutoMupdate.DownloadError"
  },

  -- Customizable settings
  mupdate_url = "https://github.com/gesslar/Mupdate/releases/latest/download/Mupdate.lua",
  payload = {
    download_path = "https://github.com/gesslar/__PKGNAME__/releases/latest/download/",
    package_name = "__PKGNAME__",
    remote_version_file = "__PKGNAME___version.txt",
    param_key = "response-content-disposition",
    param_regex = "attachment; filename=(.*)",
    debug_mode = true
  }
}

function __PKGNAME__.Mupdate:Debug(message)
  if not self.debug_mode then return end

  debugc(message)
end

function __PKGNAME__.Mupdate:AutoMupdate(handle, path)
  self:Debug("AutoMupdate - Package Name: __PKGNAME__, Handle: " .. handle)

  if handle ~= self.tag then return end

  registerNamedTimer(self.tag, self.tag, 2, function()
    deleteAllNamedTimers(self.tag)
    self.MupdateScript = require("__PKGNAME__/Mupdate")
    self.Mupdater = self.MupdateScript:new(self.payload)
    self.Mupdater:Start()
  end)
end

function __PKGNAME__.Mupdate:RegisterMupdateEventHandlers()
  local existingHandlers = getNamedEventHandlers(self.tag) or {}
  local newEvents = {}
  for event, label in pairs(self.handler_events) do
    if not existingHandlers[label] then
      self:Debug("Adding new event for " .. label)
      newEvents[event] = label
    else
      self:Debug("Event for " .. label .. " already exists.")
    end
  end

  if newEvents["sysDownloadDone"] then
    registerNamedEventHandler(
      self.tag,
      newEvents["sysDownloadDone"],
      "sysDownloadDone",
      function(event, path, size, response)
        self:Debug("Received download event for " .. path)

        if path ~= self.local_path then return end
        self:UnregisterMupdateEventHandlers()
        self:AutoMupdate(self.tag, path)
      end
    )
  end

  if newEvents["sysDownloadError"] then
    registerNamedEventHandler(
      self.tag,
      newEvents["sysDownloadError"],
      "sysDownloadError",
      function(event, err, path, actualurl)
        self:Debug("Received download error event for " .. path)
        self:Debug("Error: " .. err)

        if path ~= self.local_path then return end
        self:UnregisterMupdateEventHandlers()
      end
    )
  end
end

function __PKGNAME__.Mupdate:UnregisterMupdateEventHandlers()
  local existingHandlers = getNamedEventHandlers(self.tag) or {}
  for _, label in pairs(self.handler_events) do
    local result = deleteNamedEventHandler(self.tag, label)
  end
end

function __PKGNAME__.update()
  local version = getPackageInfo("__PKGNAME__", "version")
  cecho(f"<chocolate>[[ __PKGNAME__ ]]<reset> Initiating manual update to currently installed version {version}.\n")
  cecho(f"<chocolate>[[ __PKGNAME__ ]]<reset> If there is a new version, it will be downloaded and installed.\n")
  cecho(f"<chocolate>[[ __PKGNAME__ ]]<reset> Full logging of update activity may be found in <u>Scripts</u> > <u>Errors</u>\n")

  __PKGNAME__.Mupdate:downloadLatestMupdate()
end

function __PKGNAME__.Mupdate:downloadLatestMupdate()
  local packagePathExists = io.exists(self.package_directory)
  self:Debug("Package directory " .. self.package_directory .. " exists: " .. tostring(packagePathExists))

  local pathExists = io.exists(self.local_path)

  if pathExists then
    self:Debug("Path " .. self.local_path .. " exists: Removing")
    local success, err = pcall(os.remove, self.local_path)
    if not success then
      self:Debug(err)
      return
    else
      self:Debug("Succeeded in removing " .. self.local_path)
    end
  else
    self:Debug("Path " .. self.local_path .. " does not exist.")
  end

  -- Register the download event handlers
  self:Debug("Registering download handlers.")
  self:RegisterMupdateEventHandlers()

  -- Initiate download
  self:Debug("Initiating download of " .. self.mupdate_url .. " to " .. self.local_path)
  downloadFile(self.local_path, self.mupdate_url)
end

-- Start it up
registerNamedEventHandler(
  __PKGNAME__.Mupdate.tag, -- username
  __PKGNAME__.Mupdate.tag..".Load", -- handler name
  "sysLoadEvent", -- event name
  function(event) __PKGNAME__.Mupdate:downloadLatestMupdate() end
)
