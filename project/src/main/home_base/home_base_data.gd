extends Node

var heal_data: HealData = HealData.new()
var party_data: PartyData = PartyData.new()

func reset() -> void:
	heal_data.reset()
	party_data.reset()
