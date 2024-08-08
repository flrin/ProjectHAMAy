extends Camera2D

var player
var DEFAULT_OFFSET = Vector2(0, -92)
var is_up = false
var saved_player_pos = Vector2(0,0)
var delta_time
var rng = RandomNumberGenerator.new()
var shake_offset = Vector2(0,0)
var shake_frequency = 1
var shake_power = 1
var new_shake_offset = Vector2(0,0)
var shake_duration = 0

var new_position
var old_position
var is_moving = false

# Called when the node enters the scene tree for the first time.
func _ready():
	player = $".."


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	delta_time = delta
	offset -= shake_offset
	if is_moving:
		if snapped(offset.x,0.1) == 0 and snapped(offset.y,0.1) == 0:
			is_moving = false
		else:
			offset.x = lerpf(offset.x, 0, delta * 5)
			offset.y = lerpf(offset.y, 0, delta * 5)
	else:
		if is_instance_valid(player) and player.is_grabbing == false:
			var player_vel_vector = player.velocity
			offset.x = lerpf(offset.x, player_vel_vector.x * 0.2, delta * 2.5)
			
			if player.player_state == player.player_states.CLIMBING:
				offset.y = lerpf(offset.y, player_vel_vector.y * 0.2, delta * 2.5)
				saved_player_pos.y = player.position.y
			else:
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
							offset.y = lerpf(offset.y, player_vel_vector.y * 0.2, delta * 5)
						else:
							offset.y = lerpf(offset.y, saved_player_pos.y - player.position.y + 5.8, delta * 5) # nu vrei sa sti ce e 5.8
	
	shake_camera()
	
	offset += shake_offset

func player_hit(attack):
	shake_frequency = 5
	shake_duration = .1
	shake_power = 5

func shake_camera():
	if shake_duration > 0:
		if abs(shake_offset.x - new_shake_offset.x) <= 0.5 and abs(shake_offset.y - new_shake_offset.y) <= 0.5:
			new_shake_offset = Vector2(randf_range(-1,1), randf_range(-1,1)) * shake_power
		shake_offset.x = lerpf(shake_offset.x, new_shake_offset.x, delta_time * 20 * shake_frequency)
		shake_offset.y = lerpf(shake_offset.y, new_shake_offset.y, delta_time * 20 * shake_frequency)
	else:
		shake_offset.x = lerpf(shake_offset.x, 0, delta_time * 20 * shake_frequency)
		shake_offset.y = lerpf(shake_offset.y, 0, delta_time * 20 * shake_frequency)

	shake_duration -= delta_time

func move_to(new_pos, old_pos):
	new_position = new_pos
	old_position = old_pos
	offset -= new_pos - old_pos
	
	is_moving = true
