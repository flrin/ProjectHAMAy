extends Node2D

class_name AttackPart

@export var attack_duration :float
@export var hurtbox :Array[CollisionShape2D]
@export var attack_position :Vector2

func _ready():
	pass

func start_attack_part(attacker):
	var layer_list = []
	var mask_list = []
	
	match attacker:
		"player":
			layer_list = [7]
			mask_list = [3]
		"enemy":
			layer_list = [8]
			mask_list = [2]
	
	for i in range(0,len(hurtbox)):
		var new_area_node = Area2D.new()
		
		set_collisions_null(new_area_node)
		set_collision_layer_from_list(layer_list, true, new_area_node)
		set_collision_mask_from_list(mask_list, true, new_area_node)
		
		add_child(new_area_node)
		hurtbox[i].reparent(new_area_node, false)
		hurtbox[i].disabled = false
		new_area_node.add_to_group("attack")

func stop_attack_part():
	queue_free()

func set_collision_mask_from_list(list_to_set, value, object): #value e ori true ori false
	for i in list_to_set:
		object.set_collision_mask_value(i, value)

func set_collision_layer_from_list(list_to_set, value, object): #value e ori true ori false
	for i in list_to_set:
		object.set_collision_layer_value(i, value)

func set_collisions_null(object):
	for i in range(1,13):
		object.set_collision_mask_value(i, false)
		object.set_collision_layer_value(i, false)
