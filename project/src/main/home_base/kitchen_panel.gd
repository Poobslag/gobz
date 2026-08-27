extends ColorRect

signal kitchen_exited

const MAX_MULTIPLIER: float = 1e300

func _ready() -> void:
	%HealNavigator.move_left.connect(kitchen_exited.emit)
	%HealNavigator.move_center.connect(kitchen_exited.emit)
	%HealNavigator.move_right.connect(kitchen_exited.emit)
	
	%CookHerb1Row.recipe = [CookHerbRow.RecipeIngredient.new(Items.HERB_1, 2)] as Array[CookHerbRow.RecipeIngredient]
	%CookHerb1Row.output_type = Items.WEAK_MEDICINE
	
	%CookHerb2Row.recipe = [CookHerbRow.RecipeIngredient.new(Items.HERB_2, 2)] as Array[CookHerbRow.RecipeIngredient]
	%CookHerb2Row.output_type = Items.WEAK_MEDICINE
	
	%CookHerb3Row.recipe = [CookHerbRow.RecipeIngredient.new(Items.HERB_3, 2)] as Array[CookHerbRow.RecipeIngredient]
	%CookHerb3Row.output_type = Items.WEAK_MEDICINE
	
	%CookStrongMedicineRow.recipe = [
		CookHerbRow.RecipeIngredient.new(Items.HERB_1, 2),
		CookHerbRow.RecipeIngredient.new(Items.HERB_2, 3),
		CookHerbRow.RecipeIngredient.new(Items.HERB_3, 5),
	] as Array[CookHerbRow.RecipeIngredient]
	%CookStrongMedicineRow.output_type = Items.STRONG_MEDICINE
	
	var buy_item_rows: Array[Node] = get_tree().get_nodes_in_group("buy_item_rows").filter(is_ancestor_of)
	for buy_item_row: BuyItemRow in buy_item_rows:
		buy_item_row.pressed.connect(_on_buy_item_row_pressed.bind(buy_item_row))
	var cook_herb_rows: Array[Node] = get_tree().get_nodes_in_group("cook_herb_rows").filter(is_ancestor_of)
	for cook_herb_row: CookHerbRow in cook_herb_rows:
		cook_herb_row.pressed.connect(_on_cook_herb_row_pressed.bind(cook_herb_row))
	
	%MultiplyButton.pressed.connect(_adjust_multiplier.bind(10.0))
	%DivideButton.pressed.connect(_adjust_multiplier.bind(1/10.0))
	
	refresh()


func refresh() -> void:
	%InventoryLabel.refresh()
	%HealNavigator.refresh()
	var buy_item_rows: Array[Node] = get_tree().get_nodes_in_group("buy_item_rows").filter(is_ancestor_of)
	for buy_item_row: BuyItemRow in buy_item_rows:
		buy_item_row.refresh()
	var cook_herb_rows: Array[Node] = get_tree().get_nodes_in_group("cook_herb_rows").filter(is_ancestor_of)
	for cook_herb_row: CookHerbRow in cook_herb_rows:
		cook_herb_row.refresh()
	
	# if you have $1,000, or 1,000 of any item, you can increase the multiplier to 1,000
	var multiply_button_disabled: bool = true
	if multiply_button_disabled == true:
		if PlayerData.gold.is_gte(PlayerData.kitchen_multiplier.to_float() * 10):
			multiply_button_disabled = false
	if multiply_button_disabled == true:
		for type: Items.Type in PlayerData.inventory.items:
			if PlayerData.inventory.get_count(type).is_gte(PlayerData.kitchen_multiplier.to_float() * 10):
				multiply_button_disabled = false
				break
	
	%MultiplyButton.disabled = multiply_button_disabled
	%DivideButton.disabled = PlayerData.kitchen_multiplier.is_lte(1)


func _adjust_multiplier(factor: float) -> void:
	@warning_ignore("narrowing_conversion")
	PlayerData.kitchen_multiplier = Big.clamp(PlayerData.kitchen_multiplier.to_float() * factor, 1, MAX_MULTIPLIER)
	refresh()


func _on_cook_herb_row_pressed(cook_herb_row: CookHerbRow) -> void:
	# verify the player has the required ingredient
	var has_all_ingredients: bool = true
	for ingredient: CookHerbRow.RecipeIngredient in cook_herb_row.recipe:
		var ingredients_available: Big = PlayerData.inventory.get_count(ingredient.type)
		var ingredients_needed: Big = Big.mul(ingredient.count, PlayerData.kitchen_multiplier)
		if ingredients_available.is_lt(ingredients_needed):
			has_all_ingredients = false
			break
	if not has_all_ingredients:
		return
	
	# remove the ingredients and add the output
	for ingredient: CookHerbRow.RecipeIngredient in cook_herb_row.recipe:
		var ingredients_needed: Big = Big.mul(ingredient.count, PlayerData.kitchen_multiplier)
		PlayerData.inventory.take_item(ingredient.type, ingredients_needed)
	PlayerData.inventory.add_item(cook_herb_row.output_type, PlayerData.kitchen_multiplier)
	refresh()


func _on_buy_item_row_pressed(buy_item_row: BuyItemRow) -> void:
	# verify the player has enough money
	if buy_item_row.get_cost().is_gt(PlayerData.gold):
		return
	
	PlayerData.take_gold(buy_item_row.get_cost())
	PlayerData.inventory.add_item(buy_item_row.type, PlayerData.kitchen_multiplier)
	refresh()
