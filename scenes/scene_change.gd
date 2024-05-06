extends Node

var next_world : Node2D
var old_camera : PhantomCamera2D
var new_camera : PhantomCamera2D
var tween_duration : float

@onready var current_world = $test_world
@onready var anim = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	if !SignalBus.is_connected("sceneChanged",changeScene):
		SignalBus.sceneChanged.connect(changeScene)
	#gives the player abilities for testing
	State.currentPlayer.addWeapon("Ember of Hope")
	SignalBus.addedAbility.emit("Consolidate Ember","Ember of Hope")
	SignalBus.addedAbility.emit("Spark","Ember of Hope")
	get_viewport().process_mode = Node.PROCESS_MODE_ALWAYS
	var current_camera : PhantomCamera2D = Globals.find_by_type(self,PhantomCamera2D)
	if not current_camera.get_follow_target():
		current_camera.set_follow_target(State.currentPlayer)

func get_current_world():
	return current_world

func changeScene(next_world_name: String):
	State.scene_changing = true
	print("changing scene from " + current_world.name + " to " + next_world_name)
	next_world = load("res://scenes/rooms/" + next_world_name + ".tscn").instantiate()
	next_world.z_index = -1
	call_deferred("add_child",next_world)
	anim.play("fade_in")

func _on_animation_player_animation_finished(anim_name):
	old_camera = current_world.get_node("PhantomCamera2D")
	match anim_name:
		"fade_in":
			$CanvasLayer/ColorRect.color = Color(0,0,0,1)
			new_camera = next_world.get_node("PhantomCamera2D")
			old_camera.set_tween_duration(0)
			tween_duration = new_camera.get_tween_duration() + 0.0
			new_camera.set_tween_duration(0)
			
			#kidnap player
			var tilemap : TileMap
			var player : Player = State.currentPlayer.duplicate()
			var exit : Marker2D
			for x in Globals.get_all_children(next_world):
				if x is TileMap:
					if x.has_node("Player"):
						x.get_node("Player").queue_free()
					tilemap = x
					tilemap.add_child(player)
				elif x is Door:
					if x.nextWorldName == current_world.name:
						exit = x.exit
						
			print(player.get_parent())
			print(State.currentPlayer.get_parent())
			State.currentPlayer = player
			player.relink_components()
			new_camera.set_follow_target(player)
			print(new_camera.follow_target)
			SignalBus.teleportedTo.emit(exit.global_position)
			old_camera.set_priority(0)
			new_camera.set_priority(1)
			current_world.remove_child(old_camera)
			old_camera = null
			
			current_world.queue_free()
			current_world = next_world
			current_world.z_index = 0
			next_world = null
			$CanvasLayer/ColorRect.color = Color(0,0,0,0)
			print(tween_duration)
			anim.play("fade_out")
		"fade_out":
			State.toggleArenaMode()
			State.toggleArenaMode()
			print("stored tween duration is ", tween_duration)
			new_camera.set_tween_duration(tween_duration)
			old_camera = new_camera
			old_camera.set_priority(0)
			new_camera = null
			State.scene_changing = false
			await get_tree().create_timer(0.5).timeout
			old_camera.set_follow_target(State.currentPlayer)
