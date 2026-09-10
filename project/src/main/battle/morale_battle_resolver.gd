class_name MoraleBattleResolver

const BATTLE_MORALE_PCT: float = 0.25

## How often battle morale events are inverted (e.g. a kill gives -morale instead of +morale)
const MORALE_FLIP_CHANCE_BY_TYPE: Dictionary[Gobs.Type, float] = {
	Gobs.FIRE: 0.04,
	Gobs.WATER: 0.16,
	Gobs.GRASS: 0.12,
	Gobs.ANGEL: 0.20,
	Gobs.DEVIL: 0.08,
}

static func update_gob_battle_morale(gob_battle_status: GobBattleStatus) -> void:
	var gobs: Array[Gob] = PlayerData.army.gobs.duplicate()
	gobs.shuffle()
	for i in gobs.size() * BATTLE_MORALE_PCT:
		var gob: Gob = gobs[i]
		gob.morale.add_event(_random_battle_event(gob_battle_status, gob))


static func _random_battle_event(gob_battle_status: GobBattleStatus, gob: Gob) -> MoraleEvent:
	var event: MoraleEvent
	
	# calculate which events the goblin is eligible for
	var eligible: Array[GobBattleStatus.GobAction] = []
	for action: GobBattleStatus.GobAction in GobBattleStatus.GobAction.values():
		if gob_battle_status.has_action(gob, action):
			eligible.append(action)
	
	if eligible.is_empty():
		# the goblin did nothing in battle; return an idle event
		event = MoraleEvent.new_randomized_event(MoraleEvent.BATTLE_IDLE, -5.0)
		
		# Angels like avoiding battle (negative effects are inverted)
		if (gob.type == Gobs.Type.ANGEL and event.delta < 0.0):
			event.delta *= -1
	else:
		# the goblin did something in battle; return a battle event
		var action: GobBattleStatus.GobAction = eligible.pick_random()
		match action:
			GobBattleStatus.HIT:
				event = MoraleEvent.new_randomized_event(MoraleEvent.BATTLE_HIT, 5.0)
				event.params = [MoraleEvent.BATTLE_HIT_DESCRIPTIONS.keys().pick_random()]
			GobBattleStatus.WOUNDED:
				event = MoraleEvent.new_randomized_event(MoraleEvent.BATTLE_WOUNDED, -10.0)
				event.params = [MoraleEvent.BATTLE_WOUNDED_DESCRIPTIONS.keys().pick_random()]
			GobBattleStatus.LEVELED_UP:
				event = MoraleEvent.new_randomized_event(MoraleEvent.BATTLE_LEVELED_UP, 10.0)
			GobBattleStatus.ENEMY_HIT:
				event = MoraleEvent.new_randomized_event(MoraleEvent.BATTLE_ENEMY_HIT, 5.0)
			GobBattleStatus.ENEMY_WOUNDED:
				event = MoraleEvent.new_randomized_event(MoraleEvent.BATTLE_ENEMY_WOUNDED, 10.0)
			GobBattleStatus.ENEMY_KILLED:
				event = MoraleEvent.new_randomized_event(MoraleEvent.BATTLE_ENEMY_KILLED, 15.0)
			_:
				push_warning("Unrecognized GobAction: %s" % [action])
				event = MoraleEvent.new_randomized_event(MoraleEvent.BATTLE_HIT, 5.0)
		
		# Angels dislike battle (positive effects are inverted)
		if (gob.type == Gobs.Type.ANGEL and event.delta > 0.0):
			event.delta *= -1
	
	# Sometimes a battle has a surprising effect, and a goblin hates killing a guy for some reason
	if randf() < MORALE_FLIP_CHANCE_BY_TYPE[gob.type]:
		event.delta *= -1
	
	if randf() < 0.2:
		event.delta *= 1.5
		if randf() < 0.2:
			event.delta *= 1.5
	
	return event
