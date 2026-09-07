extends Node
## [b]Keys:[/b][br]
## 	[kbd]F[/kbd]: Inflate type weights for fire goblins
## 	[kbd]W[/kbd]: Inflate type weights for water goblins
## 	[kbd]G[/kbd]: Inflate type weights for grass goblins
## 	[kbd]A[/kbd]: Inflate type weights for angel goblins
## 	[kbd]D[/kbd]: Inflate type weights for devil goblins
## 	[kbd]X[/kbd]: Reset type weights to defaults
## 	[kbd]R[/kbd]: Regenerate parties
## 	[kbd][-,=][/kbd]: Decrease/increase nerf factor.[br]

var gob_count: int = 1000
var gob_size: Big = Big.new(5)
var type_weights: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0]
var nerf_factor: float = 1.0

var pending_parties: Array[Party] = []

func _ready() -> void:
	%Button.pressed.connect(regenerate_parties)
	regenerate_parties()


func _process(_delta: float) -> void:
	if pending_parties:
		execute_party(pending_parties.pop_front())


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_MINUS:
			nerf_factor = nerf_factor - 0.2
			print_line("Nerf factor: %.1f" % [nerf_factor])
		KEY_EQUAL:
			nerf_factor = nerf_factor + 0.2
			print_line("Nerf factor: %.1f" % [nerf_factor])
		KEY_F:
			type_weights = [5.0, 1.0, 1.0, 1.0, 1.0]
			print_line("Type weights: 🔥")
		KEY_W:
			type_weights = [1.0, 5.0, 1.0, 1.0, 1.0]
			print_line("Type weights: 💧")
		KEY_G:
			type_weights = [1.0, 1.0, 5.0, 1.0, 1.0]
			print_line("Type weights: 🌳")
		KEY_A:
			type_weights = [1.0, 1.0, 1.0, 5.0, 1.0]
			print_line("Type weights: 🕊")
		KEY_D:
			type_weights = [1.0, 1.0, 1.0, 1.0, 5.0]
			print_line("Type weights: 😈")
		KEY_X:
			type_weights = [1.0, 1.0, 1.0, 1.0, 1.0]
			print_line("Type weights: Default")
		KEY_R:
			regenerate_parties()


func execute_party(party: Party) -> void:
	for gob: Gob in PlayerData.army.gobs:
		gob.morale.clear()
	
	var morale_before: float = PlayerData.army.get_average_morale()
	var attack_before: float = PlayerData.army.get_total_attack().to_float()
	party.execute()
	var affected_gobs: int = 0
	var total_gobs: int = 0
	for gob: Gob in PlayerData.army.gobs:
		total_gobs += 1
		if gob.morale.size() > 0:
			affected_gobs += 1
	var affected_pct: float = affected_gobs / float(total_gobs)
	var morale_after: float = PlayerData.army.get_average_morale()
	var attack_after: float = PlayerData.army.get_total_attack().to_float()
	var morale_delta_string: String = "%s%.1f" % \
			["+" if morale_after > morale_before else "", morale_after - morale_before]
	var attack_delta_string: String = "%s%.1f" % \
			["+" if attack_after > attack_before else "", attack_after - attack_before]
	print_line("%s morale: %s (%.1f->%.1f) affected: %.1f attack: %s (%s->%s)" % [party.name,
			morale_delta_string, morale_before, morale_after,
			affected_pct * 100,
			attack_delta_string, Big.new(attack_before).to_aa(), Big.new(attack_after).to_aa()])


func print_line(line: String) -> void:
	if %RichTextLabel.text:
		%RichTextLabel.text += "\n"
	%RichTextLabel.text += line


func regenerate_parties() -> void:
	%RichTextLabel.text = ""
	
	for party_script: Script in PartyLibrary.PARTY_SCRIPTS:
		for gob: Gob in PlayerData.army.gobs:
			gob.morale.clear()
		reset_player_data()
		var party: Party = party_script.new()
		party.nerf_factor = nerf_factor
		pending_parties.append(party)


func reset_player_data() -> void:
	PlayerData.reset()
	HomeBaseData.reset()
	for _i in gob_count:
		var gob: Gob = PlayerData.army.generate_random_recruit({
				"count": gob_size,
				"type_weights": type_weights
			})
		PlayerData.army.add_gob(gob)
	PlayerData.gold = Big.new(5000)
	PlayerData.inventory.add_item(Items.STRONG_MEDICINE, Big.new(5000))
