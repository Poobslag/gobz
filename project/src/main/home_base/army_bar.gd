extends Control

const FILL_COLORS: Dictionary[Gobs.Type, Color] = {
	Gobs.FIRE: Color("b34947"),
	Gobs.WATER: Color("49b3b1"),
	Gobs.GRASS: Color("5bb362"),
	Gobs.ANGEL: Color("ddebe8"),
	Gobs.DEVIL: Color("744c8c"),
}

const LINE_COLORS: Dictionary[Gobs.Type, Color] = {
	Gobs.FIRE: Color("6b304b"),
	Gobs.WATER: Color("428ea1"),
	Gobs.GRASS: Color("458a61"),
	Gobs.ANGEL: Color("b4c9cc"),
	Gobs.DEVIL: Color("493961"),
}

var army: Army:
	set(value):
		army = value
		_recalculate_layout()

var _bar_widths: Array[float] = []
var _bar_types: Array[Gobs.Type] = []

func _ready() -> void:
	_recalculate_layout()


func _draw() -> void:
	var bar_start: Vector2 = Vector2(0, 0)
	for i: int in _bar_widths.size():
		var bar_width: float = _bar_widths[i]
		var fill_color: Color = FILL_COLORS[_bar_types[i]]
		var line_color: Color = LINE_COLORS[_bar_types[i]]
		var outline_rect: Rect2 = Rect2(bar_start, Vector2(bar_width, size.y))
		
		# shift bar below the text
		outline_rect = outline_rect.grow_individual(0, -14, 0, 2)
		
		# draw dark outer rectangle
		draw_rect(outline_rect, line_color)
		
		# draw light inner rectangle
		var inner_rect: Rect2 = outline_rect.grow_individual(
			-2 if i == 0 else 0, -2,
			-2 if i == _bar_widths.size() -1 else 0, -2)
		draw_rect(inner_rect, fill_color)
		
		# draw emoji
		if bar_width > 18:
			draw_string(Utils.EMOJI_FONT, outline_rect.get_center() + Vector2(-6, 4),
					Gobs.emoji_from_type(_bar_types[i]), HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		
		bar_start.x += bar_width


func _recalculate_layout() -> void:
	if PlayerData.dungeons.is_empty() or army == null or army.is_empty():
		return
	
	var boss_dungeon: Dungeon = PlayerData.get_boss_dungeon()
	var boss_dungeon_goblins: float = boss_dungeon.recon_army.get_total_goblins().to_float()
	var bar_width: float = remap(army.get_total_goblins().to_float(), 0, boss_dungeon_goblins, 100, 440)
	
	_bar_types.clear()
	_bar_widths.clear()
	var type_summaries: Array[Dictionary] = Dungeons.get_type_summaries(army)
	for summary: Dictionary[Variant, Variant] in type_summaries:
		_bar_types.append(summary["type"])
		_bar_widths.append( \
				bar_width * summary["goblins"].to_float() / army.get_total_goblins().to_float())
