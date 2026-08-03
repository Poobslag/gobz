extends ColorRect

signal finished

func _ready() -> void:
	%YourGoblins.text = ""
	%YourGoblins.text += "Your forces:\n\n"
	%YourGoblins.text += Goblins.army_bbcode(PlayerData.army)
	
	%EnemyGoblins.text = ""
	%EnemyGoblins.text += "Enemy forces:\n\n"
	%EnemyGoblins.text += Goblins.army_bbcode(PlayerData.dungeons[PlayerData.current_dungeon].army)
