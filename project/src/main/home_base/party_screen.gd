extends Control

const PARTY_GOB_ROW_SCENE: PackedScene = preload("res://src/main/home_base/party_gob_row.tscn")
const PARTY_ROW_SCENE: PackedScene = preload("res://src/main/home_base/party_row.tscn")

func _ready() -> void:
	%AskAroundButton.pressed.connect(_refresh_party_gob_rows)
	
	if HomeBaseData.party_data.partied:
		%MessageShower.set_message(HomeBaseData.party_data.party_result)
	
	%MultiplyButton.pressed.connect(_adjust_multiplier.bind(1))
	%DivideButton.pressed.connect(_adjust_multiplier.bind(-1))
	
	reset()


func reset() -> void:
	%MessageShower.set_message("[i](Let's do something fun!)[/i]")
	_populate_parties()
	refresh()


func refresh() -> void:
	_refresh_army_label()
	_refresh_party_gob_rows()
	_refresh_party_cost()


func _populate_parties() -> void:
	for child: Node in %Parties.get_children():
		%Parties.remove_child(child)
		child.queue_free()
	for party: Party in HomeBaseData.party_data.get_parties():
		var party_row: PartyRow = PARTY_ROW_SCENE.instantiate()
		party_row.party = party
		party_row.item_count = Big.ZERO
		party_row.item_type = Items.STRONG_MEDICINE
		party_row.likers = party.likers
		party_row.dislikers = party.dislikers
		party_row.pressed.connect(_on_party_row_pressed.bind(party_row))
		%Parties.add_child(party_row)


func _refresh_party_cost() -> void:
	for party_row: PartyRow in %Parties.get_children():
		match PlayerData.party_multiplier:
			0:
				party_row.item_count = Big.ZERO
				party_row.party.nerf_factor = 0.4
			1:
				party_row.item_count = Big.new(max(1, PlayerData.army.get_total_goblins().to_float() * 0.01))
				party_row.party.nerf_factor = 0.7
			2:
				party_row.item_count = Big.new(max(3, PlayerData.army.get_total_goblins().to_float() * 0.03))
				party_row.party.nerf_factor = 1.0
	%MultiplyButton.disabled = true if PlayerData.party_multiplier >= 2 else false
	%DivideButton.disabled = true if PlayerData.party_multiplier <= 0 else false


func _refresh_army_label() -> void:
	var new_text: String = ""
	new_text += "Your army:\n"
	var summary: Army.ArmySummary = PlayerData.army.get_summary()
	var morale_by_type: Dictionary[Gobs.Type, float] = PlayerData.army.get_average_morale_by_type()
	if summary.total_goblins.is_eq(0):
		new_text += "[b]%s goblins[/b]\n" % \
				[summary.total_goblins.to_aa()]
	else:
		new_text += "[b]%s goblins, [/b]%s\n" % \
				[summary.total_goblins.to_aa(), Gobs.morale_bbcode(PlayerData.army.get_average_morale(), true)]
	for goblin_type: Gobs.Type in Gobs.Type.values():
		if summary.goblins_by_type[goblin_type].is_gte(1):
			new_text += "%s: %s goblins, %s\n" % [
					Gobs.emoji_from_type(goblin_type),
					summary.goblins_by_type[goblin_type].to_aa(),
					Gobs.morale_bbcode(morale_by_type[goblin_type])]
	%ArmyLabel.text = new_text.strip_edges()


func _refresh_party_gob_rows() -> void:
	for child: Node in %PartyGobRows.get_children():
		%PartyGobRows.remove_child(child)
		child.queue_free()
	var gobs_to_show: Array[Gob] = PlayerData.army.gobs.duplicate()
	gobs_to_show.shuffle()
	for i in mini(gobs_to_show.size(), 4):
		var party_gob_row: PartyGobRow = PARTY_GOB_ROW_SCENE.instantiate()
		party_gob_row.gob = gobs_to_show[i]
		%PartyGobRows.add_child(party_gob_row)


func _adjust_multiplier(factor: int) -> void:
	PlayerData.party_multiplier = clampi(PlayerData.party_multiplier + factor, 0, 2)
	_refresh_party_cost()
	
	if HomeBaseData.party_data.partied:
		%MultiplyButton.disabled = true
		%DivideButton.disabled = true


func _on_party_row_pressed(party_row: PartyRow) -> void:
	if not PlayerData.inventory.has_item(party_row.item_type, party_row.item_count):
		return
	
	HomeBaseData.party_data.party_result = party_row.party.execute()
	HomeBaseData.party_data.partied = true
	for child: PartyRow in %Parties.get_children():
		child.refresh()
	PlayerData.inventory.take_item(party_row.item_type, party_row.item_count)
	%MessageShower.play_message(HomeBaseData.party_data.party_result)
	refresh()
