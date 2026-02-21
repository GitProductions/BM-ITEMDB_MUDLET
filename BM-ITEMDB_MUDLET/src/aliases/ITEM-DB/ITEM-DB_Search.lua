-- alias: ITEM-DB-Search

local searchItem = matches[2] or ""
searchItem = searchItem:gsub("^%s+", ""):gsub("%s+$", "")

if searchItem == "" then
    itemdb.sendStatusMessage("Search term required. Usage: itemdb.search bracer", "red")
    return
end

itemdb.searchItems(searchItem)
