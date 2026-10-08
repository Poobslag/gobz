extends Control

var dungeon: Dungeon:
	set(value):
		dungeon = value
		_refresh()

var max_army_bar_width: float:
	set(value):
		max_army_bar_width = value
		_refresh()

func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if dungeon == null:
		return
	
	var goblins_text: String = Dungeons.get_goblins_text(dungeon.recon_army)
	var shown_name: String = dungeon.name
	if dungeon.is_raid_dungeon():
		shown_name = "❗ %s" % [shown_name]
	if dungeon.boss:
		shown_name = "👑 %s" % [shown_name]
	%Label.text = "%s - %s" % [
			shown_name,
			goblins_text,
		]
	%ArmyBar.army = dungeon.recon_army
	%ArmyBar.max_army_bar_width = max_army_bar_width
