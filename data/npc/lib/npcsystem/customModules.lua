-- Custom Modules, created to help us in this datapack

--It cannot be named TravelModule because there is already a TravelModule on modules.lua
TravelLib = {}

-- These callback function must be called with parameters.npcHandler = npcHandler in the parameters table or they will not work correctly.
-- Usage:
	-- keywordHandler:addKeyword({'svargrond'}, TravelLib.say, {npcHandler = npcHandler, text = 'Do you seek a passage to Svargrond for %s?', cost = 180, discount = TravelLib.postmanDiscount})

function TravelLib.say(cid, message, keywords, parameters, node)
	local npcHandler = parameters.npcHandler

	if npcHandler == nil then
		error('TravelLib.say called without any npcHandler instance.')
	end

	local onlyFocus = (parameters.onlyFocus == nil or parameters.onlyFocus == true)
	if not npcHandler:isFocused(cid) and onlyFocus then
		return false
	end

	if parameters.storage then
		if Player(cid):getStorageValue(parameters.storage) ~= (parameters.value or 1) then
			npcHandler:say(parameters.wrongValueMessage or 'Never heard about a place like this.', cid)
			npcHandler:resetNpc(cid)
			return true
		end
	end

	local costMessage = '%d gold coins'

	if parameters.cost and parameters.cost > 0 then
		local cost = parameters.cost

		if parameters.discount then
			cost = cost - parameters.discount(cid, cost)
		end

		costMessage = string.format(costMessage, cost)
	else
		costMessage = 'free'
	end

	local parseInfo = {[TAG_PLAYERNAME] = Player(cid):getName()}

	local msg = string.format(npcHandler:parseMessage(parameters.text or parameters.message, parseInfo), costMessage)

	npcHandler:say(msg, cid, parameters.publicize and true)

	if parameters.reset then
		npcHandler:resetNpc(cid)
	elseif parameters.moveup ~= nil then
		npcHandler.keywordHandler:moveUp(parameters.moveup)
	end

	return true
end

-- These callback function must be called with parameters.npcHandler = npcHandler in the parameters table or they will not work correctly.
-- Usage:
	-- keywordHandler:addKeyword({'yes'}, TravelLib.travel, {npcHandler = npcHandler, premium = true, level = 0, cost = 180, discount = TravelLib.postmanDiscount, destination = {x=32341, y=31108, z=6} })

function TravelLib.travel(cid, message, keywords, parameters, node)
	local npcHandler = parameters.npcHandler
	if npcHandler == nil then
		error('TravelLib.travel called without any npcHandler instance.')
	end

	if not npcHandler:isFocused(cid) then
		return false
	end

	local travelCost = parameters.cost
	if travelCost and travelCost > 0 then
		if parameters.discount then
			travelCost = travelCost - parameters.discount(cid, travelCost)
		end
	end

	local player = Player(cid)
	if parameters.premium and not player:isPremium() then
		npcHandler:say('I\'m sorry, but you need a premium account in order to travel onboard our ships.', cid)
	elseif not player:removeMoney(travelCost) then
		npcHandler:say('You don\'t have enough money.', cid)
	elseif parameters.level ~= nil and player:getLevel() < parameters.level then
		npcHandler:say('You must reach level ' .. parameters.level .. ' before I can let you go there.', cid)
	elseif player:isPzLocked() then
		npcHandler:say('First get rid of those blood stains! You are not going to ruin my vehicle!', cid)
	else
		npcHandler:releaseFocus(cid)
		npcHandler:say(parameters.msg or 'Set the sails!', cid)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)

		local destination = parameters.destination
		if type(destination) == 'function' then
			destination = destination(cid)
		end

		-- What a foolish Quest - Mission 3
		if destination ~= Position(32660, 31957, 15) then -- kazordoon steamboat
			if player:getStorageValue(Storage.WhatAFoolishQuest.PieBoxTimer) > os.time() then
				player:setStorageValue(Storage.WhatAFoolishQuest.PieBoxTimer, 1)
			end
		end

		player:teleportTo(destination)
		destination:sendMagicEffect(CONST_ME_TELEPORT)

		if parameters.onTravelCallback then
			parameters.onTravelCallback(cid)
		end
	end

	npcHandler:resetNpc(cid)
	return true
end

function TravelLib.postmanDiscount(cid, cost)
	if Player(cid):getStorageValue(Storage.postman.Rank) >= 3 then
		return 10
	end

	return 0
end

local GreetModule = {}
function GreetModule.greet(cid, message, keywords, parameters)
	if not parameters.npcHandler:isInRange(cid) then
		return true
	end

	if parameters.npcHandler:isFocused(cid) then
		return true
	end

	local parseInfo = { [TAG_PLAYERNAME] = Player(cid):getName() }
	parameters.npcHandler:say(parameters.npcHandler:parseMessage(parameters.text, parseInfo), cid, true)
	parameters.npcHandler:addFocus(cid)
	return true
end

function GreetModule.farewell(cid, message, keywords, parameters)
	if not parameters.npcHandler:isFocused(cid) then
		return false
	end

	local parseInfo = { [TAG_PLAYERNAME] = Player(cid):getName() }
	parameters.npcHandler:say(parameters.npcHandler:parseMessage(parameters.text, parseInfo), cid, true)
	parameters.npcHandler:resetNpc(cid)
	parameters.npcHandler:releaseFocus(cid)
	return true
end

if KeywordHandler then
	-- Adds a keyword which acts as a greeting word
	function KeywordHandler:addGreetKeyword(keys, parameters, condition, action)
		local keys = keys
		keys.callback = FocusModule.messageMatcherDefault
		return self:addKeyword(keys, GreetModule.greet, parameters, condition, action)
	end

	-- Adds a keyword which acts as a farewell word
	function KeywordHandler:addFarewellKeyword(keys, parameters, condition, action)
		local keys = keys
		keys.callback = FocusModule.messageMatcherDefault
		return self:addKeyword(keys, GreetModule.farewell, parameters, condition, action)
	end
end

if StdModule then
	local hints = {
		[-1] = 'If you don\'t know the meaning of an icon on the right side, move the mouse cursor on it and wait a moment.',
		[0] = 'Send private messages to other players by right-clicking on the player or the player\'s name and select \'Message to ....\'. You can also open a \'private message channel\' and type in the name of the player.',
		[1] = 'Use the shortcuts \'SHIFT\' to look, \'CTRL\' for use and \'ALT\' for attack when clicking on an object or player.',
		[2] = 'If you already know where you want to go, click on the automap and your character will walk there automatically if the location is reachable and not too far away.',
		[3] = 'To open or close skills, battle or VIP list, click on the corresponding button to the right.',
		[4] = '\'Capacity\' restricts the amount of things you can carry with you. It raises with each level.',
		[5] = 'Always have a look on your health bar. If you see that you do not regenerate health points anymore, eat something.',
		[6] = 'Always eat as much food as possible. This way, you\'ll regenerate health points for a longer period of time.',
		[7] = 'After you have killed a monster, you have 10 seconds in which the corpse is not moveable and no one else but you can loot it.',
		[8] = 'Be careful when you approach three or more monsters because you only can block the attacks of two. In such a situation even a few rats can do severe damage or even kill you.',
		[9] = 'There are many ways to gather food. Many creatures drop food but you can also pick blueberries or bake your own bread. If you have a fishing rod and worms in your inventory, you can also try to catch a fish.',
		[10] = {'Baking bread is rather complex. First of all you need a scythe to harvest wheat. Then you use the wheat with a millstone to get flour. ...', 'This can be be used on water to get dough, which can be used on an oven to bake bread. Use milk instead of water to get cake dough.'},
		[11] = 'Dying hurts! Better run away than risk your life. You are going to lose experience and skill points when you die.',
		[12] = 'When you switch to \'Offensive Fighting\', you deal out more damage but you also get hurt more easily.',
		[13] = 'When you are on low health and need to run away from a monster, switch to \'Defensive Fighting\' and the monster will hit you less severely.',
		[14] = 'Many creatures try to run away from you. Select \'Chase Opponent\' to follow them.',
		[15] = 'The deeper you enter a dungeon, the more dangerous it will be. Approach every dungeon with utmost care or an unexpected creature might kill you. This will result in losing experience and skill points.',
		[16] = 'Due to the perspective, some objects in Tibia are not located at the spot they seem to appear (ladders, windows, lamps). Try clicking on the floor tile the object would lie on.',
		[17] = 'If you want to trade an item with another player, right-click on the item and select \'Trade with ...\', then click on the player with whom you want to trade.',
		[18] = 'Stairs, ladders and dungeon entrances are marked as yellow dots on the automap.',
		[19] = 'You can get food by killing animals or monsters. You can also pick blueberries or bake your own bread. If you are too lazy or own too much money, you can also buy food.',
		[20] = 'Quest containers can be recognised easily. They don\'t open up regularly but display a message \'You have found ....\'. They can only be opened once.',
		[21] = 'Better run away than risk to die. You\'ll lose experience and skill points each time you die.',
		[22] = 'You can form a party by right-clicking on a player and selecting \'Invite to Party\'. The party leader can also enable \'Shared Experience\' by right-clicking on him- or herself.',
		[23] = 'You can assign spells, the use of items, or random text to \'hotkeys\'. You find them under \'Options\'.',
		[24] = 'You can also follow other players. Just right-click on the player and select \'Follow\'.',
		[25] = 'You can found a party with your friends by right-clicking on a player and selecting \'Invite to Party\'. If you are invited to a party, right-click on yourself and select \'Join Party\'.',
		[26] = 'Only found parties with people you trust. You can attack people in your party without getting a skull. This is helpful for training your skills, but can be abused to kill people without having to fear negative consequences.',
		[27] = 'The leader of a party has the option to distribute gathered experience among all players in the party. If you are the leader, right-click on yourself and select \'Enable Shared Experience\'.',
		[28] = 'There is nothing more I can tell you. If you are still in need of some {hints}, I can repeat them for you.'
	}

	function StdModule.rookgaardHints(cid, message, keywords, parameters, node)
		local npcHandler = parameters.npcHandler
		if npcHandler == nil then
			error("StdModule.say called without any npcHandler instance.")
		end

		if not npcHandler:isFocused(cid) then
			return false
		end

		local player = Player(cid)
		local hintId = player:getStorageValue(Storage.RookgaardHints)
		npcHandler:say(hints[hintId], cid)
		if hintId >= #hints then
			player:setStorageValue(Storage.RookgaardHints, -1)
		else
			player:setStorageValue(Storage.RookgaardHints, hintId + 1)
		end
		return true
	end
end