class_name BattleState

const ROUND_COUNT: int = 5
const DEFAULT_ATTACK_SCALE: float = 2.0 / (ROUND_COUNT + 1)

var player_side: BattleSide = BattleSide.new()
var enemy_side: BattleSide = BattleSide.new()
var attack_scale: float = DEFAULT_ATTACK_SCALE

func clear() -> void:
	player_side.clear()
	enemy_side.clear()
	attack_scale = DEFAULT_ATTACK_SCALE


func update_player_orders(new_player_orders: Array[Gobs.Type]) -> void:
	_update_orders(player_side, new_player_orders)


func update_enemy_orders(new_enemy_orders: Array[Gobs.Type]) -> void:
	_update_orders(enemy_side, new_enemy_orders)


## Deploy the next 20% of gobs from each side's reserve pool, splitting gobs if necessary
func deploy_next() -> DeployResult:
	var result: DeployResult = DeployResult.new()
	result.player_deployments = player_side.deploy_next()
	result.enemy_deployments = enemy_side.deploy_next()
	return result


## Deploy all gobs from each side's reserve pool
func deploy_all() -> DeployResult:
	var result: DeployResult = DeployResult.new()
	result.player_deployments = player_side.deploy_all()
	result.enemy_deployments = enemy_side.deploy_all()
	return result


func unfrag() -> void:
	player_side.unfrag()
	enemy_side.unfrag()


func _update_orders(battle_side: BattleSide, new_orders: Array[Gobs.Type]) -> void:
	battle_side.reserve_gobs.clear()
	battle_side.rebuild_reserve(new_orders)


func _init(init_player_army: Army, init_enemy_army: Army) -> void:
	player_side.army = init_player_army
	enemy_side.army = init_enemy_army


class BattleSide:
	var army: Army
	var active_gobs: Array[Gob] = []
	var reserve_gobs: Array[Gob] = []
	
	var _goblins_per_round: float
	var _roots_by_frag: Dictionary[Gob, Gob] = {}
	var _frags_by_root: Dictionary[Gob, Array] = {}
	var _deploy_count: int = 0
	
	func rebuild_reserve(orders: Array[Gobs.Type]) -> void:
		# calculate available_gobs_by_type (goblins not in the active queue)
		var available_gobs_by_type: Dictionary[Gobs.Type, Array] = {}
		for type: Gobs.Type in orders:
			available_gobs_by_type[type] = [] as Array[Gob]
		var active_gobs_set: Dictionary[Gob, bool] = {}
		for gob: Gob in active_gobs:
			active_gobs_set[gob] = true
		for gob: Gob in army.gobs:
			if active_gobs_set.has(gob):
				continue
			if available_gobs_by_type.has(gob.type):
				available_gobs_by_type[gob.type].append(gob)
		
		# append gobs from available_gobs_by_type into reserve_gobs
		for type: Gobs.Type in orders:
			available_gobs_by_type[type].shuffle()
			reserve_gobs.append_array(available_gobs_by_type[type])
		
		# recalculate _goblins_per_round, reset _deploy_count
		_deploy_count = 0
		var total_count: float = 0.0
		for gob: Gob in reserve_gobs:
			total_count += gob.get_count().to_float()
		_goblins_per_round = ceil(total_count / float(ROUND_COUNT))
	
	
	func clear() -> void:
		army = null
		active_gobs = []
		reserve_gobs = []
		
		_goblins_per_round = 0.0
		_frags_by_root = {}
		_roots_by_frag = {}
		_deploy_count = 0
	
	
	func deploy_next() -> Array[Deployment]:
		_deploy_count += 1
		if _deploy_count >= ROUND_COUNT:
			# To avoid floating point issues, we empty the reserve in the final round
			return deploy_all()
		
		var new_gobs: Array[Gob] = _take_from_reserve(_goblins_per_round)
		return _deploy(new_gobs)
	
	
	func deploy_all() -> Array[Deployment]:
		_deploy_count = maxi(_deploy_count, ROUND_COUNT)
		var new_gobs: Array[Gob] = _take_all_from_reserve()
		return _deploy(new_gobs)
	
	
	func is_empty() -> bool:
		return active_gobs.is_empty() and reserve_gobs.is_empty()
	
	
	func get_total_active_goblins() -> Big:
		var count: float = 0.0
		for gob: Gob in active_gobs:
			count += gob.get_count().to_float()
		return Big.new(count)
	
	
	func get_total_reserve_goblins() -> Big:
		var count: float = 0.0
		for gob: Gob in reserve_gobs:
			count += gob.get_count().to_float()
		return Big.new(count)
	
	
	func get_total_goblins() -> Big:
		var count: float = 0.0
		for gob: Gob in active_gobs:
			count += gob.get_count().to_float()
		for gob: Gob in reserve_gobs:
			count += gob.get_count().to_float()
		return Big.new(count)
	
	
	## Returns the root's id for a fragment, and the gob's own id otherwise.
	func get_frag_root_id(gob: Gob) -> int:
		return _roots_by_frag[gob].id if gob in _roots_by_frag else gob.id
	
	
	func unfrag() -> void:
		for root_gob: Gob in _frags_by_root:
			var survivor_gob: Gob = root_gob if army.gobs.has(root_gob) else null
			for frag_gob: Gob in _frags_by_root[root_gob]:
				if not army.gobs.has(frag_gob):
					continue
				
				if survivor_gob == null:
					survivor_gob = frag_gob
					continue
				
				# merge this fragment into the running survivor
				survivor_gob = _merge_gob(survivor_gob, frag_gob)
			if survivor_gob != null:
				survivor_gob.name = root_gob.name
				survivor_gob.id = root_gob.id
		_frags_by_root.clear()
		_roots_by_frag.clear()
	
	
	func get_active_summary() -> ArmySummary:
		return ArmySummary.from_gobs(active_gobs)
	
	
	func remove_active_gob(gob: Gob) -> void:
		active_gobs.erase(gob)
		army.remove_gob(gob)
	
	
	func get_available_types() -> Array[Gobs.Type]:
		var available_gob_types: Dictionary[Gobs.Type, bool] = {}
		var reserve_gob_set: Dictionary[Gob, bool] = {}
		for gob: Gob in reserve_gobs:
			reserve_gob_set[gob] = true
		var active_gob_set: Dictionary[Gob, bool] = {}
		for gob: Gob in active_gobs:
			active_gob_set[gob] = true
		for gob: Gob in PlayerData.army.gobs:
			if gob.type in available_gob_types:
				continue
			if reserve_gob_set.has(gob) or active_gob_set.has(gob):
				continue
			available_gob_types[gob.type] = true
		return available_gob_types.keys()
	
	
	func has_undeployed_goblins() -> bool:
		return not get_available_types().is_empty()
	
	
	func get_reserve_types() -> Array[Gobs.Type]:
		var types: Array[Gobs.Type] = []
		for gob: Gob in reserve_gobs:
			if types.has(gob.type):
				continue
			types.append(gob.type)
		return types
	
	
	func remove_reserve_type(type: Gobs.Type) -> void:
		for i in range(reserve_gobs.size() - 1, -1, -1):
			if reserve_gobs[i].type == type:
				reserve_gobs.remove_at(i)
	
	
	func _merge_gob(gob_a: Gob, gob_b: Gob) -> Gob:
		var survivor_gob: Gob = army.merge_gob(gob_a, gob_b)
		var absorbed_gob: Gob = gob_a if survivor_gob == gob_b else gob_b
		reserve_gobs.erase(absorbed_gob)
		active_gobs.erase(absorbed_gob)
		return survivor_gob
	
	
	func _deploy(new_gobs: Array[Gob]) -> Array[Deployment]:
		active_gobs.append_array(new_gobs)
		var result: Array[Deployment] = []
		for new_gob: Gob in new_gobs:
			var deploy: Deployment = Deployment.new()
			deploy.gob = new_gob
			deploy.count = new_gob.get_count()
			result.append(deploy)
		return result
	
	
	func _take_all_from_reserve() -> Array[Gob]:
		var result: Array[Gob] = []
		result.append_array(reserve_gobs)
		reserve_gobs.clear()
		return result
	
	
	func _take_from_reserve(goblin_count: float) -> Array[Gob]:
		var result: Array[Gob] = []
		var remaining_count: float = goblin_count
		while remaining_count >= 1.0 and not reserve_gobs.is_empty():
			var next_gob: Gob = reserve_gobs.pop_front()
			var next_gob_count: float = next_gob.get_count().to_float()
			if remaining_count >= next_gob_count:
				# append the gob and continue
				result.append(next_gob)
				remaining_count -= next_gob_count
			else:
				# fragment the gob
				var frag_gob: Gob = army.split_gob(next_gob, Big.new(remaining_count))
				reserve_gobs.insert(0, next_gob)
				
				result.append(frag_gob)
				remaining_count = 0.0
				
				if not _frags_by_root.has(next_gob):
					_frags_by_root[next_gob] = [] as Array[Gob]
				_frags_by_root[next_gob].append(frag_gob)
				_roots_by_frag[frag_gob] = next_gob
		return result


class DeployResult:
	var player_deployments: Array[Deployment]
	var enemy_deployments: Array[Deployment]


class Deployment:
	var gob: Gob
	var count: Big = Big.ZERO
