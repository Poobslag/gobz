class_name NewDayFoodRow
extends HBoxContainer

@export var item_type: Items.Type = Items.FOOD_BREAD

var _tween: Tween

func prepare(from_count: Big) -> void:
	_refresh_item_label(from_count.to_float())
	_refresh_delta_label(0.0)


func play(from_count: Big, to_count: Big, duration: float) -> void:
	_tween = Utils.recreate_tween(self, _tween)
	_refresh_item_label(from_count.to_float())
	_refresh_delta_label(0.0)
	_tween.tween_method(_refresh_item_label, from_count.to_float(), to_count.to_float(), duration)
	_tween.parallel().tween_method(_refresh_delta_label, 0.0, to_count.to_float() - from_count.to_float(), duration)


func _refresh_item_label(value: float) -> void:
	%ItemLabel.text = "%s%s" % [Items.emoji_from_type(item_type), Big.float_to_aa(value)]


func _refresh_delta_label(value: float) -> void:
	if value == 0.0:
		%DeltaLabel.text = ""
	else:
		%DeltaLabel.text = "(%s%s)" % [
			"+" if value > 0 else "",
			Big.float_to_aa(value)
		]
