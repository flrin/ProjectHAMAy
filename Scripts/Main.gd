extends Node

var save_manager = SaveManager.new()

func _ready():
	save_manager.get_ready(self)

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_save"):
		save_manager.save_game()
	if Input.is_action_just_pressed("ui_load"):
		save_manager.load_game()
