extends Control
## [b]Keys:[/b][br]
## 	[kbd]P[/kbd]: Play the save indicator animation.
## 	[kbd]S[/kbd]: Stop the save indicator animation.


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_P:
			SaveIndicator.play()
		KEY_S:
			SaveIndicator.stop()
