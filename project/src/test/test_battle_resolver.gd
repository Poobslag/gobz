extends GutTest

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
	var from: Army = Army.new()
	from.add_item(army_item("🔥 3"))
	
	var to: Army = Army.new()
	to.add_item(army_item("🔥 3"))
	to.add_item(army_item("💧 3"))
	to.add_item(army_item("🌳 3"))
	
	var attacks: Array[BattleResolver.Attack] = BattleResolver.plan_attacks(from, to, Goblins.FIRE)
	assert_eq(attacks[0].target.type, Goblins.GRASS)


func test_plan_attacks_prefer_kill() -> void:
	var from: Army = Army.new()
	from.add_item(army_item("🔥 2"))
	
	var to: Army = Army.new()
	to.add_item(army_item("🔥 1"))
	to.add_item(army_item("🔥 9"))
	
	var attacks: Array[BattleResolver.Attack] = BattleResolver.plan_attacks(from, to, Goblins.FIRE)
	assert_eq(attacks[0].target.level, 1)


func test_plan_attacks_avoid_overkill() -> void:
	var from: Army = Army.new()
	from.add_item(army_item("🔥 8"))
	
	var to: Army = Army.new()
	to.add_item(army_item("🔥 1"))
	to.add_item(army_item("🔥 9"))
	
	var attacks: Array[BattleResolver.Attack] = BattleResolver.plan_attacks(from, to, Goblins.FIRE)
	assert_eq(attacks[0].target.level, 9)


func test_plan_attacks_dont_double_team() -> void:
	var from: Army = Army.new()
	from.add_item(army_item("🔥 2"))
	from.add_item(army_item("🔥 2"))
	from.add_item(army_item("🔥 2"))
	from.add_item(army_item("🔥 2"))
	from.add_item(army_item("🔥 2"))
	
	var to: Army = Army.new()
	to.add_item(army_item("🔥 1"))
	to.add_item(army_item("🔥 9"))
	
	var attacks: Array[BattleResolver.Attack] = BattleResolver.plan_attacks(from, to, Goblins.FIRE)
	assert_eq(attacks[0].target.level, 1)
	assert_eq(attacks[1].target.level, 9)
	assert_eq(attacks[2].target.level, 9)
	assert_eq(attacks[3].target.level, 9)
	assert_eq(attacks[4].target.level, 9)


func test_plan_attacks_cant_hit_cowards() -> void:
	var from: Army = Army.new()
	from.add_item(army_item("🔥 2"))
	
	var to: Army = Army.new()
	to.add_item(army_item("💧 1"))
	to.add_item(army_item("🌳 1"))
	
	var attacks: Array[BattleResolver.Attack] = \
			BattleResolver.plan_attacks(from, to, Goblins.FIRE, [Goblins.GoblinType.WATER])
	assert_eq(attacks[0].target.type, Goblins.GoblinType.WATER)


func test_resolve_attacks() -> void:
	var from: Army = Army.new()
	from.add_item(army_item("🔥 3"))
	
	var to: Army = Army.new()
	to.add_item(army_item("🔥 3"))
	to.add_item(army_item("💧 3"))
	to.add_item(army_item("🌳 3"))
	
	var attacks: Array[BattleResolver.Attack] = [
		attack(from, to, 0, 2),
	]
	BattleResolver.resolve_attacks(from, to, attacks)
	
	assert_eq(to.items.size(), 2)
	assert_eq(attacks[0].source.experience, 4)
	assert_eq(attacks[0].target.count, 0)


func test_resolve_attacks_kill_wounded_guy() -> void:
	var from: Army = Army.new()
	from.add_item(army_item("🔥 3"))
	
	var to: Army = Army.new()
	to.add_item(army_item("🔥 3"))
	
	var attacks: Array[BattleResolver.Attack] = [
		attack(from, to, 0, 0),
	]
	to.items[0].hp = 1
	attacks[0].damage = 3
	BattleResolver.resolve_attacks(from, to, attacks)
	
	assert_eq(to.items.size(), 0)
	assert_eq(attacks[0].source.experience, 4)
	assert_eq(attacks[0].target.count, 0)


func test_resolve_level_ups() -> void:
	var from: Army = Army.new()
	from.add_item(army_item("🔥 3"))
	from.items[0].experience = 11
	
	BattleResolver.resolve_level_ups(from)
	
	assert_eq(from.items[0].level, 4)
	assert_eq(from.items[0].experience, 3)
