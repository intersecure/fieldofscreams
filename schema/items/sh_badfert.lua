
ITEM.name = "Bad Fertilizer"
ITEM.model = Model("models/Items/HealthKit.mdl")
ITEM.description = "It's poor quality."

ITEM.functions.Fertilize = {
	OnRun = function(itemTable, ent)

		local client = itemTable.player
		local ent = client:GetEyeTraceNoCursor().Entity
		local plant = ent:GetClass()
		local bFind = string.find(plant, "ix_planter")


		if (bFind) then
			local fertLevel = ent:GetnFertLevel()
			print ("fertlevel:", fertLevel)
			local fertLimit = 100
			if (fertLevel < fertLimit) then
			local flag = true
			hook.Run ("fert", ent, flag)
			client:NotifyLocalized("The soil looks about " .. fertLevel .. " percent fertilized now.")
			else
				client:NotifyLocalized("Too much fertilizer already.")
				return false
			end
		elseif (!bFind) then
			client:NotifyLocalized("Use it on a planter!")
			return false
		end
		
	end
}