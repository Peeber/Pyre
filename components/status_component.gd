extends Marker2D
class_name StatusComponent

@export var heart : Node = get_parent() :
	set(value):
		heart = value
		if is_instance_valid(heart):
			heart_changed.emit()
@export var hp : HealthComponent
#@export var hitbox : HitboxComponent
#@export var knockback : KnockbackComponent
@export var immunity : ImmunityComponent

var active_statuses : Dictionary = {}
var clear_in_progress : bool = false

signal effect_added(effect : StatusEffect)
signal effect_altered(effect : StatusEffect)
signal effect_ended(effect : StatusEffect)
signal heart_changed(new_heart : Node)
signal effect_timer_ended(effect : StatusEffect)
signal step_timer_ended(effect : StatusEffect)
signal clear_finished()

func _ready():
	if not heart:
		heart = get_parent()
	if not hp:
		hp = Globals.find_by_type(heart,HealthComponent)
	#if not hitbox:
	#	hitbox = Globals.find_by_type(heart,HitboxComponent)
	#if not knockback:
	#	knockback = Globals.find_by_type(heart,KnockbackComponent)

func process_status_list(statuses):
	if not heart or not is_instance_valid(heart):
		await heart_changed
	if clear_in_progress:
		await clear_finished
	if !(statuses is Array[StatusEffect]):
		print("gave StatusComponent in " + heart.name + " something that wasn't an array of statuses in process_status_list: ",statuses)
		return
	else:
		for effect in statuses:
			add_status(effect)
		

func add_status(status : StatusEffect):
	if not heart or not is_instance_valid(heart):
		print("WARNING: no heart found for StatusComponent at path ", self.get_path(), " yielding until one is set")
		await heart_changed
	if immunity and is_instance_valid(immunity):
		if immunity.is_immune_to(status.effect_name):
			return
	if clear_in_progress:
		await clear_finished
	#gives UnnamedEffects a number, like "UnnamedEffect1" or "UnnamedEffect78", for debug purposes (dont actually use UnnamedEffects tho they stack infinitely, this is just so they dont fuse and create a mega status)
	if status.effect_name == "UnnamedEffect":
		var names = active_statuses.keys()
		if "UnnamedEffect" in names:
			var id = 1
			var finished = false
			while not finished:
				if !(("UnnamedEffect" + id) in names):
					status.effect_name = "UnnamedEffect" + id
					finished = true
				else:
					id += 1
	
	if status in active_statuses.values():
		var effect_timer = get_node_or_null(status.effect_name + "Duration")
		if effect_timer:
			if effect_timer.time_left < status.duration:
				effect_timer.wait_time = status.duration
				effect_timer.start()
				return
	elif status.effect_name in active_statuses.keys():
		var old_effect = active_statuses[status.effect_name]
		if not old_effect or not (old_effect is StatusEffect):
			active_statuses.erase(status.effect_name)
		status = Globals.fuse_statuses(old_effect,status,self)
	
	var effect_timer = get_node_or_null(status.effect_name + "Duration")
	var step_timer = get_node_or_null(status.effect_name + "Step")
	
	if not effect_timer or not is_instance_valid(effect_timer):
		effect_timer = DataTimer.new()
		effect_timer.one_shot = true
		effect_timer.autostart = true
		effect_timer.wait_time = status.duration
		effect_timer.name = status.effect_name + "Duration"
		effect_timer.data = [status]
		print(effect_timer)
		add_child(effect_timer)
		print(effect_timer.get_path())
	
	if status.step_length > 0.0:
		if not step_timer or not is_instance_valid(step_timer):
			step_timer = DataTimer.new()
			step_timer.one_shot = false
			step_timer.autostart = true
			step_timer.wait_time = status.step_length
			step_timer.name = status.effect_name + "Step"
			step_timer.data = [status]
			print(step_timer)
			add_child(step_timer)
			print(step_timer.get_path())
	
	if effect_timer:
		if effect_timer.data != [status]:
			effect_timer.data = [status]
		if not (effect_timer.is_connected("arg_timeout",end_status)):
			effect_timer.arg_timeout.connect(end_status,4)
		if effect_timer.time_left < status.duration:
			effect_timer.wait_time = status.duration
			effect_timer.start()
	if step_timer:
		if step_timer.data != [status]:
			step_timer.data = [status]
		if not (step_timer.is_connected("arg_timeout",tick_status)):
			step_timer.arg_timeout.connect(tick_status)
		if step_timer.wait_time > status.step_length:
			step_timer.wait_time = status.step_length
			step_timer.start()
	
	apply_status(status)
	active_statuses[status.effect_name] = status
	effect_added.emit(status)
	

func apply_status(status : StatusEffect):
	if clear_in_progress:
		await clear_finished
	if status.slowdown:
		if heart.has_signal("speed_changed"):
			heart.speed_changed.emit()
	if status.gfx_scene_path and status.gfx_scene_path != "":
		var gfx = load(status.gfx_scene_path).instantiate()
		call_deferred("add_child",gfx)
		await gfx.tree_entered
		status.gfx_node_path = gfx.get_path()
	

func tick_status(data: Array): #array because thats what DataTimers give you
	var status = data[0]
	if not status is StatusEffect:
		return
	
	if clear_in_progress:
		await clear_finished
	if immunity and is_instance_valid(immunity):
		if immunity.is_immune_to(status.effect_name):
			return
	print(status.effect_name + " ticked!")
	
	if status.damage and hp:
		var damage = status.damage
		if status.stackable and status.stack > 0:
			damage *= status.stack
		print("ticked " + status.effect_name + " for ",damage)
		hp.damage(damage)
	
func end_status(data: Array):
	var status = data[0]
	if not status is StatusEffect:
		return
	
	var effect_timer = get_node_or_null(status.effect_name + "Duration")
	var step_timer = get_node_or_null(status.effect_name + "Step")
	
	if effect_timer:
		effect_timer.queue_free()
	if step_timer:
		step_timer.queue_free()
	
	if status.gfx_node_path:
		var gfx = get_node_or_null(status.effect_name + "GFX")
		if gfx and is_instance_valid(gfx):
			gfx.queue_free()
			status.gfx_node_path = ""
	
	active_statuses.erase(status.effect_name)
	if heart.has_signal("speed_changed"):
		heart.speed_changed.emit()
	
	effect_ended.emit(status)

func cull_timers():
	for x in get_children():
		if x is Timer and x != $CullTimer and not (x.name.substr(0,x.name.length() - 6)) in active_statuses.keys() and not (x.name.substr(0,x.name.length() - 4)) in active_statuses.keys():
			x.queue_free()

func cull_gfx(status):
	for x in get_children():
		if x.name == status.effect_name + "GFX":
			x.queue_free()

func clear_statuses():
	clear_in_progress = true
	for x in active_statuses.values():
		end_status(x)
	for x in active_statuses.keys():
		active_statuses.erase(x)
	cull_timers()
	clear_finished.emit()

func disable():
	clear_statuses()
	queue_free()
