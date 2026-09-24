extends Node

@export var verbose_stdout_mode := false

## Game's main viewport size, as specified in the project settings.
var window_size: Vector2i = Vector2i(
	ProjectSettings.get_setting("display/window/size/viewport_width") as int,
	ProjectSettings.get_setting("display/window/size/viewport_height") as int)

func _ready() -> void:
	if "--gobz-verbose" in OS.get_cmdline_user_args():
		verbose_stdout_mode = true


func print_verbose(s: String) -> void:
	if verbose_stdout_mode:
		print(s)
