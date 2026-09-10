class_name MoraleRelationshipResolver

## How often death morale events are inverted (e.g. a friend dying gives +morale instead of -morale)
const DEATH_FLIP_CHANCE_BY_TYPE: Dictionary[Gobs.Type, float] = {
	Gobs.FIRE: 0.04,
	Gobs.WATER: 0.80, # water goblins are usually happy when their friends die, jealous when their rivals die
	Gobs.GRASS: 0.16,
	Gobs.ANGEL: 0.08,
	Gobs.DEVIL: 0.12,
}

## How often friend events are inverted (e.g. making a friend gives -morale instead of +morale)
const FRIEND_FLIP_CHANCE_BY_TYPE: Dictionary[Gobs.Type, float] = {
	Gobs.FIRE: 0.20,
	Gobs.WATER: 0.12,
	Gobs.GRASS: 0.04,
	Gobs.ANGEL: 0.08,
	Gobs.DEVIL: 0.16,
}

## How often rival events are inverted (e.g. making a rival gives +morale instead of -morale)
const RIVAL_FLIP_CHANCE_BY_TYPE: Dictionary[Gobs.Type, float] = {
	Gobs.FIRE: 0.08,
	Gobs.WATER: 0.20,
	Gobs.GRASS: 0.04,
	Gobs.ANGEL: 0.12,
	Gobs.DEVIL: 0.80, # fire goblins are competitive by nature and love competition
}

static func apply_death_morale(dead_gob_ids: Dictionary[int, bool]) -> void:
	for gob: Gob in PlayerData.army.gobs:
		for event: MoraleEvent in gob.morale.events.duplicate():
			if event.type in [MoraleEvent.MADE_FRIEND, MoraleEvent.MADE_RIVAL] \
					and int(event.params[0]["id"]) in dead_gob_ids:
				_add_end_event(gob, event)


static func create_random_relationships(friendship_chance: float = 0.1, rivalry_chance: float = 0.1) -> void:
	var half_gobs: Array[Gob] = PlayerData.army.gobs.duplicate()
	half_gobs.shuffle()
	@warning_ignore("integer_division")
	half_gobs = half_gobs.slice(0, PlayerData.army.gobs.size() / 2)
	
	# Existing relationships, stored bidirectionally to prevent duplicates
	var existing_relationships: Dictionary[String, bool] = {}
	for gob: Gob in half_gobs:
		for event: MoraleEvent in gob.morale.events.duplicate():
			if event.type in [MoraleEvent.MADE_FRIEND, MoraleEvent.MADE_RIVAL]:
				existing_relationships["%d %d" % [gob.id, int(event.params[0].id)]] = true
				existing_relationships["%d %d" % [int(event.params[0].id), gob.id]] = true
	
	for gob: Gob in half_gobs:
		if randf() < friendship_chance:
			_add_bidirectional_relationship(gob, MoraleEvent.MADE_FRIEND, existing_relationships)
		if randf() < rivalry_chance:
			_add_bidirectional_relationship(gob, MoraleEvent.MADE_RIVAL, existing_relationships)


static func _add_bidirectional_relationship( \
		gob: Gob, type: MoraleEvent.MoraleEventType, existing_relationships: Dictionary[String, bool]) -> void:
	var other_gob: Gob
	for i in 5:
		var target: Gob = PlayerData.army.gobs.pick_random()
		if target != gob and not existing_relationships.has("%d %d" % [gob.id, target.id]):
			other_gob = target
			break
	if other_gob != null:
		_add_relationship(gob, other_gob, type)
		_add_relationship(other_gob, gob, type)
		existing_relationships["%d %d" % [gob.id, other_gob.id]] = true
		existing_relationships["%d %d" % [other_gob.id, gob.id]] = true


static func _add_relationship(gob: Gob, other_gob: Gob, type: MoraleEvent.MoraleEventType) -> void:
	var delta: float
	var flip_chance: float
	if type == MoraleEvent.MADE_FRIEND:
		delta = 15
		flip_chance = FRIEND_FLIP_CHANCE_BY_TYPE[gob.type]
	else:
		delta = -15
		flip_chance = RIVAL_FLIP_CHANCE_BY_TYPE[gob.type]
	var gob_ref: MoraleEvent.GobRef = MoraleEvent.GobRef.new()
	gob_ref.id = other_gob.id
	gob_ref.name = other_gob.name
	
	var begin_event: MoraleEvent = MoraleEvent.new_randomized_event(type, delta)
	begin_event.set_gob_ref_param(0, gob_ref)
	begin_event.apply_morale_whim(flip_chance)
	gob.morale.add_event(begin_event)


static func _add_end_event(gob: Gob, begin_event: MoraleEvent) -> void:
	var end_event: MoraleEvent
	if begin_event.type == MoraleEvent.MADE_FRIEND:
		end_event = MoraleEvent.new_randomized_event(MoraleEvent.FRIEND_DIED, -40)
	else:
		end_event = MoraleEvent.new_randomized_event(MoraleEvent.RIVAL_DIED, 40)
	
	var gob_ref: MoraleEvent.GobRef = begin_event.get_gob_ref_param(0)
	end_event.set_gob_ref_param(0, gob_ref)
	end_event.apply_morale_whim(DEATH_FLIP_CHANCE_BY_TYPE[gob.type])
	gob.morale.add_event(end_event)
