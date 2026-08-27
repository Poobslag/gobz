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

## Goblins with a high brutality value prioritize killing goblins over wounding them.
const BRUTALITY_BY_TYPE: Dictionary[Gobs.Type, float] = {
	Gobs.FIRE: 0.5,
	Gobs.WATER: 0.6,
	Gobs.GRASS: 0.4,
	Gobs.ANGEL: 0.1,
	Gobs.DEVIL: 0.9,
}

static func plan_attacks(from: Army, type: Gobs.Type) -> Array[Attack]:
	var attacks: Array[Attack] = []
	
	for gob: Gob in from.gobs:
		if gob.type != type:
			continue
		
		var healthy_count: Big = gob.get_healthy_count()
		if healthy_count.is_gt(Big.ZERO):
			var attack: Attack = Attack.new()
			attack.source = gob
			attack.count = healthy_count
			attacks.append(attack)
		
		var wounded_count: Big = gob.get_wounded_count()
		if wounded_count.is_gt(Big.ZERO):
			var attack: Attack = Attack.new()
			attack.source = gob
			attack.count = wounded_count
			attack.wounded = true
			attacks.append(attack)
	
	return attacks


static func base_damage(from: Gob, to: Gob) -> Big:
	return Big.max(1, from.count.to_float() * from.attack * effectiveness(from.type, to.type))


static func effectiveness(from: Gobs.Type, to: Gobs.Type) -> float:
	return MATCHUPS[from][to]


## Resolves one round of attacks. Each attack in [param attacks] hits defenders, removing and wounding goblins.[br]
## [br]
## Attackers search for defenders they're effective against, spreading out attacks based on their brutality value.
static func resolve_attacks(from: Army, to: Army, attacks: Array[Attack],
		vulnerable_types: Array[Gobs.Type]) -> Array[Kill]:
	var attacker_pool: AttackerPool = AttackerPool.new(attacks)
	var defender_pool: DefenderPool = DefenderPool.new(to, vulnerable_types)
	
	var kills: Array[Kill] = []
	
	# Attackers prioritize targets in the following order:
	# 1. First, attack all super-effective targets, spreading out attacks.
	# 2. Next, attack all super-effective targets, concentrating attacks for kills.
	# 3. Next, repeat steps 1 and 2 for normally effective targets.
	# 4. Next, repeat steps 1 and 2 for ineffective targets.
	#
	# These four fields are used to maintain this complex cursor -- tracking whether we've exhausted all super-
	# effective targets, and tracking whether we're spreading out attacks or not.
	
	# the first defender which we did not kill. if we loop back to them, we enable murder_mode to finish them off
	var first_spared_target: Gob = null
	var prev_effectiveness: float = STRONG # the effectiveness of the previous attack
	var murder_mode: bool = false # whether attackers are concentrating attacks for kills
	var defender_index: int = 0
	
	var mercy: float = 0
	
	while not attacker_pool.is_empty() and not defender_pool.is_empty():
		if mercy > 100000:
			# at most, we should have about 500 units looping about 3,000 times to find their target.
			push_error("Battle did not terminate after %s attacks." % [mercy])
			break
		mercy += 1
		
		var attack: Attack = attacker_pool.current()
		var target_index: int = find_target_index_for_attack(attacker_pool, defender_pool, defender_index)
		var target: Gob = defender_pool.get_gob_at(target_index)
		
		if target == first_spared_target:
			murder_mode = true
		
		var result: Dictionary[String, Variant] = resolve_attack(attack, target, attacker_pool.remaining, murder_mode)
		attacker_pool.take(result["hits_taken"])
		
		if not attacker_pool.is_empty() and attacker_pool.current() != attack:
			# advanced to next attacker
			first_spared_target = null
			murder_mode = false
			prev_effectiveness = STRONG
		else:
			# kept same attacker
			var curr_effectiveness: float = effectiveness(attack.source.type, target.type)
			if curr_effectiveness < prev_effectiveness:
				prev_effectiveness = curr_effectiveness
				first_spared_target = null
				murder_mode = false
			if first_spared_target == null and not target.is_dead():
				first_spared_target = target
		
		if not target.is_dead():
			defender_index = target_index + 1
		
		if result["kill_count"].is_gt(0):
			# award gold/xp for kills
			from.gold = Big.add(from.gold, Big.mul(result["kill_count"], target.gold))
			var total_xp_gain: Big = Big.mul(result["kill_count"], target.get_kill_exp())
			var per_gob_xp_gain: int = roundi(total_xp_gain.to_float() / attack.source.get_count().to_float())
			attack.source.xp += per_gob_xp_gain
		if target.is_dead():
			to.remove_gob(target)
			defender_pool.remove_at(target_index)
		
		var kill: Kill = Kill.new()
		kill.source = attack.source
		kill.target = target
		kill.kill_count = result["kill_count"]
		kills.append(kill)
	
	return kills


static func floor_to_multiple(f: float, factor: float) -> float:
	return floor(f / factor) * factor


## Applies up to [param attacks_remaining] hits from a single attack, removing and wounding defending goblins.[br]
## [br]
## Hits are broken into four categories: hits which kill healthy back goblins, hits which wound healthy back goblins,
## hits which kill wounded back goblins, and hits which kill/wound the front goblin. Goblins split their attacks into
## trying to kill and wound healthy units. The [param murder_mode] flag overrides this behavior to maximize kills.
static func resolve_attack(attack: Attack, target: Gob, attacks_remaining: Big, murder_mode: bool) \
		-> Dictionary[String, Variant]:
	target.assert_valid()
	
	var killed_by_attack: Big = Big.ZERO
	var hits_taken: Big = Big.ZERO
	
	var damage_per_hit: int = maxi(1, \
			roundi(attack.source.attack \
			* effectiveness(attack.source.type, target.type) \
			* (Gobs.WOUNDED_ATTACK_FACTOR if attack.wounded else 1.0)))
	
	var hits_per_kill: int = ceili(target.hp_max / float(damage_per_hit))
	var hits_per_wound: int = maxi(1, roundi((target.hp_max * Gobs.WOUNDED_HP_THRESHOLD) / float(damage_per_hit)))
	var hits_to_kill_front: int = _hits_to_kill_front(target, damage_per_hit)
	
	# how many hits do we want to apply, assuming the target were not wounded and at full health?
	var old_target_count: Big = target.get_count()
	var brutality: float = 1.0 if murder_mode else BRUTALITY_BY_TYPE[attack.source.type]
	var how_many_hits_can_they_take: float = _max_full_hits(target, hits_per_kill)
	how_many_hits_can_they_take += _max_wounded_half_hits(target, hits_per_wound)
	how_many_hits_can_they_take += hits_to_kill_front
	var how_many_hits_do_they_deserve: float = roundf(hits_per_kill * target.get_count().to_float() \
			* lerp(0.5, 1.0, brutality))
	var how_many_hits_will_we_do: float = \
			min(how_many_hits_can_they_take, how_many_hits_do_they_deserve, attacks_remaining.to_float())
	var unassigned_hits: float = how_many_hits_will_we_do

	var full_hits: float = 0.0 # hits spent killing healthy back goblins
	var wounded_half_hits: float = 0.0 # hits spent killing wounded back goblins
	var healthy_half_hits: float = 0.0 # hits spent wounding healthy back goblins
	var front_hits: float = 0.0 # hits spent killing/wounding the front goblin
	
	if target.back_count.is_gt(0):
		# calculate full hits (to kill healthy back goblins)
		full_hits = unassigned_hits * brutality
		full_hits = floor_to_multiple(full_hits, hits_per_kill)
		full_hits = min(full_hits, unassigned_hits, _max_full_hits(target, hits_per_kill))
		unassigned_hits -= full_hits
		
		# calculate wounded half-hits (to kill wounded back goblins)
		var half_hits: float = unassigned_hits
		wounded_half_hits = half_hits * (target.back_wounded.to_float() / target.back_count.to_float())
		wounded_half_hits = floor_to_multiple(wounded_half_hits, hits_per_wound)
		wounded_half_hits = min(wounded_half_hits, unassigned_hits, _max_wounded_half_hits(target, hits_per_wound))
		unassigned_hits -= wounded_half_hits
		
		# calculate healthy half-hits (to wound healthy back goblins)
		healthy_half_hits = floor_to_multiple(unassigned_hits, hits_per_wound)
		healthy_half_hits = min(healthy_half_hits, unassigned_hits, _max_healthy_half_hits(target, hits_per_wound))
		unassigned_hits -= healthy_half_hits
	
	# calculate front_hits (to wound/kill the front goblin)
	front_hits  = unassigned_hits
	
	# apply full hits (to kill healthy back goblins)
	var healthy_to_dead: float = roundf(full_hits / hits_per_kill)
	target.back_count = Big.sub(target.back_count, healthy_to_dead)
	
	# apply wounded half-hits (to kill wounded back goblins)
	var wounded_to_dead: float = roundf(wounded_half_hits / hits_per_wound)
	target.back_count = Big.sub(target.back_count, wounded_to_dead)
	target.back_wounded = Big.sub(target.back_wounded, wounded_to_dead)
	
	# apply healthy half-hits (to wound healthy back goblins)
	# ensure we don't try to wound more guys than possible
	if healthy_half_hits > _max_healthy_half_hits(target, hits_per_wound):
		var excess_hits: float = (healthy_half_hits - _max_healthy_half_hits(target, hits_per_wound))
		hits_taken = Big.sub(hits_taken, excess_hits)
		healthy_half_hits -= excess_hits
	var healthy_to_wounded: float = roundf(healthy_half_hits / hits_per_wound)
	target.back_wounded = Big.add(target.back_wounded, healthy_to_wounded)
	
	# apply front hits (to wound/kill the front goblin)
	if front_hits >= hits_to_kill_front:
		if front_hits > hits_to_kill_front:
			var excess_hits: float = (front_hits - _hits_to_kill_front(target, damage_per_hit))
			hits_taken = Big.sub(hits_taken, excess_hits)
			front_hits -= excess_hits
		target.kill_front()
		front_hits -= hits_to_kill_front
		hits_to_kill_front = _hits_to_kill_front(target, damage_per_hit)
	else:
		target.front_hp = max(1, target.front_hp - front_hits * damage_per_hit)
	
	hits_taken = Big.new(how_many_hits_will_we_do)
	killed_by_attack = Big.sub(old_target_count, target.get_count())
	
	target.assert_valid()
	target.fix_invalid()
	
	return {
		"hits_taken": hits_taken,
		"kill_count": killed_by_attack,
	}


static func find_target_index_for_attack(attacker_pool: AttackerPool, defender_pool: DefenderPool, \
		start_index: int) -> int:
	var attack: Attack = attacker_pool.current()
	var best_target_index: int = 0
	var best_effectiveness: float = 0.0
	for target_offset: int in defender_pool.size():
		var target_index: int = (start_index + target_offset) % defender_pool.size()
		var target_gob: Gob = defender_pool.get_gob_at(target_index)
		var target_effectiveness: float = effectiveness(attack.source.type, target_gob.type)
		if target_effectiveness > best_effectiveness:
			best_effectiveness = target_effectiveness
			best_target_index = target_index
			if target_effectiveness == STRONG:
				break
	return best_target_index


static func resolve_level_ups(army: Army) -> Array[LevelUp]:
	var level_ups: Array[LevelUp] = []
	for gob: Gob in army.gobs:
		var level_up_count: int = 0
		while gob.can_level_up():
			gob.level_up()
			level_up_count += 1
		
		if level_up_count >= 1:
			var level_up: LevelUp = LevelUp.new()
			level_up.gob = gob
			level_up.count = level_up_count
			level_ups.append(level_up)
	return level_ups


static func _max_full_hits(target: Gob, hits_per_kill: int) -> float:
	return hits_per_kill * (target.back_count.to_float() - target.back_wounded.to_float())


static func _max_wounded_half_hits(target: Gob, hits_per_wound: int) -> float:
	return hits_per_wound * target.back_wounded.to_float()


static func _max_healthy_half_hits(target: Gob, hits_per_wound: int) -> float:
	return hits_per_wound * (target.back_count.to_float() - target.back_wounded.to_float())


static func _hits_to_kill_front(target: Gob, damage_per_hit: int) -> int:
	return ceili(target.front_hp / float(damage_per_hit))


class Attack:
	var source: Gob
	var count: Big = Big.ZERO
	var wounded: bool = false


class Kill:
	var source: Gob
	var target: Gob
	var kill_count: Big = Big.ZERO
	var wounded_count: Big = Big.ZERO


class LevelUp:
	var gob: Gob
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
	var vulnerable_gobs: Array[Gob] = []
	
	func _init(army: Army, vulnerable_types: Array[Gobs.Type]) -> void:
		for gob: Gob in army.gobs:
			if gob.type in vulnerable_types:
				vulnerable_gobs.append(gob)
	
	
	func is_empty() -> bool:
		return vulnerable_gobs.is_empty()
	
	
	func get_gob_at(index: int) -> Gob:
		return vulnerable_gobs[index]
	
	
	func remove_at(index: int) -> void:
		vulnerable_gobs.remove_at(index)
	
	
	func size() -> int:
		return vulnerable_gobs.size()
