extends Control

func _ready() -> void:
	%PickPanel.finished.connect(_on_pick_panel_finished)
	%WatchPanel.finished.connect(_on_watch_panel_finished)


func _on_pick_panel_finished() -> void:
	%PickPanel.hide()
	%WatchPanel.show()


func _on_watch_panel_finished() -> void:
	get_tree().change_scene_to_file("res://src/main/home_base_screen.tscn")
