extends CharacterBody2D
class_name Enemy

@export var hitbox : HitboxComponent
@export var hp : HealthComponent
@export var death_function : Callable
@export var act_mode : String = "none"
@export var move_mode : String = "stationary"
signal ready_to_free
var movelist : Array[Ability]= []
var mulligan = false #prevents it from dying

var death_mode = func():
	print(name + "has died")
	if death_function:
		death_function.call()
		await ready_to_free
	if not mulligan:
		self.queue_free()

var seek_mode = func(speed : int, aggression : int, intelligence : int, target):
	pass

var stay_mode = func(duration : float):
	pass

var move_modes = {
	"death" = death_mode,
	"seek" = seek_mode,
	"stationary" = stay_mode,
}

var random_attack_mode = func():
	pass

var act_modes = {
	"none" = null,
	"random_attack" = random_attack_mode,
	
}

func switch_move_mode(mode : String):
	move_mode = mode
	#make it check if its valid

func switch_act_mode(mode : String):
	act_mode = mode

func death():
	switch_move_mode("death")
	switch_act_mode("none")

func build():
	if not hitbox:
		for x in get_children():
			if x is HitboxComponent:
				hitbox = x
	if not hp:
		for x in get_children():
			if x is HealthComponent:
				hp = x
	if not hp or not hitbox:
		print(name + " has been created without the required components and will be invulnerable (and might crash the game)")
	hp.heartKilled.connect(death)
	pass
