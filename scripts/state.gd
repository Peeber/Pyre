extends Node

#insert global state variables here
var switchingRooms = false
var currentPlayer: Player
var focusPaused : bool = true
var arenaMode : bool = false
var abilitiesAllowed : bool = true
var paused : bool = false
var scriptedAbility : bool = false

func toggleFocusPaused():
	focusPaused = !focusPaused

func toggleArenaMode(instantFocus : bool):
	arenaMode = !arenaMode
	if instantFocus:
		toggleFocusPaused()
		SignalBus.arenaModeSet.emit(arenaMode)
		
func toggleAbilities():
	abilitiesAllowed = !abilitiesAllowed
	SignalBus.abilitiesToggled.emit(abilitiesAllowed)

func pause():
	get_tree().paused = true
	paused = true

func unpause():
	get_tree().paused = false
	paused = false
