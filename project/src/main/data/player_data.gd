extends Node
## Stores the player's army.

const RIPOFF_CURVE: Array[Array] = [
	[0.0,   1.00],
	[50.0,  0.80],
	[500.0, 0.60],
	[5e3,   0.50],
	[5e4,   0.40],
	[5e5,   0.30],
	[5e6,   0.20],
	[5e9,   0.10],
	[5e12,  0.05],
	[5e15,  0.03],
	[5e18,  0.02],
	[5e21,  0.01],
]


var day: int = 1
var army: Army = Army.new()
var gold: Big = Big.ZERO:
	set(value):
		gold = value
		mark_ripoff_factor_dirty()
var inventory: Inventory = Inventory.new()
var dungeons: Array[Dungeon] = []
var dungeon_index: int

var home_base_multiplier: Big = Big.ONE
var ripoff_factor: float:
	get():
		return get_ripoff_factor()

var _ripoff_factor_cache: float = 0.0
var _ripoff_factor_dirty: bool = true

var tips: Array[String] = [
	"🌳 goblins are strong against 💧, but struggle with 🔥.",
	"💧 goblins are strong against 🔥, but struggle with 🌳.",
	"🔥 goblins are strong against 🌳, but struggle with 💧.",
	"😈 goblins are strong against everything, except for 🕊.",
	"🕊 goblins are strong against 😈, but struggle against everything else.",
	"If you have lots of 🌳 goblins, avoid dungeons with too much 🔥 or 😈.",
	"If you have lots of 💧 goblins, try dungeons with lots of 🔥 or 🕊.",
	"For dungeons with lots of 🔥 goblins, focus on recruiting 💧 and 😈.",
	"For dungeons with lots of 😈 goblins, focus on recruiting 🕊.",
	"If you have lots of 🕊 goblins, avoid dungeons with too much 🌳, 💧 or 🔥.",
	
	"Goblins you don't send to fight can't be killed! Bench your weaker units.",
	"Send your vulnerable goblins in early, before the enemy kills them!",
	"Send your strongest forces in early, to deal the enemy a brutal blow!",
	"Retreat is better than defeat! You still earn 💰 from the units you killed.",
	"Dungeon information is based on goblins spotted nearby, but it's not perfect.",
	"Sometimes, enemy dungeons have strong goblins you weren't told about.",
	"If an enemy dungeon has a surprise you're not prepared for, it's OK to leave!",
	"A type hint like \"🌳🌳🔥\" means there are a lot of 🌳, and a few 🔥.",
	"A type hint like \"🔥💧🌳\" means there are several 🔥, some 💧, and a few 🌳.",
	"Recruit your goblins carefully! Some goblins ask for too much money.",
	"Recruit your goblins carefully! Some types are more useful than others.",
]

var _tip_index: int = 0

func _ready() -> void:
	tips.shuffle()


func cycle_dungeons() -> void:
	for dungeon: Dungeon in PlayerData.dungeons.duplicate():
		if dungeon.is_empty():
			PlayerData.dungeons.erase(dungeon)
			@warning_ignore("narrowing_conversion")
			PlayerData.add_dungeon(Big.new(PlayerData.army.get_total_attack().to_float() * randf_range(0.4, 1.4)))
	
	if not PlayerData.dungeons.is_empty():
		PlayerData.dungeons.remove_at(0)
	
	while PlayerData.dungeons.size() < 5:
		@warning_ignore("narrowing_conversion")
		PlayerData.add_dungeon(Big.new(PlayerData.army.get_total_attack().to_float() * randf_range(0.4, 1.4)))


func get_next_tip() -> String:
	var result: String = tips[_tip_index]
	_tip_index = (_tip_index + 1) % tips.size()
	return result


func reset() -> void:
	day = 1
	army.reset()
	gold = Big.ZERO
	dungeons = []
	dungeon_index = 0
	home_base_multiplier = Big.ONE
	_ripoff_factor_dirty = true


func start_new_game() -> void:
	reset()
	initialize_starting_army()
	cycle_dungeons()


func has_current_dungeon() -> bool:
	return dungeon_index < dungeons.size()


func get_dungeon() -> Dungeon:
	return dungeons[dungeon_index]


func get_dungeon_army() -> Army:
	return get_dungeon().army


func initialize_starting_army() -> void:
	var goblin_count: Big = PlayerData.army.get_summary().total_goblins
	while goblin_count.is_lt(3):
		var gob: Gob = Gob.new()
		
		gob.name = GoblinNames.random_name()
		gob.type = [Gobs.FIRE, Gobs.WATER, Gobs.GRASS].pick_random()
		gob.hp_max = randi_range(2, 4)
		gob.front_hp = gob.hp_max
		
		for _i in range(2):
			if randf() < 0.5:
				gob.level_up()
		
		army.add_gob(gob)
		goblin_count = Big.add(goblin_count, 1)
	
	gold = Big.max(gold, 25)


func add_dungeon(target_attack: Big) -> void:
	dungeons.append(DungeonGenerator.generate_random_dungeon(target_attack))


func scale_army_units(factor: float) -> void:
	for gob: Gob in PlayerData.army.gobs:
		gob.back_count = Big.new((gob.back_count.to_float() + 1) * factor - 1)
	for dungeon: Dungeon in PlayerData.dungeons:
		for gob: Gob in dungeon.army.gobs:
			gob.back_count = Big.new((gob.back_count.to_float() + 1) * factor - 1)
	gold = Big.new(gold.to_float() * factor)


func mark_ripoff_factor_dirty() -> void:
	_ripoff_factor_dirty = true


func get_ripoff_factor() -> float:
	if _ripoff_factor_dirty:
		_ripoff_factor_dirty = false
		_ripoff_factor_cache = _calculate_ripoff_factor()
	return _ripoff_factor_cache





func to_json_dict() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {}
	result["day"] = day
	result["army"] = army.to_glob()
	result["gold"] = gold.to_float()
	result["inventory"] = inventory.to_json_dict()
	var dungeons_json: Array[Dictionary] = []
	for dungeon: Dungeon in dungeons:
		dungeons_json.append(dungeon.to_json_dict())
	result["dungeons"] = dungeons_json
	result["home_base_multiplier"] = home_base_multiplier.to_float()
	return result


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	reset()
	day = json.get("day", 1)
	if json.has("army"):
		army.from_glob(json["army"])
	gold = Big.new(json.get("gold", 0.0))
	if json.has("inventory"):
		inventory.from_json_dict(json["inventory"])
	for dungeon_json: Dictionary in json.get("dungeons", []):
		var dungeon: Dungeon = Dungeon.new()
		var typed_dungeon_json: Dictionary[String, Variant] = {}
		typed_dungeon_json.assign(dungeon_json)
		dungeon.from_json_dict(typed_dungeon_json)
		dungeons.append(dungeon)
	home_base_multiplier = Big.new(json.get("home_base_multiplier", 1.0))




func _calculate_ripoff_factor() -> float:
	var result: float = RIPOFF_CURVE.back()[1]
	var total_gold: Big = Big.add(gold, army.get_total_gold())
	for i in range(RIPOFF_CURVE.size() - 1):
		var lo_gold: float = RIPOFF_CURVE[i][0]
		var hi_gold: float = RIPOFF_CURVE[i + 1][0]
		if total_gold.is_lte(hi_gold):
			var lo_val: float = RIPOFF_CURVE[i][1]
			var hi_val: float = RIPOFF_CURVE[i + 1][1]
			result = remap(total_gold.to_float(), lo_gold, hi_gold, lo_val, hi_val)
			break
	return result
