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
				Big.mul(ingredient.count, PlayerData.kitchen_multiplier)):
			has_all_ingredients = false
			break
	%Button.disabled = not has_all_ingredients
	
	var button_text: String = ""
	if recipe.size() == 1:
		button_text = "-%s×%s" % [Items.emoji_from_type(recipe[0].type),
				Big.mul(recipe[0].count, PlayerData.kitchen_multiplier).to_aa()]
	elif recipe.size() > 1:
		var input_emojis: String = ""
		var input_count: float = 0.0
		for ingredient: RecipeIngredient in recipe:
			input_emojis += Items.emoji_from_type(ingredient.type)
			input_count += ingredient.count
		button_text = "-%s (%s)" % [input_emojis, Big.mul(input_count, PlayerData.kitchen_multiplier).to_aa()]
	%Button.text = button_text
	
	%Label.text = "Cook %s×%s" % [Items.emoji_from_type(output_type), PlayerData.kitchen_multiplier.to_aa()]


class RecipeIngredient extends Resource:
	var type: Items.Type
	var count: int
	
	func _init(init_type: Items.Type, init_count: int) -> void:
		type = init_type
		count = init_count
