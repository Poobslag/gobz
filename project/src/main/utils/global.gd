extends Node

const SPEECH_CHARACTER_DELAY: float = 0.05
const SPEECH_LINE_DELAY: float = 0.50

@export var verbose_stdout_mode := false

func _ready() -> void:
	if "--gobz-verbose" in OS.get_cmdline_user_args():
		verbose_stdout_mode = true


func print_verbose(s: String) -> void:
	if verbose_stdout_mode:
		print(s)
