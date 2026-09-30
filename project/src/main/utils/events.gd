extends Node
## Global event bus which relays signals between parts of the game that have no natural connection.[br]
## [br]
## Use judgment before adding signals here. It's better to connect listeners directly to emitters.

enum BattleResult {
	VICTORY,
	DEFEAT,
	SURRENDER,
	MUTUAL_DEFEAT,
	RETREAT
}

@warning_ignore("unused_signal")
signal battle_finished(dungeon: Dungeon, result: BattleResult)

@warning_ignore("unused_signal")
signal party_finished(party: Party, beer_count: Big)
