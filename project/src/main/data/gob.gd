class_name Gob
## A group of goblins is a gob.

var name: String = ""

## Total goblins
var count: Big = Big.ONE:
	set(value):
		if value.to_float() - floor(value.to_float()) != 0.0:
			push_error("Error: count was set to a non integer value")
		count = value

## Level for each goblin
var level: int = 1

## Type of all goblins
var type: Gobs.Type = Gobs.Type.FIRE

## Max hp for each goblin
var hp_max: int = 4

## Hp missing from one goblin, if a goblin is wounded
var hp: int = 4

## Attack for each goblin
var attack: int = 2

## Gold for each goblin
var gold: int = 0

## Experience for each goblin
var xp: int = 0

func duplicate() -> Gob:
	var copy: Gob = Gob.new()
	copy.name = name
	copy.count = count
	copy.gold = gold
	copy.level = level
	copy.type = type
	copy.hp_max = hp_max
	copy.hp = hp
	copy.xp = xp
	copy.attack = attack
	return copy


func level_up() -> void:
	xp = max(0, xp - get_exp_threshold())
	var hp_gain: int = 0
	hp_gain += [2, 4, 4, 6].pick_random()
	attack += [1, 2, 2, 3].pick_random()
	if type == Gobs.DEVIL:
		hp_gain += [2, 4, 4, 6].pick_random()
		attack += [1, 2, 2, 3].pick_random()
	var level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
	if type == Gobs.DEVIL:
		level_cost *= 2
	gold += level_cost
	hp_max += hp_gain
	hp += hp_gain
	level += 1


func get_exp_threshold() -> int:
	var exp_factor: int = 4 if type == Gobs.DEVIL else 2
	var level_tmp: int = level
	while level_tmp > 0 and level_tmp % 10 == 0:
		level_tmp /= 10
		exp_factor *= 10
	return maxi(1, (level + 1) * exp_factor)


func can_level_up() -> bool:
	return xp >= get_exp_threshold()


## Experience points for killing each goblin
func get_kill_exp() -> int:
	return level + 1


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	name = json.get("name", "")
	count = Big.new(json.get("count", 1))
	level = json.get("level", 1)
	type = Gobs.Type.get(json.get("type", "fire").to_upper())
	
	var hp_split: PackedStringArray = json.get("hp", "4/4").split("/")
	hp = int(hp_split[0])
	hp_max = int(hp_split[1])
	
	attack = json.get("attack", 2)
	gold = json.get("gold", 0)
	xp = json.get("xp", 0)


func to_json_dict() -> Dictionary[String, Variant]:
	return {
		"name": name,
		"count": count.to_float(),
		"level": level,
		"type": Utils.enum_to_snake_case(Gobs.Type, type),
		"hp": "%s/%s" % [hp, hp_max],
		"attack": attack,
		"gold": gold,
		"xp": xp,
	}
