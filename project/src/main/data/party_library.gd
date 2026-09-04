extends Node

const PARTY_SCRIPTS: Array[Script] = [
	MurderBall,
]

var party_queue: Array[Script]

func _ready() -> void:
	party_queue = PARTY_SCRIPTS.duplicate()
	party_queue.shuffle()


func get_random_party() -> Party:
	@warning_ignore("integer_division")
	var result: Script = party_queue.pop_at(randi_range(0, party_queue.size() / 2))
	party_queue.push_back(result)
	return result.new()


func wound_goblin() -> Big:
	var wounded_count: Big = Big.ZERO
	var shuffled_gobs: Array[Gob] = PlayerData.army.gobs.duplicate()
	shuffled_gobs.shuffle()
	for gob: Gob in shuffled_gobs:
		wounded_count = gob.wound_back(Big.ONE)
		if wounded_count.is_gt(Big.ZERO):
			break
	return wounded_count


func kill_goblin() -> Big:
	var killed_count: Big = Big.ZERO
	var shuffled_gobs: Array[Gob] = PlayerData.army.gobs.duplicate()
	shuffled_gobs.shuffle()
	for gob: Gob in shuffled_gobs:
		killed_count = gob.kill_back_wounded(Big.ONE)
		if killed_count.is_eq(Big.ZERO):
			killed_count = gob.kill_back_healthy(Big.ONE)
		if killed_count.is_gt(Big.ZERO):
			break
	return killed_count


func wound_goblins(pct: float) -> Big:
	var wounded_count: Big = Big.ZERO
	var shuffled_gobs: Array[Gob] = PlayerData.army.gobs.duplicate()
	shuffled_gobs.shuffle()
	var target_gob_count: int = floori(shuffled_gobs.size() * pow(pct, 0.5))
	for i in target_gob_count:
		var gob: Gob = shuffled_gobs[i]
		wounded_count = Big.add(wounded_count, \
				gob.wound_back(Big.new(gob.get_count().to_float() * pow(pct, 0.5))))
	return wounded_count


func kill_goblins(pct: float) -> Big:
	var killed_count: Big = Big.ZERO
	var shuffled_gobs: Array[Gob] = PlayerData.army.gobs.duplicate()
	shuffled_gobs.shuffle()
	var target_gob_count: int = floori(shuffled_gobs.size() * pow(pct, 0.5))
	for i in target_gob_count:
		var gob: Gob = shuffled_gobs[i]
		killed_count = Big.add(killed_count, \
				gob.kill_back_healthy(Big.new(gob.get_count().to_float() * pow(pct, 0.5))))
	return killed_count


## Weights the specified headlines so goblins who like the event get more positive outcomes.
func apply_preferences_to_group(group_string: String, likers: Array[Gobs.Type], dislikers: Array[Gobs.Type]) -> void:
	var good_condition: MoraleDigest.TypeWeightCondition = MoraleDigest.TypeWeightCondition.new()
	var bad_condition: MoraleDigest.TypeWeightCondition = MoraleDigest.TypeWeightCondition.new()
	for liker: Gobs.Type in likers:
		good_condition.weights[liker] = 1.5
		bad_condition.weights[liker] = 0.5
	for disliker: Gobs.Type in dislikers:
		good_condition.weights[disliker] = 0.5
		bad_condition.weights[disliker] = 1.5
	
	for headline: MoraleDigest.Headline in PlayerData.morale_digest.get_headlines_in_group(group_string):
		headline.conditions.append(good_condition if headline.delta > 0.0 else bad_condition)


func apply_group_headlines_to_army(group_string: String, nerf_factor: float) -> void:
	var headlines: Array[MoraleDigest.Headline] = PlayerData.morale_digest.get_headlines_in_group(group_string)
	for headline: MoraleDigest.Headline in headlines:
		headline.delta *= nerf_factor
		headline.pct *= nerf_factor
	for gob: Gob in PlayerData.army.gobs:
		var eligible: Array[MoraleDigest.Headline] = headlines.filter(func(headline: MoraleDigest.Headline) -> bool:
			return randf() < headline.evaluate(gob))
		if eligible:
			var headline: MoraleDigest.Headline = eligible.pick_random()
			gob.morale.add_event(headline.create_event())


class MurderBall extends Party:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	
	var brutality: float = 0.5
	var wounded_count: Big = Big.ZERO
	var killed_count: Big = Big.ZERO
	
	func _init() -> void:
		super._init("MurderBall")
		brutality = randf()
		
		if brutality < 0.33:
			prompt = "\"Hey let's all play touch rules Murderball! " \
					+ "No actual murder, just touch the guy you woulda murdered.\""
		elif brutality < 0.66:
			prompt = "\"Let's play Murderball, modern rules obviously! " \
					+ "No murdering below the belt, limit five murders per team.\""
		else:
			prompt = "\"How 'bout some classic rules Murderball! " \
					+ "No murder limit, but if you murder the ref then you're the new ref.\""
		
		likers = [Gobs.FIRE, Gobs.DEVIL]
		dislikers = [Gobs.WATER, Gobs.GRASS]
	
	
	func execute() -> String:
		# calculate wounded/killed goblins
		wounded_count = PartyLibrary.wound_goblins(pow(brutality, 2) * randf_range(0.0, 0.02))
		killed_count = PartyLibrary.kill_goblins(pow(brutality, 2) * randf_range(0.0, 0.02))
		
		# If nobody is wounded/killed -- maybe just wound/kill one goblin anyway. Were they the ball?
		if wounded_count.is_eq(0) and killed_count.is_eq(0) \
				and PlayerData.army.gobs.size() >= 2 and randf() < brutality:
			if randf() < brutality:
				killed_count = PartyLibrary.kill_goblin()
			else:
				wounded_count = PartyLibrary.wound_goblin()
		
		var group_string: String = "murderball-%s" % [PlayerData.day]
		
		# 50% of goblins react +25 (+12.5); 25% of goblins react -10 (-2.5). Average = +10.0
		PlayerData.morale_digest.add_headline(MoraleEvent.MoraleEventType.MURDERBALL_WON) \
				.delta(25.0).pct(0.30).group(group_string)
		PlayerData.morale_digest.add_headline(MoraleEvent.MoraleEventType.MURDERBALL_LOST) \
				.delta(15.0).pct(0.20).group(group_string)
		PlayerData.morale_digest.add_headline(MoraleEvent.MoraleEventType.MURDERBALL_PLAY) \
				.delta(20.0).pct(0.40).group(group_string)
		PlayerData.morale_digest.add_headline(MoraleEvent.MoraleEventType.MURDERBALL_WON) \
				.delta(-5.0).pct(0.05).group(group_string)
		PlayerData.morale_digest.add_headline(MoraleEvent.MoraleEventType.MURDERBALL_LOST) \
				.delta(-10.0).pct(0.15).group(group_string)
		PlayerData.morale_digest.add_headline(MoraleEvent.MoraleEventType.MURDERBALL_PLAY) \
				.delta(-5.0).pct(0.10).group(group_string)
		PartyLibrary.apply_preferences_to_group( \
				group_string, [Gobs.Type.FIRE, Gobs.Type.DEVIL], [Gobs.Type.WATER, Gobs.Type.GRASS])
		
		PartyLibrary.apply_group_headlines_to_army(group_string, nerf_factor)
		
		var result: String = "The goblins split into teams, kicking around an improvised ball, " \
				+ "cackling at the pathetic noises the 'ball' makes."
		if not PlayerData.army.gobs.is_empty():
			if killed_count.is_gt(0) and wounded_count.is_gt(0):
				result += " %s goblins are killed during the game, %s are wounded." % \
						[killed_count.to_aa(), wounded_count.to_aa()]
			elif killed_count.is_gt(0):
				result += " %s goblins are killed during the game." % [killed_count.to_aa()]
			elif wounded_count.is_gt(0):
				result += " %s goblins are wounded during the game." % [wounded_count.to_aa()]
		result = result.replace(". 1 goblins are", ". One goblin is")
		result = result.replace(", 1 are", ", one is")
		return result
