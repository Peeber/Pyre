extends ProgressBar

@export var player : Player

func _ready():
	if !SignalBus.is_connected("healthChanged",update):
		SignalBus.healthChanged.connect(update)

func update(target,new_value,isMax):
	if target is Player:
		if isMax:
			max_value = new_value
		else:
			value = new_value
	
