extends Control

var dungeon: Dungeon:
	set(value):
		dungeon = value
		_refresh()

func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if dungeon == null:
		return
	
	var goblins_text: String = Dungeons.get_goblins_text(dungeon.recon_army)
	%Label.text = "%s - %s" % [
			dungeon.name,
			goblins_text,
		]
	%ArmyBar.army = dungeon.recon_army
