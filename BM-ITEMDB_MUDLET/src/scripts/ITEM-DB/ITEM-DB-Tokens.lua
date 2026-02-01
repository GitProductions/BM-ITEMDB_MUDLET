-- Item DB - Core / Init 
itemdb = itemdb or {} -- safe creation: if already exists, keep it; else make new empty table
itemdb.token = itemdb.token or "" -- default to empty string (prevents nil errors later)

-- Helper function to check if token has been set at all yet..
function itemdb.checkToken()
    if not itemdb.token or itemdb.token == "" then
        cecho("<red>[ITEM DB] ERROR: Authentication token is not set!\n")
        cecho("<yellow>     Please set it using:  item-db-token YOUR_TOKEN_HERE\n")
        return false
    end

    if #itemdb.token < 30 then
        cecho("<orange>[ITEM DB] Warning: Token looks suspiciously short — might be invalid.\n")
    end

    return true
end


function onHttpPostDone(_, url, body)
  cecho(string.format("<white>url: <dark_green>%s<white>, body: <dark_green>%s", url, body))

  if body.message ~= "valid" then
    cecho("<gray>ITEM-DB:<red> INVALID TOKEN, Please check and try again" .. body.message)
    return
  end

  if body.message == "valid" then
    cecho("<grey>ITEM-DB:<green>Token Verified")
    return 
  end
end

function onHttpPostError(_, url, errorMsg)
    cecho("<gray>ITEM-DB:<red> ERROR VERIFYING TOKEN, Please check your connection and try again " .. errorMsg)
    return false
end

registerAnonymousEventHandler("sysPostHttpDone", onHttpPostDone)
registerAnonymousEventHandler("sysPostHttpError", onHttpPostError)

function itemdb.verifyToken(token)
    -- Making Post request to ItemDB to verify user token
    cecho("<gray>ITEM-DB:<yellow> Verifying User Auth Token... ")
    -- local url = "https://bm-itemdb.gitago.dev/api/tokens/verify"
    local url = "http://localhost:3000/api/tokens/verify"
    local headers = { 
        ["Content-Type"] = "application/json"
        -- ["Authorization"] = "Bearer " .. itemdb.token
    }



    postHTTP("f970b7171a4c9d9aa125ae4fd3b31144ffab19eddbe2d175a21afbbe56d42180", url, headers)
end

-- Give user their token if needed for debug / etc
function itemdb.getToken()
    if not itemdb.token or itemdb.token == "" then
        cecho("<red>[ITEM DB] Token missing — set it with item-db-token <token>\n")
        return nil
    end
    return itemdb.token
end

-- Set User Token
function itemdb.setToken(token)
    if not token then
        cecho("<gray>ITEM-DB:<red> NO TOKEN FOUND, Check and try again")
    end

    

    -- verifytoken doesnt send a response technically.. how do we get it back from our onHttpPostDone ??? 
    -- if itemdb.verifyToken() == true then
    --     cecho("<gray>ITEM-DB:<green> User Auth Token Set Successfully!")
    --     itemdb.token = token
    --     return
    -- end
    itemdb.token = token
    
    itemdb.verifyToken(token)
    -- cecho("<gray>ITEM-DB:<green> User Auth Token Set Successfully!")


end
