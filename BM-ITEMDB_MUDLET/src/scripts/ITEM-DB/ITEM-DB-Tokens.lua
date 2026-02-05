-- Item DB - Core / Init 
itemdb = itemdb or {}
itemdb.token = itemdb.token or ""

function parseJson(body)
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

-- Helper function to check if token has been set at all yet..
function itemdb.checkToken(token)
    if #token < 30 then
        cecho("<orange>[ITEM DB] Warning: Token looks suspiciously short — might be invalid.\n")
        return false
    end

    itemdb.token = token -- setting token as valid and will revoke later if invalid

    itemdb.verifyToken(itemdb.token)
    return true
end

function onHttpPostDone(_, url, body)
    if itemdb.debugMode then
        cecho(string.format("<white>url: <dark_green>%s<white>, body: <dark_green>%s\n", url, body))
    end 

    if not body or body == "" then
        cecho("<red>Empty response from server!\n")
        itemdb.token = nil
    end

    -- Parsing our HTTPPost response
    local data = parseJson(body)

    -- If its a token response, it will have data.message 
    if data and data.message == "valid" then
        cecho("\n<grey>ITEM-DB:<green> Token Verified\n")
        -- itemdb.token = token 
        if data.message == "invalid" then
            cecho("<gray>ITEM-DB:<red> INVALID TOKEN, server said: " .. tostring(data.message or "no message") .. "\n")

            -- we should set to nil when invalid here to reverse but debugging..
            itemdb.token = nil
        end
    end

    -- if its an item submission it will have data.itemUrl or data.itemUrls
    if data and (data.itemUrl or data.itemUrls) then
        local url = data.itemUrl or data.itemUrls[1]

        cecho("<yellow>[ITEMDB] <gray>- <green><b>Submitted successfully!</b>\n")

        -- clickable + selectable text
        cechoLink("<yellow>[ITEMDB] <gray>- <cyan>" .. url .. "\n", function()
            openUrl(url)
        end, "Item-DB: Click to open link", true)
    end

end

function onHttpPostError(_, url, errorMsg)
    cecho("<gray>ITEM-DB:<red> ItemDB may be down, please check and report to Gitago if issue persists " .. errorMsg .. "\n")
end


function itemdb.verifyToken(token)

    -- Making Post request to ItemDB to verify user token
    cecho("<gray>ITEM-DB:<yellow> Verifying User Auth Token... ")
    local url = "https://bm-itemdb.gitago.dev/api/tokens/verify"
    -- local url = "http://localhost:3000/api/tokens/verify"
    local headers = {
        ["Content-Type"] = "application/json"
    }

    -- assuring we close/kill handlers set prior
    if tokenVerifyHandlerID then killAnonymousEventHandler(tokenVerifyHandlerID) end
    tokenVerifyHandlerID = registerAnonymousEventHandler("sysPostHttpDone", onHttpPostDone, true)

    if tokenErrorHandlerID then killAnonymousEventHandler(tokenErrorHandlerID) end
    tokenErrorHandlerID = registerAnonymousEventHandler("sysPostHttpError", onHttpPostError, true)

    postHTTP(token, url, headers)
end




-- Give user their token if needed for debug / etc
function itemdb.getToken()
    cecho("Your token is: " .. (itemdb.token or "<none>") .. "\n")
    if not itemdb.token or itemdb.token == "" then
        cecho("<red>[ITEM DB] Token missing — set it with itemdb.token <token>\n")
        return nil
    end
    return itemdb.token
end

-- Set User Token
-- user token gets set, but revoked if the verification fails
function itemdb.setToken(token)
    if not token or token == "" then
        cecho("<red>[ITEM DB] ERROR: Authentication token is not set!\n")
        cecho("<yellow>     Please set it using:  itemdb.token YOUR_TOKEN_HERE\n")

        return false
    end

    itemdb.checkToken(token)

end
