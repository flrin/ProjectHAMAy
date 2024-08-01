extends Node2D


func get_ready(attacker):
	var attack_hurtbox = $AttackHurtbox
	attack_hurtbox.set_attacker(attacker)
