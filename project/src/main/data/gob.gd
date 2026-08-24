class_name Gob
## A group of goblins is a gob.

var name: String = ""

## Total goblins, excluding the front goblin
var back_count: Big = Big.ZERO

## Number of wounded goblins, excluding the front goblin
var back_wounded: Big = Big.ZERO

## Level for each goblin
var level: int = 1

## Type of all goblins
var type: Gobs.Type = Gobs.Type.FIRE

## Max hp for each goblin
var hp_max: int = 4

## Hp of front goblin
var front_hp: int = 4

## Attack for each goblin
var attack: int = 2

## Gold for each goblin
var gold: int = 0

## Experience for each goblin
var xp: int = 0

func get_healthy_count() -> Big:
	return Big.new(back_count.to_float() - back_wounded.to_float() + (0 if is_front_wounded() else 1))


func get_wounded_count() -> Big:
	return Big.new(back_wounded.to_float() + (1 if is_front_wounded() else 0))


func get_hurt_count() -> Big:
	return Big.new(back_wounded.to_float() + (1 if is_front_hurt() else 0))


func get_count() -> Big:
	return Big.add(back_count, Big.ONE if front_hp > 0 else Big.ZERO)


func assert_valid() -> void:
	assert(back_count.is_gte(0), "back_count (%s) < 0" % [back_count])
	assert(back_wounded.is_gte(0), "back_wounded (%s) < 0" % [back_wounded])
	assert(back_wounded.is_lte(back_count), "back_wounded (%s) > back_count (%s)" % [back_wounded, back_count])


func fix_invalid() -> void:
	if back_count.is_lt(0):
		back_count = Big.ZERO
	if back_wounded.is_lt(0):
		back_wounded = Big.ZERO
	if back_wounded.is_gt(back_count):
		back_wounded = back_count


func is_dead() -> bool:
	return back_count.is_lte(0) and front_hp == 0


func is_hurt() -> bool:
	return back_wounded.is_gt(0) or is_front_hurt()


func is_front_wounded() -> bool:
	return front_hp <= hp_max * Gobs.WOUNDED_HP_THRESHOLD


func is_front_hurt() -> bool:
	return front_hp < hp_max


func get_total_attack() -> Big:
	return Big.new(
		get_wounded_count().to_float() * roundi(attack * Gobs.WOUNDED_ATTACK_FACTOR) +
		get_healthy_count().to_float() * attack
	)


func duplicate() -> Gob:
	var copy: Gob = Gob.new()
	copy.name = name
	copy.back_count = back_count
	copy.back_wounded = back_wounded
	copy.gold = gold
	copy.level = level
	copy.type = type
	copy.hp_max = hp_max
	copy.front_hp = front_hp
	copy.xp = xp
	copy.attack = attack
	return copy


func kill_front() -> void:
	if back_count.is_eq(Big.ZERO):
		front_hp = 0
	elif back_wounded.is_gte(back_count.to_float()):
		front_hp = floori(hp_max / 2.0)
		back_wounded = Big.sub(back_wounded, Big.ONE)
		back_count = Big.sub(back_count, Big.ONE)
	else:
		front_hp = hp_max
		back_count = Big.sub(back_count, Big.ONE)


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
	front_hp += hp_gain
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
	back_count = Big.new(json.get("back_count", 0))
	back_wounded = Big.new(json.get("back_wounded", 0))
	level = json.get("level", 1)
	type = Gobs.Type.get(json.get("type", "fire").to_upper())
	
	var hp_split: PackedStringArray = json.get("hp", "4/4").split("/")
	front_hp = int(hp_split[0])
	hp_max = int(hp_split[1])
	
	attack = json.get("attack", 2)
	gold = json.get("gold", 0)
	xp = json.get("xp", 0)


func to_json_dict() -> Dictionary[String, Variant]:
	return {
		"name": name,
		"back_count": back_count.to_float(),
		"back_wounded": back_wounded.to_float(),
		"level": level,
		"type": Utils.enum_to_snake_case(Gobs.Type, type),
		"hp": "%s/%s" % [front_hp, hp_max],
		"attack": attack,
		"gold": gold,
		"xp": xp,
	}


func _to_string() -> String:
	return JSON.stringify(to_json_dict())
