extends GutTest

const FIRE: Gobs.Type = Gobs.Type.FIRE
const WATER: Gobs.Type = Gobs.Type.WATER
const GRASS: Gobs.Type = Gobs.Type.GRASS
const ANGEL: Gobs.Type = Gobs.Type.ANGEL
const DEVIL: Gobs.Type = Gobs.Type.DEVIL

var player_army: Army = Army.new()
var enemy_army: Army = Army.new()
var player_orders: Array[Gobs.Type] = []
var enemy_orders: Array[Gobs.Type] = []
var attack_type: Gobs.Type = FIRE
var vulnerable_types: Array[Gobs.Type] = [FIRE, WATER, GRASS, ANGEL, DEVIL]
var battle_result: Dictionary[String, Variant] = {}

func before_each() -> void:
	player_army = Army.new()
	enemy_army = Army.new()
	player_orders.clear()
	enemy_orders.clear()


func gob(s: String) -> Gob:
	return ArmyTestUtils.gob(s)


func attack(source: Army, target: Army, \
		source_index: int, target_index: int) -> BattleResolver.Attack:
	var new_attack: BattleResolver.Attack = BattleResolver.Attack.new()
	new_attack.source = source.gobs[source_index]
	new_attack.target = target.gobs[target_index]
	new_attack.damage = BattleResolver.base_damage(new_attack.source, new_attack.target)
	return new_attack


func plan_and_resolve_attacks() -> void:
	battle_result["attacks"] = BattleResolver.plan_attacks(player_army, attack_type)
	battle_result["kills"] = BattleResolver.resolve_attacks(
			player_army, enemy_army, battle_result["attacks"], vulnerable_types)


func assert_kills(expected_kill_strings: Array[String]) -> void:
	var got_kill_strings: Array[String] = []
	for kill: BattleResolver.Kill in battle_result["kills"]:
		var source_string: String = "%s %s" % [Gobs.emoji_from_type(kill.source.type), kill.source.level]
		var target_string: String = "%s %s" % [Gobs.emoji_from_type(kill.target.type), kill.target.level]
		var kw_string: String = "%s/%s" % [kill.kill_count.to_aa(), kill.wounded_count.to_aa()]
		got_kill_strings.append("%s -> %s, %s" % [source_string, target_string, kw_string])
	assert_eq(got_kill_strings, expected_kill_strings)


func test_3v3() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs[0].count = Big.new(3)
	enemy_army.add_gob(gob("🔥 3"))
	enemy_army.gobs[0].count = Big.new(3)
	plan_and_resolve_attacks()
	
	# our units kill an enemy and wound another
	assert_kills(["🔥 3 -> 🔥 3, 1/1"])


func test_3v3_kill_wounded() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs[0].count = Big.new(3)
	enemy_army.add_gob(gob("🔥 3"))
	enemy_army.gobs[0].count = Big.new(3)
	enemy_army.gobs[0].hp = 1
	plan_and_resolve_attacks()
	
	# our units kill the wounded enemy and one more
	assert_kills(["🔥 3 -> 🔥 3, 2/0"])


func test_3v3_wound_wounded() -> void:
	player_army.add_gob(gob("🔥 3"))
	enemy_army.add_gob(gob("🔥 3"))
	enemy_army.gobs[0].count = Big.new(3)
	enemy_army.gobs[0].hp = 10
	plan_and_resolve_attacks()
	
	# our single gob doesn't deal enough damage to kill the wounded enemy
	assert_kills(["🔥 3 -> 🔥 3, 0/1"])


func test_10_trillion_v_10_trillion() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs[0].count = Big.new(10_000_000_000_000)
	enemy_army.add_gob(gob("🔥 3"))
	enemy_army.gobs[0].count = Big.new(10_000_000_000_000)
	plan_and_resolve_attacks()
	
	assert_kills(["🔥 3 -> 🔥 3, 5.0t/0"])


func test_prefer_effective_target() -> void:
	player_army.add_gob(gob("🔥 3"))
	enemy_army.add_gob(gob("🔥 3"))
	enemy_army.add_gob(gob("💧 3"))
	enemy_army.add_gob(gob("🌳 3"))
	plan_and_resolve_attacks()
	
	assert_kills(["🔥 3 -> 🌳 3, 1/0"])


func test_overkill_two_units() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs[0].count = Big.new(2)
	enemy_army.add_gob(gob("🔥 2"))
	enemy_army.add_gob(gob("💧 2"))
	enemy_army.add_gob(gob("🌳 2"))
	plan_and_resolve_attacks()
	
	# kills the vulnerable target, and splashes onto the second target
	assert_kills([
		"🔥 3 -> 🌳 2, 1/0",
		"🔥 3 -> 🔥 2, 0/1"])


func test_overkill_one_unit() -> void:
	player_army.add_gob(gob("🔥 9"))
	enemy_army.add_gob(gob("🔥 1"))
	enemy_army.add_gob(gob("💧 1"))
	enemy_army.add_gob(gob("🌳 1"))
	plan_and_resolve_attacks()
	
	# kills the vulnerable target, but does not splash
	assert_kills([
		"🔥 9 -> 🌳 1, 1/0"])


func test_resolve_level_ups() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs[0].xp = 11
	
	BattleResolver.resolve_level_ups(player_army)
	
	assert_eq(player_army.gobs[0].level, 4)
	assert_eq(player_army.gobs[0].xp, 3)


func test_wound_and_kill() -> void:
	player_army.add_gob(gob("🔥 1"))
	player_army.add_gob(gob("🔥 1"))
	enemy_army.add_gob(gob("🔥 1"))
	plan_and_resolve_attacks()
	
	# the target requires two attacks to die, but we don't report them as wounded
	assert_kills([
		"🔥 1 -> 🔥 1, 1/0"])
