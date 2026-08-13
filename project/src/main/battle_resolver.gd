class_name BattleResolver

const MATCHUPS: Array[Array] = [
	# Fire   Water  Grass  Angel  Devil
	[ 1.000, 0.333, 3.000, 3.000, 0.333], # Fire
	[ 3.000, 1.000, 0.333, 3.000, 0.333], # Water
	[ 0.333, 3.000, 1.000, 3.000, 0.333], # Grass
	[ 0.333, 0.333, 0.333, 1.000, 3.000], # Angel
	[ 3.000, 3.000, 3.000, 0.333, 1.000], # Devil
]

static func plan_attacks(
		from: Army, to: Army, type: Goblins.GoblinType,
		target_orders: Array[Goblins.GoblinType] = []) -> Array[Attack]:
	var attacks: Array[Attack] = []
	if from.items.is_empty() or to.items.is_empty():
		return []
	
	var from_sorted: Array[Army.ArmyItem] = from.items.duplicate()
	from_sorted.sort_custom(func(a: Army.ArmyItem, b: Army.ArmyItem) -> bool:
		return a.attack > b.attack)
	var targets: Array[Army.ArmyItem] = []
	for target: Army.ArmyItem in to.items:
		if target_orders.is_empty() or target_orders.has(target.type):
			targets.append(target)
	targets.shuffle()
	
	if targets == null:
		return []
	
	var virtual_targets: Dictionary[Army.ArmyItem, Army.ArmyItem] = {}
	for target: Army.ArmyItem in targets:
		virtual_targets[target] = target.duplicate()
	
	for source: Army.ArmyItem in from_sorted:
		var best_score: Big = Big.ZERO
		var best_damage: Big = Big.ZERO
		var best_target: Army.ArmyItem
		var best_damage_result: Dictionary[String, Variant] = {}
		if source.type != type:
			continue
		for target: Army.ArmyItem in targets:
			var virtual: Army.ArmyItem = virtual_targets[target]
			if virtual.count.is_lte(0):
				continue # already claimed by an earlier attacker
			var damage: Big = base_damage(source, target)
			var hp_loss: Big = Big.sub(_effective_hp(virtual), _effective_hp(virtual, damage))
			var damage_result: Dictionary[String, Variant] = apply_damage(virtual, damage)
			var damage_prevention: Big = Big.mul(damage_result["kill_count"], virtual.attack)
			var score: Big = Big.add(hp_loss, damage_prevention)
			
			if score.is_gt(best_score):
				best_score = Big.add(hp_loss, damage_prevention)
				best_damage = damage
				best_target = target
				best_damage_result = damage_result
		
		# sometimes there's no logical target to attack, because all targets should be dead
		if best_target == null and targets != null:
			best_target = targets.pick_random()
			best_damage = base_damage(source, best_target)
			best_damage_result = apply_damage(virtual_targets[best_target], best_damage)
		
		# sometimes there's no logical target to attack, because all targets already died
		if best_target == null:
			continue
		
		var attack: Attack = Attack.new()
		attack.source = source
		attack.target = best_target
		attack.damage = best_damage
		attack.damage = Big.new(attack.damage.to_float() * randf_range(1.0, 1.1))
		attacks.append(attack)
		
		virtual_targets[attack.target].hp = best_damage_result["new_hp"]
		virtual_targets[attack.target].count = best_damage_result["new_count"]
	
	return attacks


static func apply_damage(target: Army.ArmyItem, damage: Big) -> Dictionary[String, Variant]:
	var effective_hp: Big = _effective_hp(target, damage)
	var new_hp: int = Big.mod(Big.sub(effective_hp, 1), target.hp_max + 1).to_int()
	var new_count: Big = Big.new(ceil(effective_hp.to_float() / target.hp_max))
	return {
		"kill_count": Big.sub(target.count, new_count),
		"wounded_count": Big.ONE if new_count.is_gt(0) and new_hp != target.hp else Big.ZERO,
		"new_hp": new_hp,
		"new_count": new_count,
	}


static func base_damage(from: Army.ArmyItem, to: Army.ArmyItem) -> Big:
	return Big.max(1, from.count.to_float() * from.attack * effectiveness(from.type, to.type))


static func effectiveness(from: Goblins.GoblinType, to: Goblins.GoblinType) -> float:
	return MATCHUPS[from][to]


static func resolve_attacks(from: Army, to: Army, attacks: Array[Attack]) -> Array[Kill]:
	var kills: Array[Kill] = []
	for attack: Attack in attacks:
		var damage_result: Dictionary[String, Variant] = apply_damage(attack.target, attack.damage)
		attack.target.hp = damage_result["new_hp"]
		attack.target.count = damage_result["new_count"]
		var kill_count: Big = damage_result["kill_count"]
		var wounded_count: Big = damage_result["wounded_count"]
		if kill_count.is_gt(0):
			# award gold/xp for kills
			from.gold = Big.add(from.gold, Big.mul(kill_count, attack.target.gold))
			var total_xp_gain: Big = Big.mul(kill_count, attack.target.get_kill_exp())
			var per_gob_xp_gain: int = roundi(total_xp_gain.to_float() / attack.source.count.to_float())
			attack.source.xp += per_gob_xp_gain
		if attack.target.count.is_lte(0):
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


static func _effective_hp(item: Army.ArmyItem, damage: Big = Big.ZERO) -> Big:
	var a: Big = Big.sub(item.count, 1)
	a = Big.mul(a, item.hp_max)
	a = Big.add(a, item.hp)
	a = Big.sub(a, damage)
	return Big.max(a, 0)


class Attack:
	var source: Army.ArmyItem
	var target: Army.ArmyItem
	var damage: Big


class Kill:
	var source: Army.ArmyItem
	var target: Army.ArmyItem
	var kill_count: Big
	var wounded_count: Big


class LevelUp:
	var item: Army.ArmyItem
	var count: int = 0
