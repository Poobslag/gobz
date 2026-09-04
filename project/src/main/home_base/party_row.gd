class_name PartyRow
extends HBoxContainer

signal pressed

var party: Party:
	set(value):
		party = value
		_dirty = true

var item_count: Big = Big.ZERO:
	set(value):
		item_count = value
		_dirty = true

var item_type: Items.Type = Items.Type.STRONG_MEDICINE:
	set(value):
		item_type = value
		_dirty = true

var likers: Array[Gobs.Type] = []:
	set(value):
		likers = value
		_dirty = true

var dislikers: Array[Gobs.Type] = []:
	set(value):
		dislikers = value
		_dirty = true

var _dirty: bool = true

func _ready() -> void:
	%Button.pressed.connect(pressed.emit)


func _process(_delta: float) -> void:
	if _dirty:
		_dirty = false
		refresh()


func refresh() -> void:
	if HomeBaseData.party_data.partied:
		%Button.disabled = true
		%Button.text = "-"
	else:
		%Button.disabled = PlayerData.inventory.get_count(item_type).is_lt(item_count)
		%Button.text = "%s%s" % [Items.emoji_from_type(item_type), item_count.to_aa()]
	
	var new_morale_text: String = ""
	if likers:
		new_morale_text += "👍%s" % [_emoji_string(likers)]
	if dislikers:
		if new_morale_text:
			new_morale_text += "\n"
		new_morale_text += "👎%s" % [_emoji_string(dislikers)]
	%MoraleEffect.text = new_morale_text
	%Prompt.text = "%s [b][color=green]+%s[/color][/b]" % [party.prompt, [3, 6, 10][PlayerData.party_multiplier]]


func _emoji_string(types: Array[Gobs.Type]) -> String:
	var result: String = ""
	var sorted_types: Array[Gobs.Type] = types.duplicate()
	sorted_types.sort()
	for type: Gobs.Type in sorted_types:
		result += Gobs.emoji_from_type(type)
	return result
