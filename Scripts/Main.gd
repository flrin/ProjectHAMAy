extends Node

var save_manager = SaveManager.new()
var player 

func _ready():
	player = $Player
	player.on_load()
	
	save_manager.get_ready(self)

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_save"):
		save_manager.save_game()
	if Input.is_action_just_pressed("ui_load"):
		save_manager.load_game()
		var camera = get_tree().get_nodes_in_group("camera")
		camera[0].queue_free()
