class_name GoldBar
extends Control

var _cost_previews: Dictionary[int, Big] = {}
var _preview_amount: Big = Big.ZERO

func _ready() -> void:
	PlayerData.gold_changed.connect(_refresh)
	_refresh()


func start_cost_preview(id: int, amount: Big) -> void:
	_preview_amount = amount
	_cost_previews[id] = amount
	_refresh()


func stop_cost_preview(id: int) -> void:
	_cost_previews.erase(id)
	_preview_amount = Big.ZERO if _cost_previews.is_empty() else _cost_previews.values()[0]
	_refresh()


func connect_button_signals(button: Button, cost_function: Callable) -> void:
	var button_instance_id: int = button.get_instance_id()
	button.mouse_entered.connect(func() -> void:
		if button.disabled:
			return
		start_cost_preview(button_instance_id, cost_function.call()))
	button.mouse_exited.connect(stop_cost_preview.bind(button_instance_id))
	button.pressed.connect(func() -> void:
		await get_tree().process_frame
		if not is_instance_valid(button) or button.disabled:
			stop_cost_preview(button_instance_id))


func _refresh() -> void:
	var peak_gold_float: float = PlayerData.peak_gold.to_float()
	peak_gold_float = max(peak_gold_float, 1)
	var gold_float: float = PlayerData.gold.to_float()
	gold_float = max(gold_float, 1)
	var amount_float: float = _preview_amount.to_float()
	amount_float = clamp(amount_float, 0, gold_float)
	%ProgressBarFront.value = lerp(0, 100, (gold_float - amount_float) / peak_gold_float)
	%ProgressBarBack.value = lerp(0, 100, gold_float / peak_gold_float)
	%GoldLabel.text = PlayerData.gold.to_aa()


static func find_instance(node: Node) -> GoldBar:
	return node.get_tree().get_first_node_in_group("gold_bars")
