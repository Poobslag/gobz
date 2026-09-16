@tool
class_name CostDisplay
extends Control

enum Amount {
	COINS_1,
	COINS_2,
	COINS_3,
	COINS_5,
	BAGS_1,
	BAGS_2,
	BAGS_3,
	BAGS_5,
}

const COINS_1: Amount = Amount.COINS_1
const COINS_2: Amount = Amount.COINS_2
const COINS_3: Amount = Amount.COINS_3
const COINS_5: Amount = Amount.COINS_5
const BAGS_1: Amount = Amount.BAGS_1
const BAGS_2: Amount = Amount.BAGS_2
const BAGS_3: Amount = Amount.BAGS_3
const BAGS_5: Amount = Amount.BAGS_5

const OFFSETS_BY_AMOUNT: Dictionary[Amount, Array] = {
	COINS_1: [Vector2(-10, 5)],
	COINS_2: [Vector2(-16, 3), Vector2(-4, 7)],
	COINS_3: [Vector2(-10, 3), Vector2(-22, 7), Vector2(2, 7)],
	COINS_5: [Vector2(-20, 3), Vector2(0, 3), Vector2(-30, 7), Vector2(-10, 7), Vector2(10, 7)],
	BAGS_1: [Vector2(-20, 6)],
	BAGS_2: [Vector2(-30, 4), Vector2(-10, 8)],
	BAGS_3: [Vector2(-20, 4), Vector2(-40, 8), Vector2(0, 8)],
	BAGS_5: [Vector2(-35, 4), Vector2(-5, 4), Vector2(-50, 8), Vector2(-20, 8), Vector2(10, 8)],
}

const WIDTH_BY_AMOUNT: Dictionary[Amount, float] = {
	COINS_1: 14,
	COINS_2: 27,
	COINS_3: 39,
	COINS_5: 55,
	BAGS_1: 25,
	BAGS_2: 45,
	BAGS_3: 65,
	BAGS_5: 85,
}

const COST_THRESHOLDS: Array[Array] = [
	[0.01, COINS_1],
	[0.03, COINS_2],
	[0.05, COINS_3],
	[0.07, COINS_5],
	[0.10, BAGS_1],
	[0.30, BAGS_2],
	[0.50, BAGS_3],
	[1.00, BAGS_5],
]

const DISABLED_COLOR: Color = Color("888888")

@export var amount: Amount:
	set(value):
		amount = value
		queue_redraw()

@export var disabled: bool:
	set(value):
		disabled = value
		_refresh_disabled()

@export var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER:
	set(value):
		alignment = value
		queue_redraw()

func _draw() -> void:
	match amount:
		COINS_1, COINS_2, COINS_3, COINS_5:
			_draw_emojis("🔔", 20, OFFSETS_BY_AMOUNT[amount])
		BAGS_1, BAGS_2, BAGS_3, BAGS_5:
			_draw_emojis("💰", 36, OFFSETS_BY_AMOUNT[amount])


func _draw_emojis(emoji: String, font_size: int, offsets: Array[Variant]) -> void:
	var center: Vector2 = size / 2
	match alignment:
		HORIZONTAL_ALIGNMENT_LEFT:
			center.x = WIDTH_BY_AMOUNT[amount] / 2
		HORIZONTAL_ALIGNMENT_RIGHT:
			center.x = size.x - WIDTH_BY_AMOUNT[amount] / 2
	for offset: Vector2 in offsets:
		draw_string(Utils.EMOJI_FONT, center + offset, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)


func _refresh_disabled() -> void:
	self_modulate = DISABLED_COLOR if disabled else Color.WHITE


static func amount_from_cost(cost: Big) -> Amount:
	var cost_ratio: float = cost.to_float() / max(1, PlayerData.peak_gold.to_float())
	var threshold_index: int = COST_THRESHOLDS.size() - 1
	for i in COST_THRESHOLDS.size() - 1:
		if cost_ratio <= COST_THRESHOLDS[i][0]:
			threshold_index = i
			break
	return COST_THRESHOLDS[threshold_index][1]
