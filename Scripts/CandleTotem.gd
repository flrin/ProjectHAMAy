extends Node2D

var detection_area
var button
var npc_name
var has_been_used = false
var fire_particles

# Called when the node enters the scene tree for the first time.
func _ready():
	detection_area = $Area2D
	button = $E
	set_npc_name("candle_totem")
	add_to_group("npc")
	fire_particles = $CPUParticles2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_accept") and button.visible == true:
		has_been_used = true
	if has_been_used == true:
		fire_particles.emitting = false


func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		button.visible = true


func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		button.visible = false

func set_npc_name(new_name):
	npc_name = new_name

func get_npc_name():
	return npc_name
