extends Camera2D

var player
var DEFAULT_OFFSET = Vector2(0, -92)
var is_up = false
var saved_player_pos = Vector2(0,0)

var is_in_follow_state = false

# Called when the node enters the scene tree for the first time.
func _ready():
	player = $".."


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var player_vel_vector = player.velocity
	offset.x = lerpf(offset.x, player_vel_vector.x * 0.2, delta * 2.5)
	
	if player_vel_vector.y < 0: #urca
		if !is_up:
			is_up = true
			saved_player_pos = player.position
		else:
			offset.y = lerpf(offset.y, saved_player_pos.y - player.position.y + 5.8, delta * 5)
	
	if player.is_on_floor(): # sta pe loc (y)
		if is_up:
			is_up = false
			offset.y = lerpf(offset.y, saved_player_pos.y - player.position.y + 5.8, delta * 5)
		else:
			offset.y = lerpf(offset.y, player_vel_vector.y * 0.5, delta * 5)
	else:
		if player_vel_vector.y > 0: # cade
			if offset.y <= 0:
				is_up = false
			if !is_up:
				offset.y = lerpf(offset.y, player_vel_vector.y * 0.2, delta * 8)
			else:
				offset.y = lerpf(offset.y, saved_player_pos.y - player.position.y + 5.8, delta * 5) # nu vrei sa sti ce e 5.8
	
