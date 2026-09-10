class_name GobBattleStatus

enum GobAction {
	HIT = 1,
	WOUNDED = 2,
	LEVELED_UP = 4,
	ENEMY_HIT = 8,
	ENEMY_WOUNDED = 16,
	ENEMY_KILLED = 32,
}

const HIT: GobAction = GobAction.HIT
const WOUNDED: GobAction = GobAction.WOUNDED
const LEVELED_UP: GobAction = GobAction.LEVELED_UP
const ENEMY_HIT: GobAction = GobAction.ENEMY_HIT
const ENEMY_WOUNDED: GobAction = GobAction.ENEMY_WOUNDED
const ENEMY_KILLED: GobAction = GobAction.ENEMY_KILLED

var player_gob_actions: Dictionary[Gob, int] = {}

func has_action(gob: Gob, action: GobAction) -> bool:
	return player_gob_actions.get(gob, 0) & action > 0


func record_action(gob: Gob, action: GobBattleStatus.GobAction) -> void:
	if not player_gob_actions.has(gob):
		player_gob_actions[gob] = 0
	player_gob_actions[gob] |= action
