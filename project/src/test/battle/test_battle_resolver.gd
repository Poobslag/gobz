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
	attack_type = FIRE
	vulnerable_types = [FIRE, WATER, GRASS, ANGEL, DEVIL]
	battle_result.clear()


func test_3v3() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs[0].back_count = Big.new(2)
	enemy_army.add_gob(gob("🔥 3"))
	enemy_army.gobs[0].back_count = Big.new(2)
	plan_and_resolve_attacks()
	
	# our units wound 3 enemies
	assert_kills(["🔥 3 -> 🔥 3, 0/3"])


func test_3v3_kill_wounded() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs[0].back_count = Big.new(2)
	enemy_army.add_gob(gob("🔥 3"))
	enemy_army.gobs[0].back_count = Big.new(2)
	enemy_army.gobs[0].front_hp = 1
	plan_and_resolve_attacks()
	
	# our units kill the wounded enemy and wound two more
	assert_kills(["🔥 3 -> 🔥 3, 1/2"])


func test_3v3_wound_wounded() -> void:
	player_army.add_gob(gob("🔥 3"))
	enemy_army.add_gob(gob("🔥 3"))
	enemy_army.gobs[0].back_count = Big.new(2)
	enemy_army.gobs[0].front_hp = 10
	plan_and_resolve_attacks()
	
	# our single gob doesn't deal enough damage to kill the wounded enemy
	assert_kills(["🔥 3 -> 🔥 3, 0/1"])


func test_10_trillion_v_10_trillion() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs[0].back_count = Big.new(9_999_999_999_999)
	enemy_army.add_gob(gob("🔥 3"))
	enemy_army.gobs[0].back_count = Big.new(9_999_999_999_999)
	plan_and_resolve_attacks()
	
	# our fire goblins kill 2.5t goblins and wound 5.0t
	assert_kills(["🔥 3 -> 🔥 3, 2.5t/5.0t"])


func test_prefer_effective_target() -> void:
	player_army.add_gob(gob("🔥 3"))
	enemy_army.add_gob(gob("🔥 3"))
	enemy_army.add_gob(gob("💧 3"))
	enemy_army.add_gob(gob("🌳 3"))
	plan_and_resolve_attacks()
	
	assert_kills(["🔥 3 -> 🌳 3, 1/0"])


func test_overkill_two_units() -> void:
	player_army.add_gob(gob("🔥 3"))
	player_army.gobs[0].back_count = Big.new(1)
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
	
	# the target requires two attacks to die
	assert_kills(["🔥 1 -> 🔥 1, 0/0", "🔥 1 -> 🔥 1, 1/0"])


func test_angels_wound() -> void:
	attack_type = Gobs.ANGEL
	player_army.add_gob(gob("🕊 5"))
	player_army.gobs[0].back_count = Big.new(99)
	enemy_army.add_gob(gob("🕊 5"))
	enemy_army.gobs[0].back_count = Big.new(99)
	plan_and_resolve_attacks()
	
	assert_kills([
		"🕊️ 5 -> 🕊️ 5, 5/90"])


func test_devils_kill() -> void:
	attack_type = Gobs.DEVIL
	player_army.add_gob(gob("😈 5"))
	player_army.gobs[0].back_count = Big.new(99)
	enemy_army.add_gob(gob("😈 5"))
	enemy_army.gobs[0].back_count = Big.new(99)
	plan_and_resolve_attacks()
	
	assert_kills([
		"😈 5 -> 😈 5, 45/10"])


func test_resolve_attack_healthy() -> void:
	player_army.add_gob(gob("🔥 5"))
	player_army.gobs[0].back_count = Big.new(9)
	enemy_army.add_gob(gob("🔥 5"))
	enemy_army.gobs[0].back_count = Big.new(9)
	
	var target: Gob = enemy_army.gobs[0]
	
	# assign 10 hits; 4 hits kill 2 units, the remaining 6 hits wound 6 units
	plan_and_resolve_attacks()
	assert_eq(target.back_count.to_int(), 7)
	assert_eq(target.back_wounded.to_int(), 6)
	assert_kills([
		"🔥 5 -> 🔥 5, 2/6"])


func test_resolve_attack_wounded_attackers() -> void:
	player_army.add_gob(gob("🔥 5"))
	player_army.gobs[0].back_count = Big.new(9)
	player_army.gobs[0].back_wounded = Big.new(9)
	player_army.gobs[0].front_hp = 10
	enemy_army.add_gob(gob("🔥 5"))
	enemy_army.gobs[0].back_count = Big.new(9)
	
	var target: Gob = enemy_army.gobs[0]
	
	# assign 10 weak hits; 4 hits kill 1 units, the remaining 6 hits wound 3 units
	plan_and_resolve_attacks()
	assert_eq(target.back_count.to_int(), 8)
	assert_eq(target.back_wounded.to_int(), 3)
	assert_kills([
		"🔥 5 -> 🔥 5, 1/3"])


func test_resolve_attack_wounded_attackers_murder_mode() -> void:
	player_army.add_gob(gob("🔥 5"))
	player_army.gobs[0].back_count = Big.new(9)
	player_army.gobs[0].back_wounded = Big.new(9)
	player_army.gobs[0].front_hp = 10
	enemy_army.add_gob(gob("🔥 5"))
	enemy_army.gobs[0].back_count = Big.new(9)
	
	var target: Gob = enemy_army.gobs[0]
	
	# assign 10 weak hits; 8 hits kill 2 units, 2 hits wound 1 unit
	var result: Dictionary[String, Variant] = resolve_attack(0, 0, true, true)
	assert_eq(target.back_count.to_int(), 7)
	assert_eq(target.back_wounded.to_int(), 1)
	assert_eq(result["kill_count"].to_int(), 2)
	assert_eq(result["hits_taken"].to_int(), 10)


func test_plan_and_resolve_attacks_wounded_defenders() -> void:
	player_army.add_gob(gob("🔥 5"))
	player_army.gobs[0].back_count = Big.new(9)
	enemy_army.add_gob(gob("🔥 5"))
	enemy_army.gobs[0].back_count = Big.new(9)
	enemy_army.gobs[0].back_wounded = Big.new(9)
	enemy_army.gobs[0].front_hp = 10
	
	var target: Gob = enemy_army.gobs[0]
	
	# assign 10 hits; 10 hits kill 10 wounded units
	plan_and_resolve_attacks()
	assert_eq(target.back_count.to_int(), 0)
	assert_eq(target.back_wounded.to_int(), 0)
	assert_kills(["🔥 5 -> 🔥 5, 10/0"])


func test_plan_and_resolve_attacks_david_goliath_1() -> void:
	player_army.add_gob(gob("🔥 1"))
	enemy_army.add_gob(gob("🔥 10"))
	var target: Gob = enemy_army.gobs[0]
	
	plan_and_resolve_attacks()
	assert_eq(target.back_count.to_int(), 0)
	assert_eq(target.back_wounded.to_int(), 0)
	assert_eq(40, target.front_hp)
	assert_kills(["🔥 1 -> 🔥 10, 0/0"])


func test_plan_and_resolve_attacks_david_goliath_10() -> void:
	player_army.add_gob(gob("🔥 1"))
	player_army.gobs[0].back_count = Big.new(9)
	enemy_army.add_gob(gob("🔥 10"))
	var target: Gob = enemy_army.gobs[0]
	
	plan_and_resolve_attacks()
	assert_eq(target.back_count.to_int(), 0)
	assert_eq(target.back_wounded.to_int(), 0)
	assert_eq(target.front_hp, 4)
	assert_kills(["🔥 1 -> 🔥 10, 0/1", "🔥 1 -> 🔥 10, 0/1"])


func test_plan_and_resolve_attacks_david_goliath_11() -> void:
	player_army.add_gob(gob("🔥 1"))
	player_army.gobs[0].back_count = Big.new(10)
	enemy_army.add_gob(gob("🔥 10"))
	var target: Gob = enemy_army.gobs[0]
	
	plan_and_resolve_attacks()
	assert_eq(target.back_count.to_int(), 0)
	assert_eq(target.back_wounded.to_int(), 0)
	assert_eq(target.front_hp, 0)
	assert_kills(["🔥 1 -> 🔥 10, 0/0", "🔥 1 -> 🔥 10, 1/0"])


## The details of the battle don't matter too much, but it used to cause a softlock.
func test_softlock() -> void:
	PlayerDataTestUtils.load_player_data("res://assets/test/softlock_save.json")
	player_army = PlayerData.army
	enemy_army = PlayerData.dungeons[1].army
	assert_eq(enemy_army.get_total_goblins().to_float(), 16_818_897.0)
	
	plan_and_resolve_attacks()
	assert_eq(enemy_army.get_total_goblins().to_float(), 11_639_432.0)


## It used to be possible to attack 101 goblins, kill 5 of them and wound 100 of them, leaving the Gob in an
## invalid state with -5 healthy goblins.
func test_too_many_wounded() -> void:
	player_army.add_gob(gob("🕊 8"))
	player_army.gobs[0].back_count = Big.new(500)
	enemy_army.add_gob(gob("😈 8"))
	enemy_army.gobs[0].back_count = Big.new(100)
	var target: Gob = enemy_army.gobs[0]
	
	var result: Dictionary[String, Variant] = resolve_attack(0, 0, false, false)
	assert_eq(target.back_count.to_int(), 95)
	assert_eq(target.back_wounded.to_int(), 95)
	assert_eq(result["kill_count"].to_int(), 5)
	assert_eq(result["hits_taken"].to_int(), 111)


func resolve_attack(source_index: int, target_index: int, wounded: bool, murder_mode: bool) \
		-> Dictionary[String, Variant]:
	var new_attack: BattleResolver.Attack = attack(player_army, source_index, wounded)
	return BattleResolver.resolve_attack(new_attack, enemy_army.gobs[target_index], new_attack.count, murder_mode)


func gob(s: String) -> Gob:
	return ArmyTestUtils.gob(s)


func attack(source: Army, source_index: int, wounded: bool) -> BattleResolver.Attack:
	var new_attack: BattleResolver.Attack = BattleResolver.Attack.new()
	new_attack.source = source.gobs[source_index]
	new_attack.count = new_attack.source.get_wounded_count() if wounded else new_attack.source.get_healthy_count()
	new_attack.wounded = wounded
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
		var kw_string: String = "%s/%s" % [kill.kill_count.to_aa(), kill.target.get_wounded_count().to_aa()]
		got_kill_strings.append("%s -> %s, %s" % [source_string, target_string, kw_string])
	assert_eq(got_kill_strings, expected_kill_strings)
