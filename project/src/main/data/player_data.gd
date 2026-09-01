extends Node
## Stores the player's army.

const HOME_BASE_TUTORIAL: String = "home_base_tutorial"
const BATTLE_TUTORIAL: String = "battle_tutorial"

var day: int = 1
var army: Army = Army.new()
var gold: Big = Big.ZERO
var inventory: Inventory = Inventory.new()
var dungeons: Array[Dungeon] = []
var dungeon_index: int
var market: Market = Market.new()

var home_base_multiplier: Big = Big.ONE
var heal_multiplier: Big = Big.ONE
var kitchen_multiplier: Big = Big.ONE

var finished_tutorials: Dictionary[String, bool] = {}

var _next_gob_id: int = 0
var _prev_total_gold: Big = Big.ZERO

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
	"Recruit your goblins carefully! Some goblins ask for too much gold.",
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
	heal_multiplier = Big.ONE
	kitchen_multiplier = Big.ONE
	finished_tutorials.clear()
	_next_gob_id = 0


func start_new_game() -> void:
	reset()
	initialize_starting_army()
	initialize_starting_inventory()
	cycle_dungeons()


func has_current_dungeon() -> bool:
	return dungeon_index < dungeons.size()


func get_dungeon() -> Dungeon:
	return dungeons[dungeon_index]


func get_dungeon_army() -> Army:
	return get_dungeon().army


func initialize_starting_inventory() -> void:
	PlayerData.inventory.add_item(Items.HERB_1, Big.new(5))
	PlayerData.inventory.add_item(Items.HERB_2, Big.new(8))
	PlayerData.inventory.add_item(Items.HERB_3, Big.new(9))
	PlayerData.inventory.add_item(Items.WEAK_MEDICINE, Big.new(4))
	PlayerData.inventory.add_item(Items.STRONG_MEDICINE, Big.new(3))

func create_gob() -> Gob:
	var gob: Gob = Gob.new()
	gob.id = _next_gob_id
	_next_gob_id += 1
	return gob


func initialize_starting_army() -> void:
	var goblin_count: Big = PlayerData.army.get_summary().total_goblins
	while goblin_count.is_lt(3):
		var gob: Gob = army.generate_random_recruit({
			"type": [Gobs.FIRE, Gobs.WATER, Gobs.GRASS].pick_random(),
			"level": (4 if goblin_count.is_eq(0) else 3),
		})
		army.add_gob(gob)
		goblin_count = Big.add(goblin_count, 1)
	
	gold = Big.max(gold, 30)


func add_dungeon(target_attack: Big) -> void:
	dungeons.append(DungeonGenerator.generate_random_dungeon(target_attack))


func scale_army_units(factor: float) -> void:
	for gob: Gob in PlayerData.army.gobs:
		gob.back_count = Big.new((gob.back_count.to_float() + 1) * factor - 1)
	for dungeon: Dungeon in PlayerData.dungeons:
		for gob: Gob in dungeon.army.gobs:
			gob.back_count = Big.new((gob.back_count.to_float() + 1) * factor - 1)
	gold = Big.new(gold.to_float() * factor)


func take_gold(count: Big) -> void:
	gold = Big.new(max(0, gold.to_float() - count.to_float()))


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
	result["heal_multiplier"] = heal_multiplier.to_float()
	result["kitchen_multiplier"] = kitchen_multiplier.to_float()
	result["finished_tutorials"] = finished_tutorials
	result["next_gob_id"] = _next_gob_id
	return result


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	reset()
	day = json.get("day", 1)
	if json.has("army"):
		army.from_glob(json["army"])
	gold = Big.new(json.get("gold", 0.0))
	if json.has("inventory"):
		var typed_inventory_json: Dictionary[String, Variant] = {}
		typed_inventory_json.assign(json["inventory"])
		inventory.from_json_dict(typed_inventory_json)
	for dungeon_json: Dictionary in json.get("dungeons", []):
		var dungeon: Dungeon = Dungeon.new()
		var typed_dungeon_json: Dictionary[String, Variant] = {}
		typed_dungeon_json.assign(dungeon_json)
		dungeon.from_json_dict(typed_dungeon_json)
		dungeons.append(dungeon)
	home_base_multiplier = Big.new(json.get("home_base_multiplier", 1.0))
	heal_multiplier = Big.new(json.get("heal_multiplier", 1.0))
	kitchen_multiplier = Big.new(json.get("kitchen_multiplier", 1.0))
	finished_tutorials.assign(json.get("finished_tutorials", {}))
	_next_gob_id = json.get("next_gob_id", 0)


func print_gold_history() -> void:
	var total_gold: Big = Big.add(gold, army.get_total_gold())
	if _prev_total_gold.is_eq(0):
		print("Gold: %s" % [total_gold])
	else:
		print("Gold: %s -> %s (%.2f)" % [_prev_total_gold, total_gold,
				total_gold.to_float() / _prev_total_gold.to_float()])
	_prev_total_gold = total_gold
