extends Node

@export var verbose_stdout_mode := false

func _ready() -> void:
	if "--gobz-verbose" in OS.get_cmdline_user_args():
		verbose_stdout_mode = true


func print_verbose(s: String) -> void:
	if verbose_stdout_mode:
		print(s)
