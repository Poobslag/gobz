class_name ArmySummary
extends Node

var total_goblins: Big = Big.ZERO
var total_attack: Big = Big.ZERO
var goblins_by_type: Dictionary[Gobs.Type, Big] = {}
var wounded_by_type: Dictionary[Gobs.Type, Big] = {}
var attack_by_type: Dictionary[Gobs.Type, Big] = {}
var total_gold: Big = Big.ZERO

func _to_string() -> String:
	return str({
		"total_goblins": total_goblins,
		"total_attack": total_attack,
		"goblins_by_type": goblins_by_type,
		"wounded_by_type": wounded_by_type,
		"attack_by_type": attack_by_type,
		"total_gold": total_gold,
	})


static func from_gobs(gobs: Array[Gob]) -> ArmySummary:
	var result: ArmySummary = ArmySummary.new()
	
	var new_total_goblins: float = 0.0
	var new_total_attack: float = 0.0
	var new_goblins_by_type: Dictionary[Gobs.Type, float] = {}
	var new_wounded_by_type: Dictionary[Gobs.Type, float] = {}
	var new_attack_by_type: Dictionary[Gobs.Type, float] = {}
	var new_total_gold: float = 0.0
	
	for goblin_type: Gobs.Type in Gobs.Type.values():
		new_goblins_by_type[goblin_type] = 0.0
		new_attack_by_type[goblin_type] = 0.0
		new_wounded_by_type[goblin_type] = 0.0
	
	for gob: Gob in gobs:
		new_goblins_by_type[gob.type] += gob.get_count().to_float()
		new_total_goblins += gob.get_count().to_float()
		new_attack_by_type[gob.type] += gob.get_total_attack().to_float()
		new_wounded_by_type[gob.type] += gob.get_wounded_count().to_float()
		new_total_attack += gob.get_total_attack().to_float()
		new_total_gold += gob.gold * gob.get_count().to_float()
	
	result.total_goblins = Big.new(new_total_goblins)
	result.total_attack = Big.new(new_total_attack)
	for type: Gobs.Type in Gobs.Type.values():
		result.goblins_by_type[type] = Big.new(new_goblins_by_type[type])
		result.wounded_by_type[type] = Big.new(new_wounded_by_type[type])
		result.attack_by_type[type] = Big.new(new_attack_by_type[type])
	result.total_gold = Big.new(new_total_gold)
	
	return result
