extends GutTest

var player_army: Army = Army.new()
var enemy_army: Army = Army.new()
var player_orders: Array[Goblins.GoblinType] = []
var enemy_orders: Array[Goblins.GoblinType] = []

func before_each() -> void:
	player_army = Army.new()
	enemy_army = Army.new()
	player_orders.clear()
	enemy_orders.clear()


func army_item(s: String) -> Army.ArmyItem:
	return ArmyTestUtils.army_item(s)


func attack(source: Army, target: Army, \
		source_index: int, target_index: int) -> BattleResolver.Attack:
	var new_attack: BattleResolver.Attack = BattleResolver.Attack.new()
	new_attack.source = source.items[source_index]
	new_attack.target = target.items[target_index]
	new_attack.damage = BattleResolver.base_damage(new_attack.source, new_attack.target)
	return new_attack


func test_plan_attacks_prefer_effective_target() -> void:
	player_army.add_item(army_item("🔥 3"))
	
	enemy_army.add_item(army_item("🔥 3"))
	enemy_army.add_item(army_item("💧 3"))
	enemy_army.add_item(army_item("🌳 3"))
	
	var attacks: Array[BattleResolver.Attack] = BattleResolver.plan_attacks(player_army, enemy_army, Goblins.FIRE)
	assert_eq(attacks[0].target.type, Goblins.GRASS)


func test_plan_attacks_prefer_kill() -> void:
	player_army.add_item(army_item("🔥 2"))
	
	enemy_army.add_item(army_item("🔥 1"))
	enemy_army.add_item(army_item("🔥 9"))
	
	var attacks: Array[BattleResolver.Attack] = BattleResolver.plan_attacks(player_army, enemy_army, Goblins.FIRE)
	assert_eq(attacks[0].target.level, 1)


func test_plan_attacks_avoid_overkill() -> void:
	player_army.add_item(army_item("🔥 8"))
	
	enemy_army.add_item(army_item("🔥 1"))
	enemy_army.add_item(army_item("🔥 9"))
	
	var attacks: Array[BattleResolver.Attack] = BattleResolver.plan_attacks(player_army, enemy_army, Goblins.FIRE)
	assert_eq(attacks[0].target.level, 9)


func test_plan_attacks_dont_double_team() -> void:
	player_army.add_item(army_item("🔥 2"))
	player_army.add_item(army_item("🔥 2"))
	player_army.add_item(army_item("🔥 2"))
	player_army.add_item(army_item("🔥 2"))
	player_army.add_item(army_item("🔥 2"))
	
	enemy_army.add_item(army_item("🔥 1"))
	enemy_army.add_item(army_item("🔥 9"))
	
	var attacks: Array[BattleResolver.Attack] = BattleResolver.plan_attacks(player_army, enemy_army, Goblins.FIRE)
	assert_eq(attacks[0].target.level, 1)
	assert_eq(attacks[1].target.level, 9)
	assert_eq(attacks[2].target.level, 9)
	assert_eq(attacks[3].target.level, 9)
	assert_eq(attacks[4].target.level, 9)


func test_plan_attacks_cant_hit_cowards() -> void:
	player_army.add_item(army_item("🔥 2"))
	
	enemy_army.add_item(army_item("💧 1"))
	enemy_army.add_item(army_item("🌳 1"))
	
	var attacks: Array[BattleResolver.Attack] = \
			BattleResolver.plan_attacks(player_army, enemy_army, Goblins.FIRE, [Goblins.GoblinType.WATER])
	assert_eq(attacks[0].target.type, Goblins.GoblinType.WATER)


func test_resolve_attacks() -> void:
	player_army.add_item(army_item("🔥 3"))
	
	enemy_army.add_item(army_item("🔥 3"))
	enemy_army.add_item(army_item("💧 3"))
	enemy_army.add_item(army_item("🌳 3"))
	
	var attacks: Array[BattleResolver.Attack] = [
		attack(player_army, enemy_army, 0, 2),
	]
	BattleResolver.resolve_attacks(player_army, enemy_army, attacks)
	
	assert_eq(enemy_army.items.size(), 2)
	assert_eq(attacks[0].source.experience, 4)
	assert_eq(attacks[0].target.count, 0)


func test_resolve_attacks_kill_wounded_guy() -> void:
	player_army.add_item(army_item("🔥 3"))
	
	enemy_army.add_item(army_item("🔥 3"))
	
	var attacks: Array[BattleResolver.Attack] = [
		attack(player_army, enemy_army, 0, 0),
	]
	enemy_army.items[0].hp = 1
	attacks[0].damage = 3
	BattleResolver.resolve_attacks(player_army, enemy_army, attacks)
	
	assert_eq(enemy_army.items.size(), 0)
	assert_eq(attacks[0].source.experience, 4)
	assert_eq(attacks[0].target.count, 0)


func test_resolve_level_ups() -> void:
	var player_army: Army = Army.new()
	player_army.add_item(army_item("🔥 3"))
	player_army.items[0].experience = 11
	
	BattleResolver.resolve_level_ups(player_army)
	
	assert_eq(player_army.items[0].level, 4)
	assert_eq(player_army.items[0].experience, 3)
