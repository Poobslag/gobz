class_name BattleResolver

const MATCHUPS: Array[Array] = [
	# Fire   Water  Grass  Angel  Devil
	[ 1.000, 0.333, 3.000, 3.000, 0.333], # Fire
	[ 3.000, 1.000, 0.333, 3.000, 0.333], # Water
	[ 0.333, 3.000, 1.000, 3.000, 0.333], # Grass
	[ 0.333, 0.333, 0.333, 1.000, 3.000], # Angel
	[ 3.000, 3.000, 3.000, 0.333, 1.000], # Devil
]

static func plan_attacks(from: Army, to: Army, type: Goblins.GoblinType) -> Array[Attack]:
	if from.items.is_empty() or to.items.is_empty():
		return []
	
	var virtual_targets: Dictionary[Army.ArmyItem, Army.ArmyItem] = {}
	for target: Army.ArmyItem in to.items:
		virtual_targets[target] = target.duplicate()
	
	var attacks: Array[Attack] = []
	var from_sorted: Array[Army.ArmyItem] = from.items.duplicate()
	from_sorted.sort_custom(func(a: Army.ArmyItem, b: Army.ArmyItem) -> bool:
		return a.attack > b.attack)
	var to_shuffled: Array[Army.ArmyItem] = to.items.duplicate()
	to_shuffled.shuffle()
	for source: Army.ArmyItem in from_sorted:
		var best_score: int = 0
		var best_damage: int = 0
		var best_target: Army.ArmyItem
		var best_damage_result: Dictionary[String, Variant] = {}
		if source.type != type:
			continue
		for target: Army.ArmyItem in to_shuffled:
			var virtual: Army.ArmyItem = virtual_targets[target]
			if virtual.count <= 0:
				continue # already claimed by an earlier attacker
			var damage: int = base_damage(source, target)
			var hp_loss: int = _effective_hp(virtual) - _effective_hp(virtual, damage)
			var damage_result: Dictionary[String, Variant] = apply_damage(virtual, damage)
			var damage_prevention: int = damage_result["kill_count"] * virtual.attack
			var score: int = hp_loss + damage_prevention
			
			if score > best_score:
				best_score = hp_loss + damage_prevention
				best_damage = damage
				best_target = target
				best_damage_result = damage_result
		
		# sometimes there's no logical target to attack, because all targets should be dead
		if best_target == null:
			best_target = to_shuffled.pick_random()
			best_damage = base_damage(source, best_target)
			best_damage_result = apply_damage(virtual_targets[best_target], best_damage)
		
		var attack: Attack = Attack.new()
		attack.source = source
		attack.target = best_target
		attack.damage = best_damage
		attack.damage = floori(attack.damage * randf_range(1.0, 1.1))
		attacks.append(attack)
		
		virtual_targets[attack.target].hp = best_damage_result["new_hp"]
		virtual_targets[attack.target].count = best_damage_result["new_count"]
	return attacks


static func apply_damage(target: Army.ArmyItem, damage: int) -> Dictionary[String, Variant]:
	var effective_hp: int = _effective_hp(target, damage)
	var new_hp: int = (effective_hp - 1) % target.hp_max + 1
	var new_count: int = ceili(effective_hp / float(target.hp_max))
	return {
		"kill_count": target.count - new_count,
		"wounded_count": 1 if new_count > 0 and new_hp != target.hp else 0,
		"new_hp": new_hp,
		"new_count": new_count,
	}


static func base_damage(from: Army.ArmyItem, to: Army.ArmyItem) -> int:
	return maxi(1, roundi(from.attack * from.count * effectiveness(from.type, to.type)))


static func effectiveness(from: Goblins.GoblinType, to: Goblins.GoblinType) -> float:
	return MATCHUPS[from][to]


static func resolve_attacks(from: Army, to: Army, attacks: Array[Attack]) -> Array[Kill]:
	var kills: Array[Kill] = []
	for attack: Attack in attacks:
		var damage_result: Dictionary[String, Variant] = apply_damage(attack.target, attack.damage)
		attack.target.hp = damage_result["new_hp"]
		attack.target.count = damage_result["new_count"]
		var kill_count: int = damage_result["kill_count"]
		var wounded_count: int = damage_result["wounded_count"]
		from.gold += kill_count * attack.target.gold
		attack.source.experience += kill_count * attack.target.get_kill_exp()
		if attack.target.count <= 0:
			to.remove_item(attack.target)
		
		var kill: Kill = Kill.new()
		kill.source = attack.source
		kill.target = attack.target
		kill.kill_count = kill_count
		kill.wounded_count = wounded_count
		kills.append(kill)
	return kills


static func resolve_level_ups(army: Army) -> Array[LevelUp]:
	var level_ups: Array[LevelUp] = []
	for item: Army.ArmyItem in army.items:
		var level_up_count: int = 0
		while item.can_level_up():
			item.level_up()
			level_up_count += 1
		
		if level_up_count >= 1:
			var level_up: LevelUp = LevelUp.new()
			level_up.item = item
			level_up.count = level_up_count
			level_ups.append(level_up)
	return level_ups


static func _effective_hp(item: Army.ArmyItem, damage: int = 0) -> int:
	return maxi(0, item.hp_max * (item.count - 1) + item.hp - damage)


class Attack:
	var source: Army.ArmyItem
	var target: Army.ArmyItem
	var damage: int


class Kill:
	var source: Army.ArmyItem
	var target: Army.ArmyItem
	var kill_count: int
	var wounded_count: int


class LevelUp:
	var item: Army.ArmyItem
	var count: int = 0
