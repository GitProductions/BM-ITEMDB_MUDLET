-- alias: ITEM-DB timeoutSeconds setter
local timeoutSeconds = matches[2] or ""
timeoutSeconds = timeoutSeconds:gsub("^%s+", ""):gsub("%s+$", "")

if timeoutSeconds == "" then
    itemdb.sendStatusMessage("Total Seconds to wait for timeout required. Usage: itemdb.settimeout 20", "red")
    return
end

itemdb.state.submissionTimeout = tonumber(timeoutSeconds)
itemdb.sendStatusMessage("Timeout seconds set to [<green>" .. timeoutSeconds .. "] seconds", "spring_green")
-- itemdb.setTimeoutSeconds(timeoutSeconds)
