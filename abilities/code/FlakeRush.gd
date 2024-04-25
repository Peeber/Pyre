extends ContactDamage

var damage : float = 20.0
var force : float = 15.0
var interrupted = false
var is_ai : bool = false
var dash_length = 0.75
var original_speed : float

var resource = load("res://abilities/resources/Heart of Desire/Flake Rush.tres")

signal dash_ended
signal first_hit

func _on_first_hit():
	caster.stun(2.5)
	interrupted = true

func _ready():
	if !SignalBus.is_connected("abilityCast",on_cast):
		SignalBus.abilityCast.connect(on_cast)
	caster = get_parent()

func _on_area_entered(area):
	if area.get_parent() == caster or !(area is HitboxComponent):
		return
	if attack:
		hit(area)
	first_hit.emit()

func build_attack():
	if attack and attack.attack_damage:
		return
	else:
		attack = load("res://resources/Attack.tres")
		attack.attack_damage = damage
		attack.source = caster.get_path()
		attack.knockback_force = force

func on_cast(source, ability, target):
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
	build_attack()
	enable(attack)
	print(caster.name + " beginning chain dash")
	chain_dash()

func chain_dash():
	interrupted = false
	original_speed = caster.speed
	if !is_ai:
		caster.movement_override = true
	for x in 3:
		if interrupted:
			end()
			return
		await dash_ended
		dash()
	end()

func dash():
	caster.speed = 200
	if is_ai:
		caster.switch_move_mode("seek")
	dash_ended.emit()

func end():
	if caster.has_signal("action_ended"):
		caster.action_ended.emit()
	disable()
	caster.speed = original_speed
	caster.movement_override = false
	queue_free()
