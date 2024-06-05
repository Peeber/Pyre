extends ContactDamage

var damage : float = 20.0
var force : float = 400.0
var interrupted = false
var is_ai : bool = false
var dash_length = 1.5
var original_speed : float

var resource = load("res://abilities/resources/Heart of Desire/Flake Rush.tres")

signal dash_ended
signal first_hit

func _on_first_hit():
	caster.stun(2.5)
	interrupted = true

func _ready():
	if not hit_cd:
		hit_cd = $Timer
	if monitorable:
		monitorable = false
	if !SignalBus.is_connected("abilityCast",on_cast):
		SignalBus.abilityCast.connect(on_cast)
	caster = get_parent()

func _on_area_entered(area):
	print(area.name)
	if area.get_parent() == caster or !(area is HitboxComponent):
		return
	if attack:
		hit(area)
	first_hit.emit()

func build_attack():
	var standard_attack = Attack.new()
	standard_attack.attack_damage = damage
	standard_attack.source = caster.get_path()
	standard_attack.knockback_force = force
	return standard_attack

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
	enable(attack)
	print(caster.name + " beginning chain dash")
	chain_dash()

func chain_dash():
	interrupted = false
	original_speed = caster.speed
	if !is_ai:
		if "movement_override" in caster:
			caster.movement_override = true
	print("starting chain dash loop")
	for x in 3:
		print("dash ",x)
		if interrupted:
			break
		if x > 0:
			await dash_ended
		dash()
	end()

func dash():
	caster.speed = 400
	if is_ai:
		caster.switch_move_mode("seek")
	print("starting dash")
	await get_tree().create_timer(dash_length).timeout
	print("dash over")
	if is_ai:
		caster.switch_move_mode("stationary")
	await get_tree().create_timer(0.1).timeout
	dash_ended.emit()

func end():
	if caster.has_signal("action_ended"):
		caster.action_ended.emit()
	disable()
	caster.speed = original_speed
	if "movement_override" in caster:
		caster.movement_override = false
	queue_free()
