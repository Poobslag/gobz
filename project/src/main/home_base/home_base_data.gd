extends Node

const MORALE_GOOD_PATH: String = "res://assets/main/home_base/home_base_morale_good.csv"
const MORALE_BAD_PATH: String = "res://assets/main/home_base/home_base_morale_bad.csv"

var heal_data: HealData = HealData.new()
var party_data: PartyData = PartyData.new()
var _morale_message: String = ""

func reset() -> void:
	heal_data.reset()
	party_data.reset()
	clear_morale_message()


func get_morale_message() -> String:
	if _morale_message == "" and not PlayerData.army.gobs.is_empty():
		var gob: Gob = PlayerData.army.gobs.pick_random()
		if randf_range(0.0, 100.0) < gob.morale.value:
			_morale_message = LinePool.get_random_line(MORALE_GOOD_PATH).format([["name", gob.name]])
		else:
			_morale_message = LinePool.get_random_line(MORALE_BAD_PATH).format([["name", gob.name]])
	return _morale_message


func force_good_morale_message() -> void:
	if PlayerData.army.gobs.is_empty():
		return
	
	var gobs: Array[Gob] = PlayerData.army.gobs.duplicate()
	gobs.shuffle()
	var best_gob: Gob = gobs.front()
	for _i in 6:
		var gob: Gob = PlayerData.army.gobs.pick_random()
		if gob.morale.value > best_gob.morale.value:
			best_gob = gob
	_morale_message = LinePool.get_random_line(MORALE_GOOD_PATH).format([["name", best_gob.name]])


func clear_morale_message() -> void:
	_morale_message = ""
