extends Node2D

@export var attack_name = ""

func get_ready(attacker):
	var attack_hurtbox = $AttackHurtbox
	attack_hurtbox.set_attacker(attacker)
