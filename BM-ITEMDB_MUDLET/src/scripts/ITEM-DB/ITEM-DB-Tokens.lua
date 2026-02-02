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

    local message = data.message
    return message
end

-- Helper function to check if token has been set at all yet..
function itemdb.checkToken(token)
    if not token or token == "" then
        cecho("<red>[ITEM DB] ERROR: Authentication token is not set!\n")
        cecho("<yellow>     Please set it using:  itemdb.token YOUR_TOKEN_HERE\n")

        return false
    end

    if #token < 30 then
        cecho("<orange>[ITEM DB] Warning: Token looks suspiciously short — might be invalid.\n")
        return false
    end

    itemdb.token = token -- setting token as valid and will revoke later if invalid
    
    itemdb.verifyToken(itemdb.token)
    return true
end

function onHttpPostDone(_, url, body)
    -- cecho(string.format("<white>url: <dark_green>%s<white>, body: <dark_green>%s\n", url, body))

    if not body or body == "" then
        cecho("<red>Empty response from server!\n")
        itemdb.token = nil
    end

    local message = parseJson(body)

    if message == "valid" then
        cecho("<grey>ITEM-DB:<green> Token Verified\n")
        -- itemdb.token = token 
        if message == "invalid" then
            cecho("<gray>ITEM-DB:<red> INVALID TOKEN, server said: " .. tostring(message or "no message") .. "\n")

            -- we should set to nil when invalid here to reverse but debugging..
            itemdb.token = nil
        end
    end
end

function onHttpPostError(_, url, errorMsg)
    cecho("<gray>ITEM-DB:<red> ERROR VERIFYING TOKEN, Please check your connection and try again " .. errorMsg .. "\n")
end

registerAnonymousEventHandler("sysPostHttpDone", onHttpPostDone)
registerAnonymousEventHandler("sysPostHttpError", onHttpPostError)

function itemdb.verifyToken(token)
    -- Making Post request to ItemDB to verify user token
    cecho("<gray>ITEM-DB:<yellow> Verifying User Auth Token... ")
    local url = "https://bm-itemdb.gitago.dev/api/tokens/verify"
    -- local url = "http://localhost:3000/api/tokens/verify"
    local headers = {
        ["Content-Type"] = "application/json"
    }

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
    if not token then
        cecho("<gray>ITEM-DB:<red> NO TOKEN FOUND, Check and try again")
    end

    itemdb.checkToken(token)

end
