class_name GobBattleStatus

enum GobAction {
	HIT = 1,
	WOUNDED = 2,
	KILLED = 4,
	LEVELED_UP = 8,
	ENEMY_HIT = 16,
	ENEMY_WOUNDED = 32,
	ENEMY_KILLED = 64,
}

const HIT: GobAction = GobAction.HIT
const WOUNDED: GobAction = GobAction.WOUNDED
const KILLED: GobAction = GobAction.KILLED
const LEVELED_UP: GobAction = GobAction.LEVELED_UP
const ENEMY_HIT: GobAction = GobAction.ENEMY_HIT
const ENEMY_WOUNDED: GobAction = GobAction.ENEMY_WOUNDED
const ENEMY_KILLED: GobAction = GobAction.ENEMY_KILLED

## key: (int) Gob id[br]
## value: (int) GobAction bitmask
var _player_gob_actions: Dictionary[int, int] = {}

var enemies_killed: Big = Big.ZERO

func get_gob_ids() -> Array[int]:
	return _player_gob_actions.keys()


func has_action(gob_id: int, action: GobAction) -> bool:
	return _player_gob_actions.get(gob_id, 0) & action > 0


func record_action(gob_id: int, action: GobBattleStatus.GobAction) -> void:
	if not _player_gob_actions.has(gob_id):
		_player_gob_actions[gob_id] = 0
	_player_gob_actions[gob_id] |= action
