class_name BattleResolver

const NORMAL: float = 1.0
const STRONG: float = 3.0
const WEAK: float = 0.333

const MATCHUPS: Array[Array] = [
	# Fire    Water   Grass   Angel   Devil
	[ NORMAL, WEAK,   STRONG, STRONG, WEAK   ], # Fire (strong against grass, weak against water)
	[ STRONG, NORMAL, WEAK,   STRONG, WEAK   ], # Water (strong against fire, weak to grass)
	[ WEAK,   STRONG, NORMAL, STRONG, WEAK   ], # Grass (strong against water, weak to fire)
	[ WEAK,   WEAK,   WEAK,   NORMAL, STRONG ], # Angel (strong against devil, weak to everything)
	[ STRONG, STRONG, STRONG, WEAK,   NORMAL ], # Devil (strong against everything, weak to angel)
]

static func plan_attacks(from: Army, type: Goblins.GoblinType) -> Array[Attack]:
	var attacks: Array[Attack] = []
	
	for horde: Horde in from.hordes:
		if horde.type != type:
			continue
		
		var attack: Attack = Attack.new()
		attack.source = horde
		attack.count = horde.count
		attacks.append(attack)
	
	return attacks


static func base_damage(from: Horde, to: Horde) -> Big:
	return Big.max(1, from.count.to_float() * from.attack * effectiveness(from.type, to.type))


static func effectiveness(from: Goblins.GoblinType, to: Goblins.GoblinType) -> float:
	return MATCHUPS[from][to]


static func resolve_attacks(from: Army, to: Army, attacks: Array[Attack],
		vulnerable_types: Array[Goblins.GoblinType]) -> Array[Kill]:
	var attacker_pool: AttackerPool = AttackerPool.new(attacks)
	var defender_pool: DefenderPool = DefenderPool.new(to, vulnerable_types)
	
	var kills: Array[Kill] = []
	# mapping from the source horde to the kill which may claim its wound
	var pending_wounds: Dictionary[Horde, Kill]
	
	while not attacker_pool.is_empty() and not defender_pool.is_empty():
		var attack: Attack = attacker_pool.current()
		var target_index: int = find_target_index_for_attack(attacker_pool, defender_pool)
		var target: Horde = defender_pool.get_horde_at(target_index)
		
		var damage_per_hit: int = maxi(1, \
				roundi(attack.source.attack * effectiveness(attack.source.type, target.type)))
		var hits_per_kill: int = ceili(target.hp_max / float(damage_per_hit))
		var hits_to_kill_wounded: int = ceili(target.hp / float(damage_per_hit))
		var max_hits_taken: Big = Big.mul(Big.sub(target.count, 1), hits_per_kill)
		max_hits_taken = Big.add(max_hits_taken, ceili(target.hp / float(damage_per_hit)))
		var hits_taken: Big = attacker_pool.take(max_hits_taken)
		
		var kill_count: Big
		var new_hp: int
		var wounded: bool = false
		if hits_taken.is_gte(hits_to_kill_wounded):
			var hits_left: Big = Big.sub(hits_taken, hits_to_kill_wounded)
			kill_count = Big.add(1, Big.div(hits_left, hits_per_kill))
			hits_left = Big.mod(hits_left, hits_per_kill)
			new_hp = target.hp_max - hits_left.to_int() * damage_per_hit
			wounded = hits_left.is_gt(0)
		else:
			kill_count = Big.ZERO
			new_hp = target.hp - hits_taken.to_int() * damage_per_hit
			wounded = hits_taken.is_gt(0)
		
		target.hp = new_hp
		target.count = Big.sub(target.count, kill_count)
		
		if kill_count.is_gt(0):
			# award gold/xp for kills
			from.gold = Big.add(from.gold, Big.mul(kill_count, target.gold))
			var total_xp_gain: Big = Big.mul(kill_count, target.get_kill_exp())
			var per_gob_xp_gain: int = roundi(total_xp_gain.to_float() / attack.source.count.to_float())
			attack.source.xp += per_gob_xp_gain
		if target.count.is_lte(0):
			to.remove_horde(target)
			defender_pool.remove_at(target_index)
		
		var kill: Kill = Kill.new()
		kill.source = attack.source
		kill.target = target
		kill.kill_count = kill_count
		kills.append(kill)
		
		if wounded:
			pending_wounds[target] = kill
	
	# give credit for wounding targets
	for target: Horde in pending_wounds:
		if target.count.is_gte(1):
			pending_wounds[target].wounded_count = Big.ONE
	# remove any 'kills' which didn't actually wound or kill any units
	for kill_index: int in range(kills.size() - 1, -1, -1):
		var kill: Kill = kills[kill_index]
		if kill.wounded_count.is_eq(Big.ZERO) and kill.kill_count.is_eq(Big.ZERO):
			kills.remove_at(kill_index)
	
	return kills


static func find_target_index_for_attack(attacker_pool: AttackerPool, defender_pool: DefenderPool) -> int:
	var attack: Attack = attacker_pool.current()
	var best_target_index: int = 0
	var best_effectiveness: float = 0.0
	for target_offset: int in defender_pool.size():
		var target_index: int = (attacker_pool.index + target_offset) % defender_pool.size()
		var target_horde: Horde = defender_pool.get_horde_at(target_index)
		var target_effectiveness: float = effectiveness(attack.source.type, target_horde.type)
		if target_effectiveness > best_effectiveness:
			best_effectiveness = target_effectiveness
			best_target_index = target_index
			if target_effectiveness == STRONG:
				break
	return best_target_index


static func resolve_level_ups(army: Army) -> Array[LevelUp]:
	var level_ups: Array[LevelUp] = []
	for horde: Horde in army.hordes:
		var level_up_count: int = 0
		while horde.can_level_up():
			horde.level_up()
			level_up_count += 1
		
		if level_up_count >= 1:
			var level_up: LevelUp = LevelUp.new()
			level_up.horde = horde
			level_up.count = level_up_count
			level_ups.append(level_up)
	return level_ups


class Attack:
	var source: Horde
	var count: Big = Big.ZERO


class Kill:
	var source: Horde
	var target: Horde
	var kill_count: Big = Big.ZERO
	var wounded_count: Big = Big.ZERO


class LevelUp:
	var horde: Horde
	var count: int = 0


class AttackerPool:
	var attacks: Array[Attack]
	var index: int = 0
	var remaining: Big = Big.ZERO
	
	func _init(init_attacks: Array[Attack]) -> void:
		attacks = init_attacks
		_refill()
	
	
	func is_empty() -> bool:
		return index >= attacks.size()
	
	
	func current() -> Attack:
		return attacks[index]
	
	
	func take(amount: Big) -> Big:
		var hits_taken: Big = Big.min(amount, remaining)
		remaining = Big.sub(remaining, hits_taken)
		if remaining.is_lte(0):
			index += 1
			_refill()
		return hits_taken
	
	
	func _refill() -> void:
		remaining = attacks[index].count if index < attacks.size() else Big.ZERO


class DefenderPool:
	var vulnerable_hordes: Array[Horde] = []
	
	func _init(army: Army, vulnerable_types: Array[Goblins.GoblinType]) -> void:
		for horde: Horde in army.hordes:
			if horde.type in vulnerable_types:
				vulnerable_hordes.append(horde)
	
	
	func is_empty() -> bool:
		return vulnerable_hordes.is_empty()
	
	
	func get_horde_at(index: int) -> Horde:
		return vulnerable_hordes[index]
	
	
	func remove_at(index: int) -> void:
		vulnerable_hordes.remove_at(index)
	
	
	func size() -> int:
		return vulnerable_hordes.size()
