extends Collectible

const NTH: Array[String] = [
	"zeroth",
	"first",
	"second",
	"third",
	"fourth",
	"fifth",
	"sixth",
	"seventh",
	"eighth",
	"ninth",
	"tenth",
]

@export var target_boss_count: int = 0

func refresh_collectible() -> void:
	if PlayerData.bosses_defeated >= target_boss_count:
		unlock_collectible()


func get_instructions() -> String:
	return "Defeat the %s boss." % [NTH[target_boss_count]]
