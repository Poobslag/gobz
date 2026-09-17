extends Control
## [b]Keys:[/b][br]
## 	[kbd]B[/kbd]: Toggle boss[br]
## 	[kbd]G[/kbd]: Increase gold reward (coins)[br]
## 	[kbd]Shift + G[/kbd]: Decrease gold reward (coins)[br]
## 	[kbd]H[/kbd]: Increase gold reward (bags)[br]
## 	[kbd]Shift + H[/kbd]: Decrease gold reward (bags)[br]
## 	[kbd]C[/kbd]: Increase cake reward[br]
## 	[kbd]Shift + C[/kbd]: Decrease cake reward[br]
## 	[kbd]Z[/kbd]: Massively increase rewards[/br]
## 	[kbd]Shift+Z[/kbd]: Erase rewards[/br]

var gold_icon: String = "💰"
var cake_icon_count: int = 1
var gold_icon_count: int = 5

func _ready() -> void:
	refresh_reward_icons()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_B:
			%RewardsButton.boss = not %RewardsButton.boss
		KEY_G:
			gold_icon_count += -1 if Input.is_key_pressed(KEY_SHIFT) else 1
			gold_icon_count = clampi(gold_icon_count, 0, 50)
			gold_icon = "🔔"
			refresh_reward_icons()
		KEY_H:
			gold_icon_count += -1 if Input.is_key_pressed(KEY_SHIFT) else 1
			gold_icon_count = clampi(gold_icon_count, 0, 50)
			gold_icon = "💰"
			refresh_reward_icons()
		KEY_C:
			cake_icon_count += -1 if Input.is_key_pressed(KEY_SHIFT) else 1
			cake_icon_count = clampi(cake_icon_count, 0, 50)
			refresh_reward_icons()
		KEY_Z:
			gold_icon_count = 0 if Input.is_key_pressed(KEY_SHIFT) else 50
			cake_icon_count = 0 if Input.is_key_pressed(KEY_SHIFT) else 50
			refresh_reward_icons()


func refresh_reward_icons() -> void:
	%RewardsButton.reward_icons = gold_icon.repeat(gold_icon_count) + "🍰".repeat(cake_icon_count)
