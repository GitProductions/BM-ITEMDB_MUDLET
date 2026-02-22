
local function parseJson(body)
    local success, data = pcall(yajl.to_value, body)

    -- if not success then
    --     cecho("<orange>Failed to parse JSON: " .. tostring(data) .. "\n")
    --     cecho("<orange>Raw body was: " .. body .. "\n")
    --     itemdb.token = nil
    --     return
    -- end

    -- local message = data.message
    return data
end

function itemdb.sendStatusMessage(message, color)
    color = color or "spring_green"
    cecho("<" .. color .. ">┏━━<gray>[ ItemDB ]" .."<" .. color .. ">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n")
    cecho("<" .. color .. ">┃\n")
    cecho("<" .. color .. ">┃ <white> " .. message .. " \n")
    cecho("<" .. color .. ">┃\n")
    cecho("<" .. color .. ">┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n")
end

local function handleVerifySuccess(_, url, body)
    if itemdb.state.debugMode then
        cecho(string.format("\n<white>url: <dark_green>%s<white>, body: <dark_green>%s\n", url, body))
    end 

    if not body or body == "" then
        cecho("\n<red>Empty response from server!\n")
        itemdb.tokenVerified = false
        itemdb.token = nil
    end

    -- Parsing our HTTPPost response
    local data = parseJson(body)

    -- If its a token response, it will have data.message 
    if data and data.message == "valid" then

        -- Only displaying token verified AFTER startup complete, to prevent excess messages during startup flow
        if itemdb.startupComplete then
            itemdb.sendStatusMessage("Token Verified Successfully!", "spring_green")
        end

        itemdb.tokenVerified = true
    end

    if data and data.message == "invalid" then
            itemdb.sendStatusMessage("Token Invalid!", "orange_red")

            itemdb.tokenVerified = false
            itemdb.token = nil
    end

end

local function handleVerifyError(_, url, errorMsg)
    cecho("<gray>[ITEM-DB]:<red> ItemDB may be down, please check and report to Gitago if issue persists " .. errorMsg .. "\n")
end

function itemdb.verifyUserToken(token)
    -- Making Post request to ItemDB to verify user token

    if itemdb.state.debugMode then
        itemdb.sendStatusMessage("Verifying User Auth Token...", "khaki")
    end

    local url = itemdb.BASE_URL .. "/api/tokens/verify"
    local headers = {
        ["Content-Type"] = "application/json"
    }

    -- assuring we close/kill handlers set prior
    -- if tokenVerifyHandlerID then killAnonymousEventHandler(tokenVerifyHandlerID) end
    -- tokenVerifyHandlerID = registerAnonymousEventHandler("sysPostHttpDone", onHttpPostDone, true)

    -- if tokenErrorHandlerID then killAnonymousEventHandler(tokenErrorHandlerID) end
    -- tokenErrorHandlerID = registerAnonymousEventHandler("sysPostHttpError", onHttpPostError, true)

    registerNamedEventHandler("itemdb.verifyToken", "itemdbVerifySuccess", "sysPostHttpDone", handleVerifySuccess)
    registerNamedEventHandler("itemdb.verifyToken", "itemdbVerifyError", "sysPostHttpError", handleVerifyError)


    postHTTP(token, url, headers)
end


-- ============================================================
-- TOKEN COMMANDS - SET, GET, VERIFY
-- Note: user token gets set, but revoked if the verification fails
-- ============================================================

-- Helper function to check if token has been set at all yet..
local function checkToken(token)
    if #token < 30 then
        cecho("<orange>[ITEM DB] Warning: Token looks suspiciously short - might be invalid.\n")
        return false
    end

    if itemdb.tokenVerified and token == itemdb.token then
        cecho("<green>[ITEM DB] Token already verified.\n")
        return true
    end

    itemdb.tokenVerified = false -- reset verified status until we verify the new token
    itemdb.token = token -- setting token as valid and will revoke later if invalid

    itemdb.verifyUserToken(itemdb.token)
end


-- Give user their token if needed for debug / etc
function itemdb.getToken()
    if not itemdb.token or itemdb.token == "" then
        cecho("<gray>[ITEM-DB]: Token missing. Set it with: <white>itemdb.setToken YOUR_TOKEN\n")
        cecho("<spring_green>Need one? ")
        cechoLink(
            "<light_cyan>Click here to get your token",
            [[openUrl("https://bm-itemdb.gitago.dev/account")]],
            "Open account page",
            true
        )
        cecho("\n")
        return nil
    end

    if not itemdb.tokenVerified then
        cecho("<gray>[ITEM-DB]: Token not verified yet. Please check your token & set it again.\n")
        -- return nil 
    end

    -- Show masked token
    local masked = string.rep("*", 8) .. string.sub(itemdb.token, -4)
    cecho("<spring_green>Token set: <white>" .. masked .. " <dim_grey>(last 4 visible)\n")
    return itemdb.token
end


-- User sets their token, we check it and revoke if invalid. We also give user feedback on success / failure and next steps.
function itemdb.setToken(token)
    if not token or token == "" then
        cecho("<red>[ITEM DB] ERROR: Authentication token is not set!\n")
        cecho("<yellow>     Please set it using:  itemdb.token YOUR_TOKEN_HERE\n")

        return false
    end

    checkToken(token)
end





