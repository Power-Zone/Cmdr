local Util = require(script.Parent.Parent.Shared.Util)
local Players = game:GetService("Players")

local function ShorthandSingle (text, executor)
	if text == "." or text == "me" then
		return {executor}
	elseif text == "random" or text == "?" then
		local players = Players:GetPlayers()
		if #players <= 1 then
			return players
		else
			return {players[math.random(1,#players)]}
		end
	end
end

local function ShorthandMultiple (text, executor)
	if text == "*" or text == "all" then
		return Players:GetPlayers()
	elseif text == "others" then
		local Others = Players:GetPlayers()
		for i = 1, #Others do
			if Others[i] == executor then
				table.remove(Others, i)
				break
			end
		end
		return Others
	elseif (string.sub(text,1,7) == "random[" or string.sub(text,1,2) == "?[") and string.sub(text,string.len(text)) == "]" then
		local maxSize = tonumber(string.match(text,"random%[(.+)%]")) or tonumber(string.match(text,"%?%[(.+)%]"))
		if maxSize and maxSize > 0 then
			local players = {}
			local remainingPlayers = Players:GetPlayers()
			for i = 1,math.min(maxSize,#remainingPlayers) do
				local index = 1
				if #remainingPlayers > 1 then
					index = math.random(1,#remainingPlayers)
				end
				
				table.insert(players,remainingPlayers[i])
				table.remove(remainingPlayers,i)
			end
			
			return players
		end
	end
end

local function CheckShorthands (text, executor, ...)
	for _, func in pairs({...}) do
		local values = func(text, executor)

		if values then return values end
	end
end

local playerType = {
	Transform = function (text, executor)
		local shorthand = CheckShorthands(text, executor, ShorthandSingle)
		if shorthand then
			return shorthand
		end

		local findPlayer = Util.MakeFuzzyFinder(Players:GetPlayers())

		return findPlayer(text)
	end;

	Validate = function (players)
		return #players > 0, "No player with that name could be found."
	end;

	Autocomplete = function (players)
		return Util.GetNames(players)
	end;

	Parse = function (players)
		return players[1]
	end;
}

local playersType = {
	Listable = true;
	Prefixes = "% teamPlayers";

	Transform = function (text, executor)
		local shorthand = CheckShorthands(text, executor, ShorthandSingle, ShorthandMultiple)

		if shorthand then
			return shorthand, true
		end

		local findPlayers = Util.MakeFuzzyFinder(Players:GetPlayers())

		return findPlayers(text)
	end;

	Validate = function (players)
		return #players > 0, "No players were found matching that query."
	end;

	Autocomplete = function (players)
		return Util.GetNames(players)
	end;

	Parse = function (players, returnAll)
		return returnAll and players or { players[1] }
	end;
}

return function (cmdr)
	cmdr:RegisterType("player", playerType)
	cmdr:RegisterType("players", playersType)
end
