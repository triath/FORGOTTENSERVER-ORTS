function onUse(cid, item, fromPosition, itemEx, toPosition)
	local player = Player(cid)
	if(item.uid == 3005) then
		if(getPlayerStorageValue(cid, 90) == 30) then
			setPlayerStorageValue(cid, 90, 31)
			doPlayerAddItem(cid, 4857, 1)
			player:sendTextMessage(MESSAGE_INFO_DESCR, "You have found a wrinkled parchment.")
		else
			player:sendTextMessage(MESSAGE_INFO_DESCR, "The chest is empty.")
		end
	end
	return true
end