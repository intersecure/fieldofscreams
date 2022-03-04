
ITEM.name = "Seeds"
ITEM.width = 1
ITEM.height = 1
ITEM.model = Model("models/props_2fort/lunchbag.mdl")
ITEM.description = "A weird seed."


ITEM.functions.Plant = {
	OnRun = function(itemTable, ent)
		client = itemTable.player
		ent = client:GetEyeTraceNoCursor().Entity
		plant = ent:GetClass()
		bFind = string.find(plant, "ix_planter")
		if (bFind) then
			local planted = ent:GetbPlanted()

			if (!planted) then
			hook.Run ( "planted", ent )
			elseif (planted) then
				client:NotifyLocalized("Something is already growing here.")
				return false
			end						
		elseif (!bFind) then
			client:NotifyLocalized("Use it on a planter!")		
			return false 
		end

	end
}