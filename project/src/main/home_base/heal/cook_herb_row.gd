class_name CookHerbRow
extends HBoxContainer

signal pressed

var recipe: Array[RecipeIngredient]:
	set(value):
		recipe = value
		if is_node_ready():
			refresh()

var output_type: Items.Type:
	set(value):
		output_type = value
		if is_node_ready():
			refresh()

func _ready() -> void:
	%Button.pressed.connect(pressed.emit)


func refresh() -> void:
	var has_all_ingredients: bool = true
	for ingredient: RecipeIngredient in recipe:
		if not PlayerData.inventory.has_item(ingredient.type, \
				Big.mul(ingredient.count, PlayerData.supplies_multiplier)):
			has_all_ingredients = false
			break
	%Button.disabled = not has_all_ingredients
	
	var button_text: String = ""
	if recipe.size() == 1:
		button_text = "-%s" % [Items.emoji_from_type(recipe[0].type)]
	elif recipe.size() > 1:
		var input_emojis: String = ""
		for ingredient: RecipeIngredient in recipe:
			input_emojis += Items.emoji_from_type(ingredient.type)
		button_text = "-%s" % [input_emojis]
	%Button.text = button_text
	
	%TopLabel.text = "Cook %s×%s" % [Items.emoji_from_type(output_type), PlayerData.supplies_multiplier.to_aa()]
	
	var bottom_text: String = ""
	for ingredient: RecipeIngredient in recipe:
		if bottom_text:
			bottom_text += "   "
		var inventory_count: Big = PlayerData.inventory.get_count(ingredient.type)
		var recipe_count: Big = Big.mul(ingredient.count, PlayerData.supplies_multiplier)
		var has_ingredient: bool = inventory_count.is_gte(recipe_count)
		bottom_text += "%s %s%s%s" % [
			Items.emoji_from_type(ingredient.type),
			"" if has_ingredient else "[color=b34947]",
			recipe_count.to_aa(),
			"" if has_ingredient else "[/color]",
			]
	%BottomLabel.text = bottom_text


class RecipeIngredient extends Resource:
	var type: Items.Type
	var count: int
	
	func _init(init_type: Items.Type, init_count: int) -> void:
		type = init_type
		count = init_count
