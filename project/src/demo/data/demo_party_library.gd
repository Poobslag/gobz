extends Node
## [b]Keys:[/b][br]
## 	[kbd]F[/kbd]: Inflate type weights for fire goblins
## 	[kbd]W[/kbd]: Inflate type weights for water goblins
## 	[kbd]G[/kbd]: Inflate type weights for grass goblins
## 	[kbd]A[/kbd]: Inflate type weights for angel goblins
## 	[kbd]D[/kbd]: Inflate type weights for devil goblins
## 	[kbd]X[/kbd]: Reset type weights to defaults
## 	[kbd]R[/kbd]: Reset type weights to defaults
## 	[kbd][-,=][/kbd]: Decrease/increase nerf factor.[br]

var gob_count: int = 1000
var gob_size: Big = Big.new(5)
var type_weights: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0]
var nerf_factor: float = 1.0

func _ready() -> void:
	%Button.pressed.connect(regenerate_parties)
	regenerate_parties()


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


func print_line(line: String) -> void:
	if %RichTextLabel.text:
		%RichTextLabel.text += "\n"
	%RichTextLabel.text += line


func regenerate_parties() -> void:
	%RichTextLabel.text = ""
	
	PartyLibrary.party_queue.sort()
	for party_script: Script in PartyLibrary.PARTY_SCRIPTS:
		reset_player_data()
		var morale_before: float = PlayerData.army.get_average_morale()
		var party: Party = party_script.new()
		party.nerf_factor = nerf_factor
		party.execute()
		var morale_after: float = PlayerData.army.get_average_morale()
		var morale_delta_string: String = "%s%.1f" % \
				["+" if morale_after > morale_before else "", morale_after - morale_before]
		%RichTextLabel.text += "%s %s (%.1f->%.1f)" % [party.name, morale_delta_string, morale_before, morale_after]


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
