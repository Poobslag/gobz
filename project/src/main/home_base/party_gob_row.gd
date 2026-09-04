class_name PartyGobRow
extends VBoxContainer

var gob: Gob:
	set(value):
		gob = value
		if is_node_ready():
			_refresh()

func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if gob == null:
		%Name.text = ""
		%Event.visible = false
		return
	
	%Name.text = "%s %s %s" % [Gobs.emoji_from_type(gob.type), gob.name, Gobs.morale_bbcode(gob.morale.value)]
	var last_event: MoraleEvent = gob.morale.get_last_event()
	if last_event:
		%Event.visible = true
		%Event.text = "\t\t[i](%s, Day %s, [color=%s][b]%s%s[/b][/color])[/i]" % \
				[last_event.get_desc(gob), last_event.day, \
				"red" if last_event.delta < 0 else "green", "" if last_event.delta < 0 else "+",
				roundi(last_event.delta)]
	else:
		%Event.visible = false
