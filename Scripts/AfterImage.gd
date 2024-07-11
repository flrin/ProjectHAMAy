extends Node2D

var resource
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_ready(res, pos):
	resource = res
	
	var model_sprite = Sprite2D.new()
	model_sprite.texture = resource
	
	add_child(model_sprite)
	
	position = pos
	model_sprite.position.y = -model_sprite.texture.get_height()/2
	
	model_sprite.modulate = Color(0.523,1,1,0.523)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_timer_timeout():
	queue_free()
