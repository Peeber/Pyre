extends Area2D
class_name HitboxComponent

@export var health_component : HealthComponent
@export var knockback_component : KnockbackComponent
@export var isImmune : bool = false #immune to damage
@export var isImmovable: bool = false #immune to knockback
signal immuneChanged(is_immune : bool)
signal hit
signal damaging_hit
signal knocking_hit

func damage(attack: Attack):
	hit.emit()
	if health_component and is_instance_valid(health_component) and not isImmune:
		health_component.damage(attack)
		damaging_hit.emit()
	if knockback_component and is_instance_valid(knockback_component) and not isImmovable:
		knockback_component.knockback(attack.source,attack.knockback_force,attack.knockback_direction)
		knocking_hit.emit()

func makeImmune(is_immune,duration : float):
	if isImmune == is_immune:
		return
	isImmune = is_immune
	immuneChanged.emit(isImmune)
	
	if duration and duration >= 0:
		var interrupted = false
		immuneChanged.connect(func(_immune):
			interrupted = true
		)
		
		var timer = Timer.new()
		add_child(timer)
		timer.one_shot = true
		timer.wait_time = duration
		timer.start()
		await timer.timeout
		
		if not interrupted:
			isImmune = !isImmune
			immuneChanged.emit(isImmune)
		
		timer.queue_free()
		
