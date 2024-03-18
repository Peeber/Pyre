extends Area2D
class_name Door

@export var currentWorld : Node2D
@export var nextWorldName : String
@export var isLocked : bool
@export var exit : Marker2D

func _on_body_entered(body):
	print("detected " + body.name)
	if isLocked == false:
		print("detected " + body.name)
		if body is Player:
			SignalBus.sceneChanged.emit(nextWorldName)
			print("Changed from " + currentWorld.name + "to " + nextWorldName)
		

func lock():
	isLocked = true

func unlock():
	isLocked = false
