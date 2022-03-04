
ITEM.name = "Fruit"
ITEM.width = 1
ITEM.height = 1
ITEM.model = Model("models/props/de_inferno/crate_fruit_break_gib2.mdl")
ITEM.description = "This fruit went directly from rock hard to overripe before your very eyes, but it seems okay to eat."


ITEM.functions.Eat = {
	OnRun = function(itemTable, ent)
		client = itemTable.player
        print("fun")
	end
}