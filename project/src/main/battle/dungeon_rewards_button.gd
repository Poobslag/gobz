class_name DungeonRewardsButton
extends Button

const LAYOUT_ARRANGEMENT: Array[String] = [
	" 9 5 2 7 b",
	"8 4 3 1 6 a",
]

const LAYOUT_ARRANGEMENT_BOSS: Array[String] = [
	" w u t v x ",
	"r p n o q s",
	" m i g h k ",
	"l f d c e j",
	" 9 5 2 7 b ",
	"8 4 3 1 6 a",
]

const FONT_SIZE_BY_EMOJI: Dictionary[String, int] = {
	"💰": 36,
	"🔔": 20,
}

const ORDERED_CHARS := "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

static var _index_by_char: Dictionary[String, int] = {}
static var _static_layout_data: Array[Vector2] = []
static var _static_layout_data_boss: Array[Vector2] = []

@export var reward_icons: String = "":
	set(value):
		reward_icons = value
		_recalculate_layout()
		queue_redraw()

@export var boss: bool = false:
	set(value):
		boss = value
		_recalculate_layout()
		queue_redraw()

var _layout_data: Array[Array] = []
var _shown_reward_icons: String = ""

static func _static_init() -> void:
	# map from the string constants in 'LAYOUT_ORDER' to the
	for i in ORDERED_CHARS.length():
		_index_by_char[ORDERED_CHARS[i]] = i
	_static_layout_data = _positions_from_picture(LAYOUT_ARRANGEMENT)
	_static_layout_data_boss = _positions_from_picture(LAYOUT_ARRANGEMENT_BOSS)


func _ready() -> void:
	_recalculate_layout()


func _draw() -> void:
	for i in _layout_data.size():
		var emoji_position: Vector2 = _layout_data[i][0]
		var emoji: String = _layout_data[i][1]
		var font_size: int = FONT_SIZE_BY_EMOJI.get(emoji, 24)
		draw_string(Utils.EMOJI_FONT, emoji_position, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)


func _recalculate_layout() -> void:
	if reward_icons.length() == 0:
		_shown_reward_icons = ""
		_layout_data = []
		return
	
	custom_minimum_size.y = 46 if boss else 31
	size.y = 46 if boss else 31
	
	_shown_reward_icons = reward_icons
	var max_icons: int = _static_layout_data_boss.size() if boss else _static_layout_data.size()
	if _shown_reward_icons.length() > max_icons:
		_shown_reward_icons = subsample_string(_shown_reward_icons, max_icons)
	
	_layout_data.resize(_shown_reward_icons.length())
	var layout_positions: Array[Vector2] = _static_layout_data_boss if boss else _static_layout_data
	for i in _shown_reward_icons.length():
		_layout_data[i] = [layout_positions[i], _shown_reward_icons[i]]
	
	var icon_bounds: Rect2 = Rect2(_layout_data[0][0], Vector2.ZERO)
	for datum: Array[Variant] in _layout_data:
		icon_bounds = icon_bounds.expand(datum[0])
	
	var icon_spread: Vector2 = Vector2(15, 8) if "🔔" in _shown_reward_icons else Vector2(25, 8)
	if icon_bounds.size.x <= 1.0:
		icon_spread *= 1.5
	elif icon_bounds.size.x <= 2.0:
		icon_spread *= 1.2
	elif icon_bounds.size.x <= 4.0:
		icon_spread *= 1.1
	var icon_offset: Vector2 = Vector2(-10, 4) if "🔔" in _shown_reward_icons else Vector2(-19, 6)
	
	for datum: Array[Variant] in _layout_data:
		datum[0] = (datum[0] - icon_bounds.get_center()) * icon_spread + size * 0.5 + icon_offset
	
	# sort bottom icons to be drawn last
	_layout_data.sort_custom(func(a: Array[Variant], b: Array[Variant]) -> bool:
		return a[0].y < b[0].y)


static func subsample_string(s: String, count: int) -> String:
	if count == 0:
		return ""
	
	var result: String = ""
	var step: float = float(s.length()) / count
	var start: float = 0.5 * step
	for i: int in count:
		result += s[floori(start + i * step)]
	return result


## Converts an ASCII picture into a list of coordinates.[br]
## [br]
## Example input:[br]
## 	["  1  ",[br]
## 	 "2   4",[br]
## 	 "  3  "][br]
## [br]
## The ascii picture is an array of strings, where each string corresponds to a row in the picture and each character
## corresponds to a column in the picture. Characters like '1', '2' and '3' correspond to positions of cards.
## Characters like ' ' correspond to empty space.[br]
## [br]
## The response is a list of coordinates like [[1, 0], [0, 0.5]] corresponding to the positions of cards, where
## [2, 0.5] corresponds to a card in the third column, and half-way between the first and second rows. Coordinates in
## the ascii picture are divided by two to allow for cards to fall between rows/columns for more complex pictures.[br]
static func _positions_from_picture(picture: Array[String]) -> Array[Vector2]:
	# key: (int) char index like '1' or '11' corresponding to the picture characters '1' or 'b'
	# value: (Vector2) coordinate in the picture
	var coords_by_char_index: Dictionary[int, Vector2] = {}
	
	# convert the picture to a key/value
	for pic_y: int in picture.size():
		var row_string: String = picture[pic_y]
		for pic_x: int in row_string.length():
			var pic_char: String = row_string[pic_x]
			if pic_char in _index_by_char:
				coords_by_char_index[_index_by_char[pic_char]] = Vector2(pic_x, pic_y)
	
	if coords_by_char_index:
		# determine the leftmost and uppermost card positions
		var min_coord: Vector2 = coords_by_char_index.values()[0]
		for char_index: int in coords_by_char_index:
			var coord: Vector2 = coords_by_char_index[char_index]
			min_coord.x = min(min_coord.x, coord.x)
			min_coord.y = min(min_coord.y, coord.y)
		
		# adjust card positions so that the leftmost and uppermost cards are at position zero
		for char_index: int in coords_by_char_index:
			var coord: Vector2 = coords_by_char_index[char_index]
			coords_by_char_index[char_index] = coord - min_coord
	
	var sorted_char_indexes: Array[int] = coords_by_char_index.keys()
	sorted_char_indexes.sort()
	
	# convert picture positions like [2, 7] into card positions like [1.0, 3.5]
	var positions: Array[Vector2] = []
	for char_index: int in sorted_char_indexes:
		positions.append(coords_by_char_index[char_index] * Vector2(0.5, 0.5))
	
	return positions
