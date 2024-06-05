extends ContactDamage

var damage : float = 15.0
var force : float = 300.0
var dash_length = 2
var original_speed : float
var is_ai : bool = false
var interrupted : bool = false

var resource = load("res://abilities/resources/Heart of Desire/Flake Homing Rush.tres")

func _ready():
	if hit_cd:
		hit_cd.queue_free()
	if monitorable:
		monitorable = false
	if !SignalBus.is_connected("abilityCast",on_cast):
		SignalBus.abilityCast.connect(on_cast)
	caster = get_parent()

func disable():
	set_deferred("monitoring" ,false)
	attack = null

func on_cast(source, ability, target, _is_ember):
	if source != caster or ability != resource:
		return
	if caster is Enemy:
		is_ai = true
		caster.move_target = target
	
	if SignalBus.is_connected("abilityCast",on_cast):
		SignalBus.abilityCast.disconnect(on_cast)
	
	if caster.get_node("HitboxComponent") and not shape:
		var hurtbox = caster.hitbox.get_node("CollisionShape2D")
		if not hurtbox:
			print("error: tried to create flake rush without a valid shape")
			return
		hurtbox = hurtbox.duplicate()
		hurtbox.scale *= 1.2
		add_child(hurtbox)
	print("building attack")
	if not attack:
		attack = build_attack()
	print(caster.name + " beginning homing charge")
	dash()
	
func dash():
	original_speed = caster.speed
	if !is_ai:
		if "movement_override" in caster:
			caster.movement_override = true
	if "stunned" in caster:
		if caster.stunned:
			await caster.stun_ended
	caster.speed = 400
	if is_ai:
		caster.switch_move_mode("seek_homing")
	enable(attack)
		
	print("starting dash")
	if is_ai:
		if caster.move_mode != "seek_homing" and not caster.movement_override:
			caster.switch_move_mode("seek_homing")
			await caster.swapped_move_mode
	await get_tree().create_timer(dash_length).timeout
	print("dash over")
	if !interrupted:
		end()
	
func _on_area_entered(area):
	print(area.name)
	if area.get_parent() == caster or !(area is HitboxComponent):
		return
	interrupted = true
	if attack:
		hit(area)
	else:
		print("flake homing rush had no attack, aborting")
	end()
	
func build_attack():
	var standard_attack = Attack.new()
	standard_attack.attack_damage = damage
	standard_attack.source = caster.get_path()
	standard_attack.knockback_force = force
	return standard_attack

func hit(area):
	if caster and caster != self:
		var generalized_velocity = Physics.get_generalized_velocity(caster)
		if generalized_velocity != Vector2.ZERO:
			attack.knockback_direction = generalized_velocity.normalized()
	area.damage(attack)

func end():
	caster.speed = original_speed
	caster.stun(3)
	if caster.has_signal("action_ended"):
		caster.action_ended.emit()
	if "movement_override" in caster:
		caster.movement_override = false
	if is_ai:
		caster.switch_move_mode("stationary")
	disable()
	queue_free()
	
