function onUse(cid, item, fromPosition, itemEx, toPosition)
	if(item.uid == 3176) then
		if(getPlayerStorageValue(cid, Storage.WrathoftheEmperor.Questline) == 4 or getPlayerStorageValue(cid, Storage.WrathoftheEmperor.Questline) == 5) then
			if(item.itemid == 10782) then
				doTeleportThing(cid, toPosition, true)
				doTransformItem(item.uid, 10783)
			end
		end
	end
	return true
end