extends Node2D

var resource

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func get_ready(res, pos, faceing_direction):
	resource = res
	scale.x=faceing_direction
	var model_sprite = Sprite2D.new()
	model_sprite.texture = resource
	
	add_child(model_sprite)
	
	position = pos
	model_sprite.position.y = -model_sprite.texture.get_height()/2
	model_sprite.modulate = Color(0.43,0.1,0.03,0.423)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_timer_timeout():
	queue_free()
