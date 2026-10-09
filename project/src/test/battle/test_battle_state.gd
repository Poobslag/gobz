extends GutTest

const FIRE: Gobs.Type = Gobs.Type.FIRE
const WATER: Gobs.Type = Gobs.Type.WATER
const GRASS: Gobs.Type = Gobs.Type.GRASS
const ANGEL: Gobs.Type = Gobs.Type.ANGEL
const DEVIL: Gobs.Type = Gobs.Type.DEVIL

var player_army: Army = Army.new()
var enemy_army: Army = Army.new()
var player_orders: Array[Gobs.Type] = [FIRE, WATER, GRASS, ANGEL, DEVIL]
var enemy_orders: Array[Gobs.Type] = [FIRE, WATER, GRASS, ANGEL, DEVIL]

var state: BattleState

func before_each() -> void:
	player_army.reset()
	enemy_army.reset()
	player_orders = [FIRE, WATER, GRASS, ANGEL, DEVIL]
	enemy_orders = [FIRE, WATER, GRASS, ANGEL, DEVIL]


## A few size-1 gobs which split evenly into multiples of 5
func test_deploy_next_10_5() -> void:
	for _i in 10:
		player_army.add_gob(gob("🔥 3"))
	for _i in 5:
		enemy_army.add_gob(gob("💧 3"))
	state = new_battle_state()
	
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 2)
	assert_eq(state.enemy_side.active_gobs.size(), 1)
	
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 4)
	assert_eq(state.enemy_side.active_gobs.size(), 2)
	
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 6)
	assert_eq(state.enemy_side.active_gobs.size(), 3)
	
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 8)
	assert_eq(state.enemy_side.active_gobs.size(), 4)
	
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 10)
	assert_eq(state.enemy_side.active_gobs.size(), 5)
	
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 10)
	assert_eq(state.enemy_side.active_gobs.size(), 5)


## Checks for floating point issues. Deploying 20% of 9.99e30 five times can result in a remainder.
func test_deploy_next_float_precision( \
		params: float = use_parameters([100.0, 9.99e15, 1.1e18, 1.1e30, 9.99e30])) -> void:
	
	var gob_count: float = params
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs.back().back_count = Big.new(gob_count - 1)
	state = new_battle_state()
	
	state.deploy_next()
	assert_almost_eq(state.player_side.get_total_active_goblins().to_float(), gob_count * 0.2, gob_count * 0.01)
	
	state.deploy_next()
	assert_almost_eq(state.player_side.get_total_active_goblins().to_float(), gob_count * 0.4, gob_count * 0.01)
	
	state.deploy_next()
	state.deploy_next()
	state.deploy_next()
	assert_almost_eq(state.player_side.get_total_active_goblins().to_float(), gob_count, gob_count * 0.01)
	assert_eq(state.player_side.get_total_reserve_goblins().to_int(), 0)


func test_from_armies_orders_types() -> void:
	for _i in 5:
		player_army.add_gob(gob("🔥 3"))
		player_army.add_gob(gob("💧 3"))
		player_army.add_gob(gob("🌳 3"))
	player_orders = [WATER, FIRE]
	state = new_battle_state()
	
	assert_eq(state.player_side.reserve_gobs.size(), 10)
	assert_eq(state.player_side.reserve_gobs[0].type, WATER)
	assert_eq(state.player_side.reserve_gobs[4].type, WATER)
	assert_eq(state.player_side.reserve_gobs[5].type, FIRE)
	assert_eq(state.player_side.reserve_gobs[9].type, FIRE)


## Only 3 goblins -- 1 per round for the first 3 rounds, then 0
func test_deploy_next_3() -> void:
	for _i in 3:
		player_army.add_gob(gob("🔥 3"))
	state = new_battle_state()
	
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 1)
	
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 2)
	
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 3)
	
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 3)


## Splits up a gob with 10 goblins
func test_deploy_next_split_large_gob() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs.back().back_count = Big.new(9)
	state = new_battle_state()
	
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 1)
	assert_eq(state.player_side.reserve_gobs.size(), 1)
	assert_eq(state.player_side.get_total_active_goblins().to_int(), 2)
	
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 2)
	assert_eq(state.player_side.reserve_gobs.size(), 1)
	assert_eq(state.player_side.get_total_active_goblins().to_int(), 4)
	
	state.deploy_next()
	state.deploy_next()
	state.deploy_next()
	assert_eq(state.player_side.active_gobs.size(), 5)
	assert_eq(state.player_side.reserve_gobs.size(), 0)
	assert_eq(state.player_side.get_total_active_goblins().to_int(), 10)


func test_unfrag_noop() -> void:
	for _i in 10:
		player_army.add_gob(gob("🔥 3"))
	state = new_battle_state()
	
	# no frags
	state.deploy_next()
	state.deploy_next()
	state.deploy_next()
	
	state.unfrag()
	assert_eq(player_army.gobs.size(), 10)
	assert_eq(player_army.get_total_goblins().to_int(), 10)


func test_unfrag_2_frags() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs.back().back_count = Big.new(9)
	player_army.gobs.back().name = "Kleex"
	player_army.gobs.back().id = 896
	state = new_battle_state()
	
	state.deploy_next()
	assert_eq(player_army.gobs.size(), 2)
	
	state.unfrag()
	assert_eq(player_army.gobs.size(), 1)
	assert_eq(player_army.get_total_goblins().to_int(), 10)
	assert_eq(player_army.gobs[0].name, "Kleex")
	assert_eq(player_army.gobs[0].id, 896)


func test_unfrag_root_dies() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs.back().back_count = Big.new(9)
	player_army.gobs.back().name = "Kleex"
	player_army.gobs.back().id = 896
	state = new_battle_state()
	
	# frag the gob, and ensure the frag has a different name/id
	state.deploy_next()
	assert_eq(player_army.gobs.size(), 2)
	assert_ne(player_army.gobs[1].name, "Kleex")
	assert_ne(player_army.gobs[1].id, 896)
	
	# kill the root gob
	player_army.remove_gob(player_army.gobs[0])
	
	state.unfrag()
	assert_eq(player_army.gobs.size(), 1)
	assert_eq(player_army.get_total_goblins().to_int(), 2)
	assert_eq(player_army.gobs[0].name, "Kleex")
	assert_eq(player_army.gobs[0].id, 896)


func test_unfrag_root_and_frag_die() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs.back().back_count = Big.new(9)
	player_army.gobs.back().name = "Kleex"
	player_army.gobs.back().id = 896
	state = new_battle_state()
	
	# frag the gob, and ensure the frag has a different name/id
	state.deploy_next()
	
	# kill the root and frag gobs
	player_army.remove_gob(player_army.gobs[0])
	player_army.remove_gob(player_army.gobs[0])
	
	state.unfrag()
	assert_eq(player_army.gobs.size(), 0)


func test_unfrag_frag_outlevels_root() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs.back().back_count = Big.new(9)
	player_army.gobs.back().name = "Kleex"
	player_army.gobs.back().id = 896
	state = new_battle_state()
	
	# frag the gob, and ensure the frag has a different name/id
	state.deploy_next()
	assert_eq(player_army.gobs.size(), 2)
	assert_ne(player_army.gobs[1].name, "Kleex")
	assert_ne(player_army.gobs[1].id, 896)
	
	# level up the 1st frag
	player_army.gobs[1].level_up()
	
	state.unfrag()
	assert_eq(player_army.gobs.size(), 1)
	assert_eq(player_army.get_total_goblins().to_int(), 10)
	assert_eq(player_army.gobs[0].name, "Kleex")
	assert_eq(player_army.gobs[0].id, 896)
	assert_eq(player_army.gobs[0].level, 4)


func test_unfrag_3_frags() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs.back().back_count = Big.new(9)
	state = new_battle_state()
	
	state.deploy_next()
	state.deploy_next()
	assert_eq(player_army.gobs.size(), 3)
	
	state.unfrag()
	assert_eq(player_army.gobs.size(), 1)
	assert_eq(player_army.get_total_goblins().to_int(), 10)


func test_unfrag_5_frags_frag_outlevels_root() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs.back().back_count = Big.new(9)
	player_army.gobs.back().name = "Kleex"
	player_army.gobs.back().id = 896
	state = new_battle_state()
	
	state.deploy_next()
	state.deploy_next()
	state.deploy_next()
	state.deploy_next()
	state.deploy_next()
	assert_eq(player_army.gobs.size(), 5)
	player_army.gobs[2].level_up()
	player_army.remove_gob(player_army.gobs[3])
	
	state.unfrag()
	assert_eq(player_army.gobs.size(), 1)
	assert_eq(player_army.get_total_goblins().to_int(), 8)
	assert_eq(player_army.gobs[0].level, 4)
	assert_eq(player_army.gobs[0].name, "Kleex")
	assert_eq(player_army.gobs[0].id, 896)


func test_update_player_orders_recalculates_goblins_per_round() -> void:
	for _i in 10:
		player_army.add_gob(gob("🔥 3"))
	for _i in 5:
		player_army.add_gob(gob("💧 3"))
	player_orders = [FIRE]
	state = new_battle_state()
	
	state.deploy_next()
	# 2🔥 active, 8🔥 in reserve
	assert_eq(state.player_side.get_total_active_goblins().to_int(), 2)
	assert_eq(state.player_side.get_total_reserve_goblins().to_int(), 8)
	
	state.update_player_orders([WATER])
	state.deploy_next()
	# 2🔥, 1💧 active, 4💧 in reserve
	assert_eq(state.player_side.get_total_active_goblins().to_int(), 3)
	assert_eq(state.player_side.get_total_reserve_goblins().to_int(), 4)


func test_update_player_orders_unfrag_edge_case() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs.back().back_count = Big.new(9)
	player_army.add_gob(gob("💧 3"))
	player_orders = [FIRE]
	state = new_battle_state()
	
	state.deploy_next()
	# 2🔥 active, 8🔥 in reserve (fragged)
	assert_eq(state.player_side.get_total_active_goblins().to_int(), 2)
	assert_eq(state.player_side.get_total_reserve_goblins().to_int(), 8)
	assert_eq(player_army.gobs.size(), 3)
	
	state.update_player_orders([WATER])
	state.deploy_next()
	# 2🔥, 1💧 active, 8🔥 in reserve (fragged)
	assert_eq(state.player_side.get_total_active_goblins().to_int(), 3)
	assert_eq(state.player_side.get_total_reserve_goblins().to_int(), 0)
	assert_eq(player_army.gobs.size(), 3)
	
	state.unfrag()
	# 10🔥, 1💧 in the player's army. The 🔥 goblin has been unfragged.
	assert_eq(player_army.gobs.size(), 2)


func new_battle_state() -> BattleState:
	var battle_state: BattleState = BattleState.new(player_army, enemy_army)
	battle_state.update_player_orders(player_orders)
	battle_state.update_enemy_orders(enemy_orders)
	return battle_state


func gob(s: String) -> Gob:
	return ArmyTestUtils.gob(s)
