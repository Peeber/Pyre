extends Node
class_name ImmunityComponent

signal immune_changed(immunity_type : String,is_immune : bool)
var immunity_list : Array = []

func is_immune_to(immunity_type : String):
	if immunity_type.to_lower() in immunity_list:
		return true
	else:
		return false

func apply_immunity_change(immunity_type : String, is_immune : bool):
	immunity_type = immunity_type.to_lower()
	if is_immune:
		if !(immunity_type in immunity_list):
			immunity_list.append(immunity_type)
	else:
		if immunity_type in immunity_list:
			immunity_list.remove_at(immunity_list.find(immunity_type))
	immune_changed.emit(immunity_type, is_immune)

func make_immune_to(immunity_type : String, is_immune : bool = true, duration : float = 0):
	if is_immune_to(immunity_type) == is_immune:
		return
	
	if duration and duration > 0:
		if immunity_type in immunity_list:
			var current_timer = get_node(immunity_type + "ImmunityTimer")
			if current_timer.wait_time < duration:
				current_timer.wait_time = duration
		else:
			var timer = Timer.new()
			timer.one_shot = true
			timer.wait_time = duration
			add_child(timer)
			timer.name = immunity_type + "ImmunityTimer"
			print(timer, timer.name, timer.wait_time)
			timer.start()
			await timer.timeout.connect(func():
				apply_immunity_change(immunity_type,!is_immune)
				timer.queue_free()
			)
	apply_immunity_change(immunity_type,is_immune)

