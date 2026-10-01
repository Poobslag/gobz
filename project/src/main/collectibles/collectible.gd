class_name Collectible
extends Node

const LOCKED: PlayerData.CollectibleStatus = PlayerData.CollectibleStatus.LOCKED
const UNLOCKED: PlayerData.CollectibleStatus = PlayerData.CollectibleStatus.UNLOCKED
const REPORTED: PlayerData.CollectibleStatus = PlayerData.CollectibleStatus.REPORTED
const VIEWED: PlayerData.CollectibleStatus = PlayerData.CollectibleStatus.VIEWED

@export var id: String = ""
@export var emoji: String = ""
@export var desc: String = ""

func _ready() -> void:
	add_to_group("collectibles")
	connect_signals()


## Connects signals needed for this achievement. Can be overridden by child scripts to connect other signals.
func connect_signals() -> void:
	PlayerSave.before_save.connect(_on_player_save_before_save)
	PlayerSave.after_load.connect(_on_player_save_after_load)


func disconnect_save_signal() -> void:
	PlayerSave.before_save.disconnect(_on_player_save_before_save)


func disconnect_load_signal() -> void:
	PlayerSave.after_load.disconnect(_on_player_save_after_load)


## Overridden by child classes to return instructions for unlocking the collectible, plus any progress.
func get_instructions() -> String:
	return ""


func with_progress(text: String, current: float, target: float) -> String:
	var result: String = text
	if is_locked():
		result += " (%s/%s)" % [Big.float_to_aa(current), Big.float_to_aa(target)]
	return result


## Overridden by child classes to conditionally unlock the collectible.
func refresh_collectible() -> void:
	pass


func unlock_collectible() -> void:
	if id.is_empty():
		push_error("empty id for collectible '%s'" % [name])
		return
	
	if is_locked():
		PlayerData.collectible_status[id] = UNLOCKED


func is_locked() -> bool:
	return PlayerData.get_collectible_status(id) == LOCKED


func get_status() -> PlayerData.CollectibleStatus:
	return PlayerData.get_collectible_status(id)


func _on_player_save_after_load() -> void:
	if PlayerData.get_collectible_status(id) == LOCKED:
		refresh_collectible()


func _on_player_save_before_save() -> void:
	if PlayerData.get_collectible_status(id) == LOCKED:
		refresh_collectible()
