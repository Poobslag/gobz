extends Node
## Stores data on different kinds of parties, their effects, and who likes them.[br]
## [br]
## Different goblins like different parties:[/br]
## 	Fire goblins love murderball, festivals and gambling (they want to socialize and form romantic bonds)[br]
## 	Fire goblins hate brawls, drinking (drunken love confessions don't count)[br]
## 	Water goblins love hazing, pranks, brawls (sociopaths, love the power dynamic and beating guys up)[br]
## 	Water goblins hate sport, festivals (ugh, fair play and friendship! so lame)[br]
## 	Grass goblins love gambling, drinking and hazing (they are spring break frat bros)[br]
## 	Grass goblins hate brawls, murderball (that just seems like work, bro)[br]
## 	Angel goblins love festivals, drinking, pranks (they just want to be merry and have fun)[br]
## 	Angel goblins hate brawls, hazing (it's too cruel)[br]
## 	Devil goblins love murderball, brawls, drinking (they want to grow strong, drinking also shows strength)[br]
## 	Devil goblins hate gambling, pranks (not honorable)[br]

const PARTY_SCRIPTS: Array[Script] = [
	MurderBall,
	Gambling,
	Drinking,
	Hazing,
	Pranks,
	Brawl,
	Festival,
]

var party_queue: Array[Script]

func _ready() -> void:
	party_queue = PARTY_SCRIPTS.duplicate()
	party_queue.shuffle()


func get_random_party() -> Party:
	@warning_ignore("integer_division")
	var result: Script = party_queue.pop_at(randi_range(0, (party_queue.size() - 1) / 2))
	party_queue.push_back(result)
	return result.new()


func wound_goblin() -> Big:
	var _wounded_count: Big = Big.ZERO
	var shuffled_gobs: Array[Gob] = PlayerData.army.gobs.duplicate()
	shuffled_gobs.shuffle()
	for gob: Gob in shuffled_gobs:
		_wounded_count = gob.wound_back(Big.ONE)
		if _wounded_count.is_gt(Big.ZERO):
			break
	return _wounded_count


func kill_goblin() -> Big:
	var _killed_count: Big = Big.ZERO
	var shuffled_gobs: Array[Gob] = PlayerData.army.gobs.duplicate()
	shuffled_gobs.shuffle()
	for gob: Gob in shuffled_gobs:
		_killed_count = gob.kill_back_wounded(Big.ONE)
		if _killed_count.is_eq(Big.ZERO):
			_killed_count = gob.kill_back_healthy(Big.ONE)
		if _killed_count.is_gt(Big.ZERO):
			break
	return _killed_count


func wound_goblins(pct: float) -> Big:
	var _wounded_count: Big = Big.ZERO
	var shuffled_gobs: Array[Gob] = PlayerData.army.gobs.duplicate()
	shuffled_gobs.shuffle()
	var target_gob_count: int = floori(shuffled_gobs.size() * pow(pct, 0.5))
	for i in target_gob_count:
		var gob: Gob = shuffled_gobs[i]
		_wounded_count = Big.add(_wounded_count, \
				gob.wound_back(Big.new(gob.get_count().to_float() * pow(pct, 0.5))))
	return _wounded_count


func kill_goblins(pct: float) -> Big:
	var _killed_count: Big = Big.ZERO
	var shuffled_gobs: Array[Gob] = PlayerData.army.gobs.duplicate()
	shuffled_gobs.shuffle()
	var target_gob_count: int = floori(shuffled_gobs.size() * pow(pct, 0.5))
	for i in target_gob_count:
		var gob: Gob = shuffled_gobs[i]
		_killed_count = Big.add(_killed_count, \
				gob.kill_back_healthy(Big.new(gob.get_count().to_float() * pow(pct, 0.5))))
	return _killed_count


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


func apply_group_headlines_to_army(group_string: String, nerf_factor: float) -> Array[Gob]:
	var affected_gobs: Array[Gob] = []
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
			affected_gobs.append(gob)
	return affected_gobs


func fix_plural(text: String) -> String:
	var result: String = text
	result = result.replace(" 1 goblins are ", " One goblin is ")
	result = result.replace(" 1 are ", " one is ")
	return result


class MurderBall extends Party:
	var _brutality: float = 0.5
	var _wounded_count: Big = Big.ZERO
	var _killed_count: Big = Big.ZERO
	
	func _init() -> void:
		super._init("MurderBall")
		_brutality = randf()
		name += "-%.1f" % [_brutality]
		
		if _brutality < 0.33:
			prompt = "\"Hey let's all play touch rules Murderball! " \
					+ "No actual murder, just touch the guy you woulda murdered.\""
		elif _brutality < 0.66:
			prompt = "\"Let's play Murderball, modern rules obviously! " \
					+ "No murdering below the belt, limit five murders per team.\""
		else:
			prompt = "\"How 'bout some classic rules Murderball! " \
					+ "No murder limit, but if you murder the ref then you're the new ref.\""
		
		likers = [Gobs.FIRE, Gobs.DEVIL]
		dislikers = [Gobs.WATER, Gobs.GRASS]
	
	
	func execute() -> String:
		# calculate wounded/killed goblins
		_wounded_count = PartyLibrary.wound_goblins(pow(_brutality, 2) * randf_range(0.0, 0.02))
		_killed_count = PartyLibrary.kill_goblins(pow(_brutality, 2) * randf_range(0.0, 0.02))
		
		# If nobody is wounded/killed -- maybe just wound/kill one goblin anyway. Were they the ball?
		if _wounded_count.is_eq(0) and _killed_count.is_eq(0) \
				and PlayerData.army.gobs.size() >= 2 and randf() < _brutality:
			if randf() < _brutality:
				_killed_count = PartyLibrary.kill_goblin()
			else:
				_wounded_count = PartyLibrary.wound_goblin()
		
		# 50% of goblins react +25 (+12.5); 25% of goblins react -10 (-2.5). Average = +10.0
		add_headline(MoraleEvent.MURDERBALL_WON).delta(35.0).pct(0.20)
		add_headline(MoraleEvent.MURDERBALL_LOST).delta(25.0).pct(0.15)
		add_headline(MoraleEvent.MURDERBALL_PLAY).delta(30.0).pct(0.15)
		add_headline(MoraleEvent.MURDERBALL_WON).delta(-5.0).pct(0.05)
		add_headline(MoraleEvent.MURDERBALL_LOST).delta(-10.0).pct(0.10)
		add_headline(MoraleEvent.MURDERBALL_PLAY).delta(-5.0).pct(0.05)
		finalize_morale()
		
		var result: String = "The goblins split into teams, kicking around an improvised ball, " \
				+ "cackling at the pathetic noises the 'ball' makes."
		if not PlayerData.army.gobs.is_empty():
			if _killed_count.is_gt(0) and _wounded_count.is_gt(0):
				result += " %s goblins are killed during the game, %s are wounded." % \
						[_killed_count.to_aa(), _wounded_count.to_aa()]
			elif _killed_count.is_gt(0):
				result += " %s goblins are killed during the game." % [_killed_count.to_aa()]
			elif _wounded_count.is_gt(0):
				result += " %s goblins are wounded during the game." % [_wounded_count.to_aa()]
		result = PartyLibrary.fix_plural(result)
		return result


class Gambling extends Party:
	const WINNINGS_BY_EVENT: Dictionary[MoraleEvent.MoraleEventType, Array] = {
		MoraleEvent.GAMBLING_WON_BIG: [5, 6, 7],
		MoraleEvent.GAMBLING_WON: [2, 3],
		MoraleEvent.GAMBLING_LOST: [-2, -3],
		MoraleEvent.GAMBLING_LOST_BIG: [-5, -6, -7],
		MoraleEvent.GAMBLING_PLAY: [-3, -2, 2, 3],
	}
	
	var _which: int = randi_range(0, 2)
	
	func _init() -> void:
		super._init("Gambling")
		match _which:
			0:
				prompt = "\"Anybody wanna play swindler's dice?"
				prompt += " C'mon, first swindle is on the house! Geh heh heh.\""
			1:
				prompt = "\"Let's play more swindler's dice!"
				prompt += " We ain't even gotta play for gold... if you're chicken.\""
			2:
				prompt = "\"It's been a while since we played swindler's dice!"
				prompt += " Who wants to give me their gold first?\""
		
		likers = [Gobs.FIRE, Gobs.GRASS]
		dislikers = [Gobs.DEVIL]
	
	func execute() -> String:
		add_headline(MoraleEvent.GAMBLING_WON_BIG).delta(50.0).pct(0.03)
		add_headline(MoraleEvent.GAMBLING_WON).delta(35.0).pct(0.25)
		add_headline(MoraleEvent.GAMBLING_LOST).delta(-5.0).pct(0.10)
		add_headline(MoraleEvent.GAMBLING_LOST).delta(5.0).pct(0.05)
		add_headline(MoraleEvent.GAMBLING_LOST_BIG).delta(-15.0).pct(0.02)
		add_headline(MoraleEvent.GAMBLING_PLAY).delta(15.0).pct(0.10)
		add_headline(MoraleEvent.GAMBLING_PLAY).delta(-5.0).pct(0.02)
		var gambling_gobs: Array[Gob] = finalize_morale()
		
		# randomly award goblins gold based on how RNG treated them
		var get_gob_ref_param_remaining: float = 0.0
		for gob: Gob in gambling_gobs:
			var last_event_type: MoraleEvent.MoraleEventType = gob.morale.get_last_event().type
			if not last_event_type in WINNINGS_BY_EVENT:
				continue
			var get_gob_ref_param_change_per_gob: int = WINNINGS_BY_EVENT[last_event_type].pick_random()
			gob.gold += get_gob_ref_param_change_per_gob
			get_gob_ref_param_remaining -= get_gob_ref_param_change_per_gob * gob.get_count().to_float()
		
		# give the RNG one pass to even things out, so gold doesn't enter/leave the economy
		gambling_gobs.shuffle()
		for gob: Gob in gambling_gobs:
			if abs(get_gob_ref_param_remaining) < 10.0:
				break
			var gob_size: float = gob.get_count().to_float()
			if gob_size * 0.5 >= abs(get_gob_ref_param_remaining):
				continue
			if get_gob_ref_param_remaining > 0.0:
				gob.gold += 1
				get_gob_ref_param_remaining -= gob.get_count().to_float()
			else:
				gob.gold -= 1
				get_gob_ref_param_remaining += gob.get_count().to_float()
		
		var result: String
		if randf() < 0.5:
			result = "The goblins break into groups of three or four," \
				+ " furiously rolling dice and shouting at each other for cheating. "
			if randf() < 0.5:
				result += " It's difficult to hide anything up your sleeves when you don't wear a shirt..."
			else:
				result += " Of course all the cheating cancels out in the end."
		else:
			result = "The goblins pull out sacks of weighted dice," \
					+ " and the air is filled with the sounds of laughter and loud arguments."
			if randf() < 0.5:
				result += " Hey, you're cheating wrong! "
			else:
				result += " What? That's not how you cheat! Let me show you."
		return result


class Drinking extends Party:
	var _wounded_count: Big = Big.ZERO
	var _which: int = randi_range(0, 2)
	
	func _init() -> void:
		super._init("Drinking")
		match _which:
			0:
				prompt = "\"Let's get drunk and go nuts! We got some extra get_gob_ref_param, right?"
				prompt += " C'monnn let's live a little!\""
			1:
				prompt = "\"If you can find us some alcohol,"
				prompt += " how bout we put it in our mouths until we start actin' funny!\""
			2:
				prompt = "\"Where's the beer? C'mon we gotta party while the partyin's good!"
				prompt += " We could die tomorrow, man.\""
		
		likers = [Gobs.FIRE, Gobs.GRASS, Gobs.ANGEL, Gobs.DEVIL]
		dislikers = []
		expected_reward = 13.0
	
	
	func execute() -> String:
		add_headline(MoraleEvent.DRINKING_FOOLISH).delta(10.0).pct(0.20)
		add_headline(MoraleEvent.DRINKING_FOOLISH).delta(-5.0).pct(0.05)
		add_headline(MoraleEvent.DRINKING_PARTY).delta(20.0).pct(0.20)
		add_headline(MoraleEvent.DRINKING_PARTY).delta(-5.0).pct(0.05)
		add_headline(MoraleEvent.DRINKING_FIGHT).delta(30.0).pct(0.25)
		add_headline(MoraleEvent.DRINKING_FIGHT).delta(-10.0).pct(0.05)
		var fighting_gobs: Array[Gob] = finalize_morale()
		fighting_gobs = fighting_gobs.filter(func(gob: Gob) -> bool:
			return gob.morale.get_last_event().type == MoraleEvent.DRINKING_FIGHT)
		
		# wound goblins who were in a fight
		for gob: Gob in fighting_gobs:
			if randf() < 0.5:
				continue
			_wounded_count = Big.add(_wounded_count,
					gob.wound_back(Big.new(maxf(1.0, gob.get_count().to_float() * randf_range(0.0, 0.03)))))
			gob.front_hp = maxi(1, gob.front_hp - randi_range(1, 3))
		
		var result: String
		if randf() < 0.5:
			result = "The goblins erupt into cacophony of off-key singing and drinking."
			if randf() < 0.5:
				result += " Some sing so badly it provokes a few fights, which inspire new songs."
			else:
				result += " As the embarrassment of public singing sets in, they drink even more to forget."
		else:
			result = "The goblins improvise new drinking games focused on violence and humiliation."
			if randf() < 0.5:
				result += " 'Let's have a bite-off!' 'Ow, hey, you bit me!!!'"
			else:
				result += " 'Someone punch me in the stomach, I can take it! ...OW!!! What was that for!?'"
		if _wounded_count.is_gt(0):
			result += " %s goblins are wounded." % [_wounded_count.to_aa()]
		result = PartyLibrary.fix_plural(result)
		return result


class Hazing extends Party:
	var _wounded_count: Big = Big.ZERO
	var _which: int = randi_range(0, 2)
	var _victim: Gob
	var _victim_string: String
	
	func _init() -> void:
		super._init("Hazing")
		
		# find the victim
		for i in range(PlayerData.army.gobs.size() - 1, -1, -1):
			if _victim == null or PlayerData.army.gobs[i].level < _victim.level:
				_victim = PlayerData.army.gobs[i]
		_victim_string = "new guy"
		if _victim != null:
			_victim_string = "%s %s" % [Gobs.emoji_from_type(_victim.type), _victim.name]
		
		match _which:
			0:
				prompt = "\"Let's take turns initiatin' the new guy into our little goblin crew!"
				prompt += " Hey %s, get your ass over here!\"" % [_victim_string]
			1:
				prompt = "\"Who wants to help me break in the new meat?\""
				prompt += " %s ain't had their ass beat yet!\"" % [_victim_string]
				prompt = prompt.replace("new guy", "The new guy")
			2:
				prompt = "\"Nothing quite like beatin' up someone weaker than you."
				prompt += " Let's teach %s what we're all about, wheh heh heh!\"" % [_victim_string]
				prompt = prompt.replace("new guy", "the new guy")
		
		likers = [Gobs.FIRE, Gobs.WATER, Gobs.GRASS, Gobs.DEVIL]
		if _victim:
			likers.erase(_victim.type)
		dislikers = [Gobs.ANGEL]
		if _victim:
			if _victim.type != Gobs.ANGEL:
				dislikers.append(_victim.type)
	
	
	func execute() -> String:
		var victim_weights: Dictionary[Gobs.Type, float] = {
				Gobs.FIRE: 0.1, Gobs.WATER: 0.1, Gobs.GRASS: 0.1, Gobs.ANGEL: 0.1, Gobs.DEVIL: 0.1}
		var attacker_weights: Dictionary[Gobs.Type, float] = {
				Gobs.FIRE: 1.0, Gobs.WATER: 1.0, Gobs.GRASS: 1.0, Gobs.ANGEL: 0.1, Gobs.DEVIL: 1.0}
		if _victim:
			victim_weights[_victim.type] = 1.0
			attacker_weights[_victim.type] = 0.1
		
		var victim_headline: MoraleDigest.Headline
		add_headline(MoraleEvent.HAZING_ATTACKER).delta(35.0).pct(0.35).type_weights(attacker_weights)
		add_headline(MoraleEvent.HAZING_WITNESS).delta(25.0).pct(0.15)
		add_headline(MoraleEvent.HAZING_VICTIM).delta(10.0).pct(0.20).type_weights(victim_weights)
		victim_headline = PlayerData.morale_digest.headlines.back()
		add_headline(MoraleEvent.HAZING_ATTACKER).delta(-5.0).pct(0.05).type_weights(attacker_weights)
		add_headline(MoraleEvent.HAZING_WITNESS).delta(-5.0).pct(0.05)
		add_headline(MoraleEvent.HAZING_VICTIM).delta(-20.0).pct(0.40).type_weights(victim_weights)
		if randf() < 0.33:
			# about a third of goblins don't enjoy it
			victim_headline = PlayerData.morale_digest.headlines.back()
		
		if _victim:
			_victim.morale.add_event(victim_headline.create_event())
		var victim_gobs: Array[Gob] = finalize_morale()
		if _victim:
			if _victim in victim_gobs:
				_victim.morale.pop_last_event()
			else:
				victim_gobs.append(_victim)
		victim_gobs = victim_gobs.filter(func(gob: Gob) -> bool:
			return gob.morale.get_last_event().type == MoraleEvent.HAZING_VICTIM)
		
		# wound goblins who were hazed
		for gob: Gob in victim_gobs:
			if randf() < 0.5 and not gob == _victim:
				continue
			_wounded_count = Big.add(_wounded_count,
					gob.wound_back(Big.new(maxf(1.0, gob.get_count().to_float() * randf_range(0.0, 0.03)))))
			gob.front_hp = maxi(1, gob.front_hp - randi_range(1, 3))
		
		var victim_female: bool = randf() < 0.5
		var result: String
		if randf() < 0.5:
			result = "The goblins blindfold %s, shove him to the ground and beat the crap out of him." % \
					[_victim_string]
			if victim_female:
				result = result.replace("shove him", "shove her")
				result = result.replace("out of him", "out of her")
			result = result.replace("blindfold new guy", "blindfold the new guy")
			if randf() < 0.5:
				result += " %s taunts them, 'is that all you got? Ha ha.' He's one of them now." % [_victim_string]
				if victim_female:
					result = result.replace("He's one of", "She's one of")
			else:
				result += " Strangely, other goblins blindfold themselves hoping to join in. 'Me! Do me next!!'"
		else:
			result = "The goblins pin %s to the ground, kicking him and making him eat things." % [_victim_string]
			if victim_female:
				result = result.replace("him and making him", "her and making her")
				result = result.replace("pin new guy", "pin the new girl")
			else:
				result = result.replace("pin new guy", "pin the new guy")
			if randf() < 0.5:
				result += " 'Make 'em eat this slug I found!' 'Wait he liked it? ...I wanna eat a slug!'"
				if victim_female:
					result = result.replace("Make 'em", "make 'er")
					result = result.replace(" he liked", " she liked")
			else:
				result += " Unfortunately he likes being kicked and eating things, so they move onto someone else..."
				if victim_female:
					result = result.replace(" he likes", " she likes")
		if _wounded_count.is_gt(0):
			result += " %s goblins are wounded." % [_wounded_count.to_aa()]
		result = PartyLibrary.fix_plural(result)
		return result


class Pranks extends Party:
	var _which: int = randi_range(0, 2)
	
	func _init() -> void:
		super._init("Pranks")
		
		match _which:
			0:
				prompt = "\"Hey you see those idiots sleepin over there? I got an idea for a hilarious prank...\""
			1:
				prompt = "\"I got a new prank idea I wanted to try out. Trust me, this'll be hilarious!\""
			2:
				prompt = "\"Me and the other guys had an idea for a really funny prank. You on board?\""
		
		likers = [Gobs.WATER, Gobs.ANGEL]
		dislikers = [Gobs.DEVIL]
	
	
	func execute() -> String:
		add_headline(MoraleEvent.PRANKS_VICTIM).delta(10.0).pct(0.10)
		add_headline(MoraleEvent.PRANKS_ATTACKER).delta(30.0).pct(0.25)
		add_headline(MoraleEvent.PRANKS_WITNESS).delta(20.0).pct(0.25)
		add_headline(MoraleEvent.PRANKS_VICTIM).delta(-3.0).pct(0.25)
		finalize_morale()
		
		var result: String
		if randf() < 0.5:
			result = "The pranking goblins concoct a bunch of silly schemes using"
			if randf() < 0.5:
				result += " wasp nests, sticky sap,"
			else:
				result += " hot coals, rotten fish,"
			result += " all sorts of gross and painful ways to torture each other."
			result = " They laugh and bond over the resulting mischief."
		else:
			result = "Several sleeping goblins are rudely awakened by disgusting and painful plots, mostly involving"
			if randf() < 0.5:
				result += " sharp sticks and smelly garbage."
			else:
				result += " prickly thorns and leeches."
			result += " They find new victims for their favorite pranks and mischief spreads throughout the camp."
		return result


class Brawl extends Party:
	var _which: int = randi_range(0, 2)
	var _wounded_count: Big = Big.ZERO
	
	func _init() -> void:
		super._init("Brawl")
		
		match _which:
			0:
				prompt = "\"I gotta unleash some pent-up aggression."
				prompt += " How about we all just get in a big pile and like wail each other!\""
			1:
				prompt = "\"Let's have some kinda big... beatin' each other up contest thing!"
				prompt += " Like a big goblin battle royale.\""
			2:
				prompt = "\"Who else thinks they're the biggest, baddest goblin in the camp?"
				prompt += " Who thinks they can take me? C'mon!\""
		
		likers = [Gobs.WATER, Gobs.DEVIL]
		dislikers = [Gobs.FIRE, Gobs.GRASS, Gobs.ANGEL]
	
	
	func execute() -> String:
		add_headline(MoraleEvent.BRAWL_WON).delta(40.0).pct(0.30)
		add_headline(MoraleEvent.BRAWL_LOST).delta(10.0).pct(0.20)
		add_headline(MoraleEvent.BRAWL_WITNESS).delta(25.0).pct(0.15)
		add_headline(MoraleEvent.BRAWL_WON).delta(-5.0).pct(0.10)
		add_headline(MoraleEvent.BRAWL_LOST).delta(-10.0).pct(0.10)
		add_headline(MoraleEvent.BRAWL_WITNESS).delta(-5.0).pct(0.05)
		var fighting_gobs: Array[Gob] = finalize_morale()
		
		# wound goblins who were in a fight
		for gob: Gob in fighting_gobs:
			if randf() < 0.6:
				continue
			elif randf() < 0.6:
				gob.front_hp = maxi(1, gob.front_hp - randi_range(1, 3))
			else:
				_wounded_count = Big.add(_wounded_count,
						gob.wound_back(Big.new(maxf(1.0, gob.get_count().to_float() * randf_range(0.0, 0.02)))))
		
		var result: String
		if randf() < 0.5:
			result = "The goblins pair off and fight, immersed in a sea of spectators."
			if randf() < 0.5:
				result += " 'Yeah, kick his ass!' 'You're cheerin' for that guy? That guy sucks!'"
				result += " The spectators quickly devolve into a brawl of their own."
			else:
				result += " After trading bloody noses and bruises, the goblins laugh and hug each other,"
				result += " and the best hugger is declared the victor."
		else:
			result = "Two goblins tackle each other to the ground and start beating each other senseless."
			if randf() < 0.5:
				result += " Excited by the sudden display of violence, the other goblins join in,"
				result += " the camp devolving into a raucous bloody brawl."
			else:
				result += " The other goblins cackle with glee,"
				result += " joining in and landing kicks and punches where they can."
		if _wounded_count.is_gt(0):
			result += " %s goblins are wounded." % [_wounded_count.to_aa()]
		result = PartyLibrary.fix_plural(result)
		return result


class Festival extends Party:
	var _which: int = randi_range(0, 2)
	
	func _init() -> void:
		super._init("Festival")
		
		match _which:
			0:
				prompt = "\"How about a good ol' goblin festival with like..."
				prompt = " Food, drinks, music, dancin', all that good stuff!\""
			1:
				prompt = "\"Let's get some music here! Y'know, a little dancing, some nice food,"
				prompt += " a good ol' goblin time.\""
			2:
				prompt = "\"Can't we just relax and y'know, dance and screw around for a change?"
				prompt += " I'm bored of beatin' stuff up.\""
		
		likers = [Gobs.FIRE, Gobs.ANGEL]
		dislikers = [Gobs.WATER]
	
	
	func execute() -> String:
		add_headline(MoraleEvent.FESTIVAL_DANCE).delta(25.0).pct(0.15)
		add_headline(MoraleEvent.FESTIVAL_LOVE).delta(50.0).pct(0.05)
		add_headline(MoraleEvent.FESTIVAL_LOVE).delta(35.0).pct(0.10)
		add_headline(MoraleEvent.FESTIVAL_RELAX).delta(20.0).pct(0.20)
		add_headline(MoraleEvent.FESTIVAL_DANCE).delta(-5.0).pct(0.05)
		add_headline(MoraleEvent.FESTIVAL_LOVE).delta(-15.0).pct(0.05)
		add_headline(MoraleEvent.FESTIVAL_RELAX).delta(-5.0).pct(0.05)
		finalize_morale()
		
		var result: String
		if randf() < 0.5:
			result = "The joyful sounds of music and laughter fill the air, "
			if randf() < 0.5:
				result += " as goblins embarrass themselves with their awkward dance moves."
				result += " Apparently good warriors make terrible dancers."
			else:
				result += " as goblins impress others with their cool dance moves."
				result += " Not all talents are showcased on the battlefield."
		else:
			result = "The goblins take a break from fighting to laugh, drink and tell"
			if randf() < 0.5:
				result += " filthy jokes."
			elif randf() < 0.5:
				result += " unsettling jokes."
			result += " A few goblins break out instruments,"
			if randf() < 0.5:
				result += " impressing others with just how terrible they are."
			else:
				result += " impressing others with their hidden talents."
		return result
