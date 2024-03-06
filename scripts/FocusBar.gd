extends ProgressBar

@onready var timer = Timer
# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	if !SignalBus.is_connected("focusChanged",update):
		SignalBus.focusChanged.connect(update)

func update(new_focus):
	value = new_focus
	if State.arenaMode and value == 0:
		visible = false
		print("focus bar closed")
	else:
		visible = true
		print("focus bar revealed")
		
