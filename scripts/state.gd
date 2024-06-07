extends Node

#insert global state variables here
var switchingRooms = false
var currentPlayer: Player
var focusPaused : bool = true
var arenaMode : bool = false
var abilitiesAllowed : bool = true
var paused : bool = false
var scriptedAbility : bool = false
var emberMax : int = 1
var sparkMax : int = 3
var sparks = []
var scene_changing : bool = false
var latest_actionable_target

func toggleFocusPaused():
	focusPaused = !focusPaused

func toggleArenaMode(delayFocus : bool = false):
	arenaMode = !arenaMode
	if not delayFocus:
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

func sparkAdded(spark : Spark):
	for x in sparks:
		if not is_instance_valid(x):
			sparks.remove_at(sparks.find(x))
	sparks.append(spark)
	if sparks.size() > sparkMax:
		var old = sparks[0]
		sparks.remove_at(0)
		old.queue_free()

func failedCast(source,isEmber):
	if State.arenaMode == true and source is Player:
		if isEmber:
			State.currentPlayer.embers += 1
			SignalBus.emberChanged.emit(State.currentPlayer.embers)
		else:
			State.currentPlayer.focus = 100
