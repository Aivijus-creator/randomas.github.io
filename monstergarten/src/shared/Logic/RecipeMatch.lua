--!strict
-- Recipe matching. Pure.
local Recipes = require(script.Parent.Parent.Config.Recipes)

local RecipeMatch = {}

local function sortedKey(list: { string }): string
	local copy = table.clone(list)
	table.sort(copy)
	return table.concat(copy, "+")
end

-- Exact match for an appliance + ingredient list. allowEvent lets the Cake recipe through.
function RecipeMatch.find(appliance: string, ingredients: { string }, allowEvent: boolean?): Recipes.Recipe?
	local key = sortedKey(ingredients)
	for _, r in Recipes.Recipes do
		if r.Appliance == appliance and (allowEvent or not r.Event) and sortedKey(r.Ingredients) == key then
			return r
		end
	end
	return nil
end

-- Can `ingredient` be added to `current` and still be on the way to some recipe?
function RecipeMatch.canAdd(appliance: string, current: { string }, ingredient: string, allowEvent: boolean?): boolean
	if #current >= Recipes.MaxSlots then
		return false
	end
	local want = table.clone(current)
	table.insert(want, ingredient)
	for _, r in Recipes.Recipes do
		if r.Appliance == appliance and (allowEvent or not r.Event) and #r.Ingredients >= #want then
			-- every wanted ingredient must be available in the recipe (multiset subset)
			local pool = table.clone(r.Ingredients)
			local ok = true
			for _, w in want do
				local idx = table.find(pool, w)
				if idx then
					table.remove(pool, idx)
				else
					ok = false
					break
				end
			end
			if ok then
				return true
			end
		end
	end
	return false
end

-- Feeding result: "Favorite" | "Suitable" | "Cake" | "Raw" | "Wrong" | "NoEat"
function RecipeMatch.feedResult(babyDef: any, itemKind: string, itemId: string): string
	if not babyDef.Eats then
		if babyDef.Id == "Yeti" and itemId == "Ice" then
			return "Ice"
		end
		return "NoEat"
	end
	if itemKind == "Ingredient" then
		if babyDef.FavoriteFood == "ANY" then
			return "Raw"
		end
		if babyDef.Id == "Yeti" and itemId == "Ice" then
			return "Ice"
		end
		return "Wrong"
	end
	if itemId == "Burnt" then
		return "Wrong"
	end
	if babyDef.FavoriteFood == "ANY" then
		return "Favorite"
	end
	if itemId == babyDef.FavoriteFood then
		return "Favorite"
	end
	if itemId == "Cake" then
		return "Cake"
	end
	if itemId == "Porridge" then
		return "Suitable"
	end
	return "Wrong"
end

return RecipeMatch
