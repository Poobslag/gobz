class_name TrophyRow
extends HBoxContainer

const COLOR_LOCKED: Color = Color("00000080")

const LOCKED: PlayerData.CollectibleStatus = PlayerData.CollectibleStatus.LOCKED
const UNLOCKED: PlayerData.CollectibleStatus = PlayerData.CollectibleStatus.UNLOCKED
const REPORTED: PlayerData.CollectibleStatus = PlayerData.CollectibleStatus.REPORTED
const VIEWED: PlayerData.CollectibleStatus = PlayerData.CollectibleStatus.VIEWED

var collectible: Collectible

func _ready() -> void:
	if collectible == null:
		return
	
	%Emoji.text = collectible.emoji
	%Emoji.self_modulate = COLOR_LOCKED if collectible.get_status() == LOCKED else Color.WHITE
	%NewLabel.visible = collectible.get_status() in [UNLOCKED, REPORTED]
	
	%Desc.text = collectible.desc
	%Desc.self_modulate = COLOR_LOCKED if collectible.get_status() == LOCKED else Color.WHITE
	%Instructions.text = collectible.get_instructions()
	
	if collectible.get_status() in [UNLOCKED, REPORTED]:
		PlayerData.collectible_status[collectible.id] = VIEWED
