extends Timer
class_name DataTimer

@export var data : Array = []
signal arg_timeout(data)

func _ready():
	if not is_connected("timeout",_on_timeout):
		timeout.connect(_on_timeout)

func _on_timeout():
	arg_timeout.emit(data)
