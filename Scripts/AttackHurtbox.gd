extends Node2D

@export var attack_parts :Array[AttackPart] 

var stopwatch = 0
var attack_counter = 0
@onready var attacker

func _ready():
	for attack in attack_parts:
		attack.position = attack.attack_position
	attack_parts[attack_counter].start_attack_part(attacker)
	

func _physics_process(delta):
	if stopwatch >= attack_parts[attack_counter].attack_duration:
		attack_parts[attack_counter].stop_attack_part()
		attack_counter += 1
		if attack_counter == len(attack_parts):
			queue_free()
		else:
			attack_parts[attack_counter].start_attack_part(attacker)
		
		stopwatch = 0
		
	stopwatch += delta

func set_attacker(att):
	attacker = att
