extends GutHookScript
## Performs initialization steps for Gut tests.

func run() -> void:
	# Prevent tests from overwriting user data.
	PlayerSave.save_folder = "user://test_sav_881"
