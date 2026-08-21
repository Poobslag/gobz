extends VBoxContainer

signal navigate_left_pressed
signal navigate_center_pressed
signal navigate_right_pressed
signal navigate_kitchen_pressed

@export var kitchen: bool = false:
	set(value):
		kitchen = value
		if is_node_ready():
			refresh()

func _ready() -> void:
	%KitchenButton.pressed.connect(navigate_kitchen_pressed.emit)
	
	%LeftButton.pressed.connect(func() -> void:
		HomeBaseData.heal_data.navigate_left()
		navigate_left_pressed.emit())
	
	%RightButton.pressed.connect(func() -> void:
		HomeBaseData.heal_data.navigate_right()
		navigate_right_pressed.emit())
	
	%CenterButton.pressed.connect(navigate_center_pressed.emit)
	
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
