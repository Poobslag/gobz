extends Control

@onready var save_slot_rows: Array[SaveSlotRow] = [
	%SaveSlotRow0,
	%SaveSlotRow1,
	%SaveSlotRow2,
]

func _ready() -> void:
	for save_slot in 3:
		_refresh_save_slot_row(save_slot)
		var save_slot_row: SaveSlotRow = save_slot_rows[save_slot]
		save_slot_row.play_pressed.connect(_on_save_slot_row_play_pressed.bind(save_slot))
		save_slot_row.delete_confirmed.connect(_on_save_slot_row_delete_confirmed.bind(save_slot))


func _refresh_save_slot_row(save_slot: int) -> void:
	var save_slot_row: SaveSlotRow = save_slot_rows[save_slot]
	var summary: Dictionary[String, Variant] = PlayerSave.peek_save_summary(save_slot)
	save_slot_row.desc = summary["desc"]
	match summary["error"]:
		OK:
			save_slot_row.state = SaveSlotRow.State.EXISTS
		ERR_FILE_NOT_FOUND:
			save_slot_row.state = SaveSlotRow.State.NOT_FOUND
		_:
			save_slot_row.state = SaveSlotRow.State.ERROR


func _on_save_slot_row_play_pressed(save_slot: int) -> void:
	if PlayerSave.has_data(save_slot):
		PlayerSave.load_data(save_slot)
	else:
		PlayerSave.save_slot = save_slot
		PlayerData.start_new_game()
		PlayerSave.save_data()
	
	PlayerData.print_gold_history()
	get_tree().change_scene_to_file("res://src/main/home_base/home_base_screen.tscn")


func _on_save_slot_row_delete_confirmed(save_slot: int) -> void:
	PlayerSave.delete_data(save_slot)
	_refresh_save_slot_row(save_slot)
