extends Collectible

func connect_signals() -> void:
	super.connect_signals()
	disconnect_save_signal()
	disconnect_load_signal()
	
	Events.battle_finished.connect(_on_events_battle_finished)


func get_instructions() -> String:
	return "Defeat a raid on the first day it's announced."


func _on_events_battle_finished(dungeon: Dungeon, result: Events.BattleResult) -> void:
	if dungeon.raid_days == DungeonDirector.RAID_DAYS_START \
			and result in [Events.BattleResult.VICTORY, Events.BattleResult.MUTUAL_DEFEAT]:
		unlock_collectible()
