class_name MoraleEvent

enum MoraleEventType {
	NONE,
	DAY_OFF,
	MADE_FRIEND,
	MADE_RIVAL,
	FRIEND_DIED,
	RIVAL_DIED,
	HEAL_VISIT,
	
	# party events
	MURDERBALL_WON,
	MURDERBALL_LOST,
	MURDERBALL_PLAY,
	GAMBLING_WON,
	GAMBLING_WON_BIG,
	GAMBLING_LOST,
	GAMBLING_LOST_BIG,
	GAMBLING_PLAY,
	DRINKING_FOOLISH,
	DRINKING_PARTY,
	DRINKING_FIGHT,
	HAZING_VICTIM,
	HAZING_ATTACKER,
	HAZING_WITNESS,
	PRANKS_VICTIM,
	PRANKS_ATTACKER,
	PRANKS_WITNESS,
	BRAWL_WON,
	BRAWL_LOST,
	BRAWL_WITNESS,
	FESTIVAL_DANCE,
	FESTIVAL_LOVE,
	FESTIVAL_RELAX,
	
	# battle events
	BATTLE_IDLE,
	BATTLE_ENEMY_KILLED,
	BATTLE_ENEMY_WOUNDED,
	BATTLE_ENEMY_HIT,
	BATTLE_WOUNDED,
	BATTLE_HIT,
	BATTLE_LEVELED_UP,
}

const NONE: MoraleEventType = MoraleEventType.NONE
const DAY_OFF: MoraleEventType = MoraleEventType.DAY_OFF
const MADE_FRIEND: MoraleEventType = MoraleEventType.MADE_FRIEND
const MADE_RIVAL: MoraleEventType = MoraleEventType.MADE_RIVAL
const FRIEND_DIED: MoraleEventType = MoraleEventType.FRIEND_DIED
const RIVAL_DIED: MoraleEventType = MoraleEventType.RIVAL_DIED
const HEAL_VISIT: MoraleEventType = MoraleEventType.HEAL_VISIT

## party events
const MURDERBALL_WON: MoraleEventType = MoraleEventType.MURDERBALL_WON
const MURDERBALL_LOST: MoraleEventType = MoraleEventType.MURDERBALL_LOST
const MURDERBALL_PLAY: MoraleEventType = MoraleEventType.MURDERBALL_PLAY
const GAMBLING_WON: MoraleEventType = MoraleEventType.GAMBLING_WON
const GAMBLING_WON_BIG: MoraleEventType = MoraleEventType.GAMBLING_WON_BIG
const GAMBLING_LOST: MoraleEventType = MoraleEventType.GAMBLING_LOST
const GAMBLING_LOST_BIG: MoraleEventType = MoraleEventType.GAMBLING_LOST_BIG
const GAMBLING_PLAY: MoraleEventType = MoraleEventType.GAMBLING_PLAY
const DRINKING_FOOLISH: MoraleEventType = MoraleEventType.DRINKING_FOOLISH
const DRINKING_PARTY: MoraleEventType = MoraleEventType.DRINKING_PARTY
const DRINKING_FIGHT: MoraleEventType = MoraleEventType.DRINKING_FIGHT
const HAZING_VICTIM: MoraleEventType = MoraleEventType.HAZING_VICTIM
const HAZING_ATTACKER: MoraleEventType = MoraleEventType.HAZING_ATTACKER
const HAZING_WITNESS: MoraleEventType = MoraleEventType.HAZING_WITNESS
const PRANKS_VICTIM: MoraleEventType = MoraleEventType.PRANKS_VICTIM
const PRANKS_ATTACKER: MoraleEventType = MoraleEventType.PRANKS_ATTACKER
const PRANKS_WITNESS: MoraleEventType = MoraleEventType.PRANKS_WITNESS
const BRAWL_WON: MoraleEventType = MoraleEventType.BRAWL_WON
const BRAWL_LOST: MoraleEventType = MoraleEventType.BRAWL_LOST
const BRAWL_WITNESS: MoraleEventType = MoraleEventType.BRAWL_WITNESS
const FESTIVAL_DANCE: MoraleEventType = MoraleEventType.FESTIVAL_DANCE
const FESTIVAL_LOVE: MoraleEventType = MoraleEventType.FESTIVAL_LOVE
const FESTIVAL_RELAX: MoraleEventType = MoraleEventType.FESTIVAL_RELAX

## battle events
const BATTLE_IDLE: MoraleEventType = MoraleEventType.BATTLE_IDLE
const BATTLE_ENEMY_KILLED: MoraleEventType = MoraleEventType.BATTLE_ENEMY_KILLED
const BATTLE_ENEMY_WOUNDED: MoraleEventType = MoraleEventType.BATTLE_ENEMY_WOUNDED
const BATTLE_ENEMY_HIT: MoraleEventType = MoraleEventType.BATTLE_ENEMY_HIT
const BATTLE_WOUNDED: MoraleEventType = MoraleEventType.BATTLE_WOUNDED
const BATTLE_HIT: MoraleEventType = MoraleEventType.BATTLE_HIT
const BATTLE_LEVELED_UP: MoraleEventType = MoraleEventType.BATTLE_LEVELED_UP

const BATTLE_HIT_DESCRIPTIONS: Dictionary[int, String] = {
	0: "Conked in the head",
	1: "Bloody nose",
	2: "Kicked in the face",
	3: "Black eye",
	4: "Fingers smashed",
	5: "Concussion",
	6: "Knifed in the gut",
	7: "Stabbed in the chest",
	8: "Bitten",
	9: "Broken ribs",
	10: "Poked with sharp stick",
}

const BATTLE_WOUNDED_DESCRIPTIONS: Dictionary[int, String] = {
	0: "Split down the middle",
	1: "Arms torn clean off",
	2: "Face split open",
	3: "Set on fire",
	4: "Brain chopped off",
	5: "Guts torn out",
	6: "Partially eaten",
	7: "Skin partially dissolved",
	8: "Legs bent wrong",
	9: "Smushed into paste",
	10: "Blown to pencils",
	11: "Skewered repeatedly",
}

var type: MoraleEventType = MoraleEventType.NONE
var delta: float = 0.0
var params: Array[Variant] = []
var day: int = 1

func get_desc(_gob: Gob) -> String:
	var result: String
	match type:
		NONE:
			pass
		DAY_OFF:
			if delta > 0.0:
				result = "Relaxing day off"
			else:
				result = "Boring day off"
		MADE_FRIEND:
			var gob_ref: GobRef = get_gob_ref_param(0)
			if delta > 0.0:
				result = "Made friends with %s" % [gob_ref.name]
			else:
				result = "Annoying new friend, %s" % [gob_ref.name]
		MADE_RIVAL:
			var gob_ref: GobRef = get_gob_ref_param(0)
			if delta > 0.0:
				result = "New rivalry with %s" % [gob_ref.name]
			else:
				result = "Annoying new enemy, %s" % [gob_ref.name]
		FRIEND_DIED:
			var gob_ref: GobRef = get_gob_ref_param(0)
			if delta > 0:
				result = "Friend %s had a glorious death" % [gob_ref.name]
			else:
				result = "Friend %s died" % [gob_ref.name]
		RIVAL_DIED:
			var gob_ref: GobRef = get_gob_ref_param(0)
			if delta > 0:
				result = "Rival %s died" % [gob_ref.name]
			else:
				result = "Rival %s had a glorious death" % [gob_ref.name]
		HEAL_VISIT:
			if delta > 0.0:
				result = "Visited in the infirmary"
			else:
				result = "Embarrassing infirmary visit"
		
		# party events
		MURDERBALL_WON:
			if delta > 0.0:
				result = "Won a game of murderball"
			else:
				result = "Boring game of murderball"
		MURDERBALL_LOST:
			if delta > 0.0:
				result = "Close game of murderball"
			else:
				result = "Lost a game of murderball"
		MURDERBALL_PLAY:
			if delta > 0.0:
				result = "Played murderball"
			else:
				result = "Suffered through murderball"
		GAMBLING_WON:
			if delta > 0.0:
				result = "Won gold gambling"
			else:
				result = "Boring night gambling"
		GAMBLING_WON_BIG:
			if delta > 0.0:
				result = "Rolled a grand swindle!"
			else:
				result = "Wasted time gambling"
		GAMBLING_LOST:
			if delta > 0.0:
				result = "Lost a risky swindle"
			else:
				result = "Lost gold gambling"
		GAMBLING_LOST_BIG:
			if delta > 0.0:
				result = "Almost rolled a grand swindle"
			else:
				result = "Went broke gambling"
		GAMBLING_PLAY:
			result = "Swindler's dice"
		DRINKING_FOOLISH:
			if delta > 15.0:
				result = "Ran naked in the public square"
			elif delta > 0.0:
				result = "Made a fool of themselves"
			else:
				result = "So embarrassed..."
		DRINKING_PARTY:
			if delta > 0.0:
				result = "A party they'll never forget"
			else:
				result = "Blackout drunk"
		DRINKING_FIGHT:
			result = "Drunken fight"
		HAZING_VICTIM:
			result = "Beaten up and humiliated"
		HAZING_ATTACKER:
			if delta > 0.0:
				result = "Roughed up the new guy"
			else:
				result = "Went too hard on the new guy"
		HAZING_WITNESS:
			result = "Watched the new guy get beat up"
		PRANKS_VICTIM:
			result = "Got pranked"
		PRANKS_ATTACKER:
			if delta > 0.0:
				result = "Played a prank"
			else:
				result = "Prank backfired"
		PRANKS_WITNESS:
			if delta > 0.0:
				result = "Saw a funny prank"
			else:
				result = "Bored by pranks"
		BRAWL_WON:
			if delta > 0.0:
				result = "Won a brawl"
			else:
				result = "Hurt someone in a brawl"
		BRAWL_LOST:
			if delta > 0.0:
				result = "Had fun in a brawl"
			else:
				result = "Got hurt in a brawl"
		BRAWL_WITNESS:
			if delta > 0.0:
				result = "Watched an amazing brawl"
			else:
				result = "Avoided a brawl"
		FESTIVAL_DANCE:
			if delta > 0.0:
				result = "Showed off their dancing"
			else:
				result = "Danced poorly"
		FESTIVAL_LOVE:
			if delta > 40.0:
				result = "Confessed their love"
			elif delta > 20.0:
				result = "Smooched a goblin"
			elif delta > 0.0:
				result = "Felt their heart race"
			else:
				result = "Had their heart broken"
		FESTIVAL_RELAX:
			if delta > 0.0:
				result = "Enjoyed a festival"
			else:
				result = "Bored by the festival"
		
		# battle events
		BATTLE_IDLE:
			if delta > 0.0:
				result = "Abstained from battle"
			else:
				result = "Didn't get to fight"
		BATTLE_ENEMY_KILLED:
			if delta > 0.0:
				result = "Killed some bad guys"
			else:
				result = "Murdered a bad guy"
		BATTLE_ENEMY_WOUNDED:
			if delta > 0.0:
				result = "Clobbered some bad guys"
			else:
				result = "Disfigured a bad guy"
		BATTLE_ENEMY_HIT:
			result = "Fought some bad guys"
		BATTLE_WOUNDED:
			var param: int = params[0] if (params and params[0] in BATTLE_WOUNDED_DESCRIPTIONS) else 0
			result = BATTLE_WOUNDED_DESCRIPTIONS[param]
		BATTLE_HIT:
			var param: int = params[0] if (params and params[0] in BATTLE_HIT_DESCRIPTIONS) else 0
			result = BATTLE_HIT_DESCRIPTIONS[param]
		BATTLE_LEVELED_UP:
			if delta > 0.0:
				result = "Leveled up"
			else:
				result = "Anxious about leveling up"
	return result

func get_gob_ref_param(i: int) -> GobRef:
	var gob_ref: GobRef = GobRef.new()
	gob_ref.from_json_dict(Utils.typed_json_dict(params[i]))
	return gob_ref


func set_gob_ref_param(i: int, gob_ref: GobRef) -> void:
	if params.size() <= i:
		params.resize(i + 1)
	params[i] = gob_ref.to_json_dict()


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	type = MoraleEventType.get(json.get("type", "none").to_upper())
	delta = json.get("delta", 0.0)
	params = json.get("params", [])
	day = json.get("day", 1)


func to_json_dict() -> Dictionary[String, Variant]:
	return {
		"type": Utils.enum_to_snake_case(MoraleEventType, type),
		"delta": delta,
		"params": params,
		"day": day
	}


func _to_string() -> String:
	return JSON.stringify(to_json_dict())


func apply_morale_whim(flip_chance: float = 0.2) -> void:
	if randf() < flip_chance:
		delta *= -1
	if randf() < 0.2:
		delta *= 1.5
		if randf() < 0.2:
			delta *= 1.5


static func new_randomized_event(init_type: MoraleEvent.MoraleEventType, init_delta: float) -> MoraleEvent:
	var event: MoraleEvent = MoraleEvent.new()
	event.type = init_type
	event.delta = sign(init_delta) * clampf(abs(init_delta) * randf_range(0.6, 1.4), 1.0, 100.0)
	event.day = PlayerData.day
	return event


class GobRef:
	var id: int = -1
	var name: String
	
	func from_json_dict(json: Dictionary[String, Variant]) -> void:
		id = json.get("id", -1)
		name = json.get("name", "")
	
	
	func to_json_dict() -> Dictionary[String, Variant]:
		return {"id": id, "name": name}
