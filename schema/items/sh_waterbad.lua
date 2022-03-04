
ITEM.name = "Unfiltered Water"
ITEM.model = Model("models/props_junk/garbage_glassbottle002a_chunk01.mdl")
ITEM.description = "A bottle of disgusting unfiltered water."


ITEM.functions.Water = {
	OnRun = function(itemTable, ent)
		local client = itemTable.player
		local ent = client:GetEyeTraceNoCursor().Entity
		local plant = ent:GetClass()

		local bFind = string.find(plant, "ix_planter")
		if (bFind) then
			local water, waterLimit = ent:GetnWaterLevel(), 160
			if (water < waterLimit) then
				local string sWaterType = "shitty"
				hook.Run("water", ent, sWaterType, client)
			else
				itemTable.player:NotifyLocalized("It's absolutely drenched already.")
				return false
			end
		elseif (!bFind) then
			itemTable.player:NotifyLocalized("Use it on a planter!")		
			return false 
		end
	end
}