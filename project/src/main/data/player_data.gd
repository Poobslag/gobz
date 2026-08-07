extends Node
## Stores the player's army.

var army: Army = Army.new()
var gold: int = 0
var dungeons: Array[Dungeon] = []
var dungeon_index: int
var home_base_multiplier: int = 1

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
	"Dungeon information is based on the goblins spotted nearby, but it's not perfect.",
	"Sometimes, enemy dungeons are a little stronger or weaker than you were told.",
	"Sometimes, enemy dungeons have extra types you weren't told about.",
	"A type hint like \"🌳🌳🔥\" means there are a lot of 🌳, and a few 🔥.",
	"A type hint like \"🔥💧🌳\" means there are several 🔥, some 💧, and a few 🌳.",
	"Recruit your goblins carefully! Some goblins ask for too much money.",
	"Recruit your goblins carefully! Some types are more useful than others.",
]

var _tip_index: int = 0

func _ready() -> void:
	tips.shuffle()


func get_next_tip() -> String:
	var result: String = tips[_tip_index]
	_tip_index = (_tip_index + 1) % tips.size()
	return result


func reset() -> void:
	army.reset()


func has_current_dungeon() -> bool:
	return dungeon_index < dungeons.size()


func get_dungeon() -> Dungeon:
	return dungeons[dungeon_index]


func get_dungeon_army() -> Army:
	return get_dungeon().army


func initialize_starting_army() -> void:
	var goblin_count: int = PlayerData.army.get_summary().total_goblins
	while goblin_count < 3:
		var item: Army.ArmyItem = Army.ArmyItem.new()
		
		item.name = GoblinNames.random_name()
		item.type = [Goblins.FIRE, Goblins.WATER, Goblins.GRASS].pick_random()
		item.hp_max = randi_range(2, 4)
		item.hp = item.hp_max
		
		for _i in range(2):
			if randf() < 0.5:
				item.level_up()
		
		army.add_item(item)
		goblin_count += 1
	
	gold = maxi(gold, 25)


func add_dungeon(target_attack: int) -> void:
	dungeons.append(DungeonGenerator.generate_random_dungeon(target_attack))


func scale_army_units(factor: float) -> void:
	for item: Army.ArmyItem in PlayerData.army.items:
		item.count = min(item.count * float(factor), 999_999_999_999_999_999)
		item.experience = min(item.experience * float(factor), 999_999_999_999_999_999)
	for dungeon: Dungeon in PlayerData.dungeons:
		for item: Army.ArmyItem in dungeon.army.items:
			item.count = min(item.count * float(factor), 999_999_999_999_999_999)
			item.experience = min(item.experience * float(factor), 999_999_999_999_999_999)
	gold = min(gold * float(factor), 999_999_999_999_999_999)
