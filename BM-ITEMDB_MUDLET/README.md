## BlackMUD ItemDB Helper Package

This package was designed for the players of BlackMUD to have an easy way to submit items they have identified into the community item database so that players, new and old are able to quickly look up various items stats and try and determine the high/low for various items due to them having a /random/ stat gen.

This package is new and may have some issues along the way where it may not capture identifies as expected. 


### Installing
Inside of mudlet in the console you can copy/paste this command directly and it will automatically install the package

`lua installPackage("https://github.com/GitProductions/BM-ITEMDB_MUDLET/releases/latest/download/BM-ITEMDB.mpackage")`

### On First Startup

Before you can submit items to the database you will need to create an account via [BlackMUD ItemDB](https://bm-itemdb.gitago.dev/account)

Sign up for an account you can then create an API token which can be used to set up the package.

![Example API Token Request](image.png)

Once you acquire the token from the ItemDB you can hop in Mudlet and type in the command as seen below.
Be sure you are replacing `<TOKEN>` with your actual token from the website.

> `itemdb.set <TOKEN>`


### Whats next?

After thats done, you should have a confirmation message shown and you can begin sending items to the database now directly from Mudlet.. 

You can test it by reciting an identify and await for it to capture. 
You will be prompted with a clickable button/text that will open your inventory. 

When it opens your inventory its going to attach a link to the end of each line.
You will then click the item you just identified and this is how we are capturing the short-description of the item.

After that the submission is complete and you should be able to find it via the website.


---


### Having issues?

Reboot Mudlet, try again!  

If that doesn't work or you have other techincal issues please reach out to Gitago via the discord.



































Test add an item to inventory db 

lua itemdb.inventory.setData({{name = "dagger", condition = "excellent", quantity = 15, desc = nil}, {name = "sword", condition = "excellent", quantity = 1, desc = nil}})

lua 

Check inventory capture length
lua cecho(tostring(#itemdb.inventory.data))

lua for i, row in ipairs(itemdb.inventory.rows) do cecho(i .. ": " .. row.name .. " visible=" .. tostring(row:isVisible()) .. "\n") end





-- saving a table 

how bmudlet does it..
configFile = BlackMUDlet_config.lua
packageName = BlackMUDlet

- saving to it like this..
lua table.save(BlackMUDlet.packagePath .. BlackMUDlet.configFile, BlackMUDlet.Config)

- we can overwrite it with ours..
lua table.save(BlackMUDlet.packagePath .. BlackMUDlet.configFile, itemdb)


- we copy exactly as bmudlet and make the same paths mimicing everything.. and we cannot make it save??
unsure what stopping us..
lua table.save(itemdb.packagePath .. itemdb.configFile, itemdb)

we have for variables
configFile = bmud_itemdb.lua
packageName = BM-ITEMDB


<!-- Need to figure out how to create a proper geyser window that can capture iventory data...


inventory items dont seem to upadte properly when an item is removed.. 
aka we have 6 items in list, one gets put away or dropped.. that item now has its named replaced with 'bag' or the last item inthe list instead of removing it all together...







sample one liner works fine.. 

and a fairly simple plain window works fine too..


///



- Added simple aliases for itemdb.help() and itemdb.checkToken() and update aliases.json to expose them. 
- added an in-client help display (itemdb.help)
- now hiding/showing during item selections
- rename the inventory window and tidy its table formatting.
- Improve token handling: parseJson now returns full data
- token verification registers/cleans HTTP handlers to avoid duplicate calls.
- stronger validation for empty/short tokens 

Modified uninstall messaging with direct reinstall links
