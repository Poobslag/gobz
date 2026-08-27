extends VBoxContainer

signal before_move

signal move_left
signal move_center
signal move_right
signal move_kitchen

@export var kitchen: bool = false:
	set(value):
		kitchen = value
		if is_node_ready():
			refresh()

func _ready() -> void:
	%KitchenButton.pressed.connect(move_kitchen.emit)
	
	%LeftButton.pressed.connect(func() -> void:
		before_move.emit()
		HomeBaseData.heal_data.move_left()
		move_left.emit())
	
	%RightButton.pressed.connect(func() -> void:
		before_move.emit()
		HomeBaseData.heal_data.move_right()
		move_right.emit())
	
	%CenterButton.pressed.connect(func() -> void:
		before_move.emit()
		move_center.emit())
	
	if kitchen:
		%KitchenButton.disabled = true
		%CenterButton.disabled = false
	else:
		%KitchenButton.disabled = false
		%CenterButton.disabled = true


func refresh() -> void:
	if HomeBaseData.heal_data.get_groups().size() <= 1:
		%LeftButton.visible = false
		%RightButton.visible = false
		%Spacer3.visible = true
		%Spacer4.visible = true
	else:
		%LeftButton.visible = true
		%RightButton.visible = true
		%Spacer3.visible = false
		%Spacer4.visible = false
	
	if HomeBaseData.heal_data.get_groups().size() >= 2:
		var left_group: HealData.HealGroup = HomeBaseData.heal_data.get_left_group()
		%LeftButton.text = "Visit %s" % [_get_gob_string(left_group)]
		
		var right_group: HealData.HealGroup = HomeBaseData.heal_data.get_right_group()
		%RightButton.text = "Visit %s" % [_get_gob_string(right_group)]
	
	var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
	if kitchen:
		%CenterButton.text = "Visit %s" % [_get_gob_string(center_group)]
	else:
		%CenterButton.text = "Visiting %s" % [_get_gob_string(center_group)]


func _get_gob_string(heal_group: HealData.HealGroup) -> String:
	var gob_string: String = "Nobody"
	if heal_group != null:
		var gob: Gob = heal_group.front()
		gob_string = "%s %s" % [Gobs.emoji_from_type(gob.type), gob.name]
	return gob_string
