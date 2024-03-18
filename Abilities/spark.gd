extends RigidBody2D
class_name Spark

@onready var ThrowTime = $ThrowTime
@onready var area = $Area2D
@export var source : PhysicsBody2D

var attack = Attack.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	ThrowTime.start()
	await ThrowTime.timeout
	var detected = area.get_overlapping_bodies()
	for x in detected:
		if x is Spark:
			createBeam(x)

func setupAttack():
	attack.attack_damage = 2.5
	attack.knockback_force = 0
	attack.canIgnite = true

func createBeam(target):
	var laser = LaserBeam.new()
	add_child(laser)
	laser.points = PackedVector2Array([global_position, target.global_position])
	laser.collided.connect(onHit)

func onHit(position, collider, normal_vector):
	var hitbox : HitboxComponent
	var children_list = collider.get_children()
	for x in children_list:
		if x is HitboxComponent:
			hitbox = x
	print("hit" + collider.name)
	hitbox.damage(attack)
