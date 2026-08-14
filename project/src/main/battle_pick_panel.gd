extends ColorRect

signal finished

var orders: Array[Goblins.GoblinType] = []
var consecutive_retreat_presses: int = 0

@onready var button_by_type: Dictionary[Goblins.GoblinType, Button] = {
		Goblins.FIRE: %Fire,
		Goblins.WATER: %Water,
		Goblins.GRASS: %Grass,
		Goblins.ANGEL: %Angel,
		Goblins.DEVIL: %Devil,
}

func _ready() -> void:
	for type: Goblins.GoblinType in Goblins.GoblinType.values():
		var button: Button = button_by_type[type]
		button.pressed.connect(_append_order.bind(type))
	%Undo.pressed.connect(_undo_pressed)
	%Done.pressed.connect(_done_pressed)
	
	refresh()


func clear_orders() -> void:
	orders.clear()


func refresh() -> void:
	%YourGoblins.text = ""
	%YourGoblins.text += "You:\n"
	%YourGoblins.text += Goblins.army_bbcode(PlayerData.army)
	
	%EnemyGoblins.text = ""
	if PlayerData.has_current_dungeon():
		%EnemyGoblins.text += "Bad guys:\n"
		%EnemyGoblins.text += Goblins.army_bbcode(PlayerData.get_dungeon().army)
	
	var all_orders_given: bool = true
	var player_army_summary: Army.ArmySummary = PlayerData.army.get_summary()
	for type: Goblins.GoblinType in Goblins.GoblinType.values():
		var button: Button = button_by_type[type]
		button.disabled = player_army_summary.goblins_by_type[type].is_eq(0) or orders.has(type)
		if not button.disabled:
			all_orders_given = false
	%Undo.disabled = orders.is_empty()
	%Done.text = "Retreat" if orders.is_empty() else "Fight!"
	
	var order_string: String = ""
	if not orders.is_empty():
		var order_emojis: Array[String] = []
		for order: Goblins.GoblinType in orders:
			order_emojis.append(Goblins.EMOJIS_BY_GOBLIN_TYPE[order])
		order_string = "(Current orders: %s)" % [", ".join(order_emojis)]
	var query: String = ""
	if consecutive_retreat_presses >= 1:
		query = "Really retreat?"
	elif all_orders_given:
		query = "Your goblins are ready!"
	elif orders.is_empty():
		query = "Who should attack first?"
	else:
		query = "Who should attack next?"
	%QueryLabel.text = "%s %s" % [query, order_string]
	
	var player_disadvantage: bool = PlayerData.has_current_dungeon() \
			and PlayerData.get_dungeon_army().get_total_attack().is_gte(PlayerData.army.get_total_attack())
	%SplashArt.flip_h = player_disadvantage


func _append_order(type: Goblins.GoblinType) -> void:
	consecutive_retreat_presses = 0
	if not orders.has(type):
		orders.push_back(type)
	refresh()


func _undo_pressed() -> void:
	consecutive_retreat_presses = 0
	if not orders.is_empty():
		orders.pop_back()
	refresh()


func _done_pressed() -> void:
	if orders.is_empty():
		consecutive_retreat_presses += 1
	else:
		consecutive_retreat_presses = 0
	
	if consecutive_retreat_presses == 1:
		refresh()
	else:
		finished.emit()
