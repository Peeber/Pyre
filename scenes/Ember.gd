extends TextureRect

@onready var label = $Label

# Called when the node enters the scene tree for the first time.
func _ready():
	refresh(1)
	if !SignalBus.is_connected("abilitiesToggled",toggle):
		SignalBus.abilitiesToggled.connect(toggle)
	if !SignalBus.is_connected("emberChanged",refresh):
		SignalBus.emberChanged.connect(refresh)

func refresh(value):
	label.text = str(value)

func toggle(is_allowed):
	visible = is_allowed
