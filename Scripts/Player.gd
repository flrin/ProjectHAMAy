extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const DODGE_ACCELERATION = 5
const PUSHBACK_SPEED  = 300
const AFTERIMAGE_NUMBER = 5
const AFTERIMAGE_FREQ = 0.01
const DEFAULT_SLOW_DOWN = 1
const DEFAULT_ATTACK_DECELERATION = 3
const CLIMBING_SPEED = -300

signal damage_taken(attack)
signal interacted_with_npc(npc)

# Get the gravity from the project settings to be synced with RigidBody nodes.

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dodge_accel = 1
var collision_shape
var hitbox_area
var is_pushed = false
var heart_ammount
var player_model = load("res://Assets/Characters/PlayerCharacter.png")
var afterimage_scene = load("res://Scenes/AfterImage.tscn")
var afterimage_timer
var ui
var afterimage_count = 10
var tilemap
var animation
var fake_direction = 1
var jump_counter = 1
var pushback_timer
var dodge_count = 0
var camera
var is_reading = false
var is_attacking = false

var hurtbox_node
var atttack_slow_down

var grab_ray_cast
var grab_check_ray_cast
var is_grabbing=false

var current_animation = "walk"

var attack1_hurtbox_scene = load("res://Scenes/PlayerAttack1.tscn")
var attack2_hurtbox_scene = load("res://Scenes/PlayerAttack2.tscn")

var attack_deceleration = DEFAULT_ATTACK_DECELERATION

var stun_duration = 0.3

var player_state = player_states.IDLE

enum player_states {
	ATTACKING,
	IDLE,
	RUNNING,
	JUMPING,
	LANDING,
	WALKING,
	DODGING,
	CLIMBING,
	NONE
}

func _ready():
	atttack_slow_down = 1
	camera = $Camera2D
	animation = $AnimatedSprite2D #animation
	animation.animation = current_animation
	collision_shape = $CollisionShape2D
	hitbox_area = $HitboxArea
	ui = get_node("../UI/UI")
	damage_taken.connect(ui.change_health)
	set_collision_mask_from_list([2,3,4,5], true)
	afterimage_timer = $AfterimageTimer
	tilemap=get_node("../TileMap")
	pushback_timer = $PushbackTimer
	grab_check_ray_cast = $GrabCheckRayCast
	grab_ray_cast = $GrabRayCast
	interacted_with_npc.connect(ui.interacted_with_npc)
	heart_ammount = 4
	damage_taken.connect(camera.player_hit)
	
func _physics_process(delta):
	print(player_states.keys()[player_state])
	
	#Process collisions

	# Add the gravity.
	if not is_on_floor():
		if is_pushed == false:
			velocity.y += gravity * delta
			if velocity.y > 0 and player_state != player_states.JUMPING and player_state != player_states.CLIMBING and velocity.y > 100:
				play_animation("jump")
				player_state = player_states.JUMPING
		else:
			velocity.y += gravity * delta * 2
	
	#Handle ladder climbing
	if is_on_ladder():
		if Input.is_action_pressed("ui_up"):
			velocity.y = CLIMBING_SPEED
			player_state = player_states.CLIMBING
		else:
			if Input.is_action_pressed("ui_down"):
				velocity.y = -CLIMBING_SPEED
				player_state = player_states.CLIMBING
			else:
				if player_state == player_states.CLIMBING:
					velocity.y = 0
	else:
		if player_state == player_states.CLIMBING:
			player_state = player_states.NONE 
			check_available_state()
	
	#Handle attack
	if !is_grabbing:
		if player_state != player_states.ATTACKING and player_state != player_states.JUMPING:
			if Input.is_action_just_pressed("ui_click"):
				play_animation("attack1")
				atttack_slow_down = DEFAULT_SLOW_DOWN
				attack_deceleration = DEFAULT_ATTACK_DECELERATION
				player_state = player_states.ATTACKING
				
				is_attacking = true
				hurtbox_node = attack1_hurtbox_scene.instantiate()
				hurtbox_node.get_ready("player")
				add_child(hurtbox_node)

			if Input.is_action_just_pressed("ui_1"):
				play_animation("attack2")
				atttack_slow_down = DEFAULT_SLOW_DOWN
				attack_deceleration = DEFAULT_ATTACK_DECELERATION * .01
				player_state = player_states.ATTACKING
			
				is_attacking = true
				hurtbox_node = attack2_hurtbox_scene.instantiate()
				hurtbox_node.get_ready("player")
				add_child(hurtbox_node)
	
	
	if player_state == player_states.ATTACKING:
		if velocity.y > 50 and is_instance_valid(hurtbox_node):
			hurtbox_node.queue_free()
			hurtbox_node = null
			is_attacking = false
			atttack_slow_down = 1
		
	
	if player_state == player_states.ATTACKING and is_attacking:
		atttack_slow_down = lerpf(atttack_slow_down, 0, delta * attack_deceleration)
	else:
		atttack_slow_down = 1
	
	#Handle interact
	if Input.is_action_just_pressed("ui_interact") and !is_reading:
		var temp_npc = look_for_group("npc")
		if temp_npc:
			emit_signal("interacted_with_npc", temp_npc)
			is_reading = true
			match temp_npc.get_npc_name():
				"cat":
					pass
				"candle_totem":
					if temp_npc.has_been_used == false:
						ui.change_max_health(1)
						heart_ammount += 1

	# Handle jump.
	if !is_pushed and !is_reading and !is_attacking:
		if is_on_floor():
			if Input.is_action_just_pressed("ui_accept"):
				if jump_counter > 0 and !Input.is_action_pressed("ui_down"):
					velocity.y = JUMP_VELOCITY
					jump_counter -= 1
					play_animation("jump")
					player_state = player_states.JUMPING
			else:
				jump_counter = 1
		else:
			if Input.is_action_just_pressed("ui_accept") and is_pushed == false:
				if jump_counter > 1:
					velocity.y = JUMP_VELOCITY
					jump_counter -= 1
					play_animation("jump")
					player_state = player_states.JUMPING
	
	if player_state == player_states.JUMPING:
		hitbox_area.get_node("CollisionShape2D").shape.height = 20
		if is_on_floor() and !animation.is_playing():
			play_animation("land")
			player_state = player_states.LANDING
	else:
		hitbox_area.get_node("CollisionShape2D").shape.height = 48
	
	#if Input.is_action_just_pressed("ui_accept") and ((is_on_floor() or jump_counter > 0) and !Input.is_action_pressed("ui_down")) and is_pushed == false:
		#velocity.y = JUMP_VELOCITY
		#jump_counter -= 1
		
	#Handle ledge grab
	_check_ledge_grab()
	if !is_pushed and !is_reading and !is_attacking:
			if Input.is_action_just_pressed("ui_accept") and (is_on_floor() || is_grabbing) && !Input.is_action_pressed("ui_down"):
				is_grabbing=false
				velocity.y = JUMP_VELOCITY
				player_state = player_states.NONE
				check_available_state()
			if is_grabbing : return #daca nu intelegi ce face asta da stiu ca intelegi ca esti baiat destept da freez la caracter mid air il fac sa iasa din functie si pe scurt nu ii se mai aplica nimic din _physics_process . tot cce poate face e sa sara codu de deasupra sau sa stea pe viata agatat din cauza ca nu poate face altceva pe scurt asta e tot codu de stat in aer lmao
	#Handle dodge
	if dodge_accel == 1:
		if Input.is_action_just_pressed("ui_dodge") and is_on_floor() and player_state != player_states.ATTACKING and !is_reading:
			if is_pushed == false:
				dodge_accel = DODGE_ACCELERATION
				set_collision_mask_from_list([2,3,4,5], false)
				set_collision_layer_value(2,false)
				hitbox_area.set_deferred("monitoring", false) 
				start_afterimage()
				dodge_count = 1
				modulate = Color(0.43,0.1,0.03,0.823)
				player_state = player_states.DODGING
		else:
			if dodge_count == 1:
				set_collision_mask_from_list([2,3,4,5], true)
				set_collision_layer_value(2,true)
				hitbox_area.set_deferred("monitoring", true) 
				set_color_default()
				dodge_count = 0
				player_state = player_states.NONE
				check_available_state()
	else:
		dodge_accel -= 0.5

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != fake_direction and direction and is_pushed == false:
		scale.x *= -1
		fake_direction = direction
		
	if player_state == player_states.WALKING:
		if direction == 0: #trebe animatie de idle cand cacam
			animation.stop()
			player_state = player_states.IDLE
		
	if is_pushed == false:
		if direction and (!is_attacking or !is_on_floor()):
			velocity.x = direction * SPEED * dodge_accel * atttack_slow_down
			if  player_state == player_states.IDLE:
				player_state = player_states.WALKING
				play_animation("walk")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED * delta * 18.25)
	else:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, SPEED * delta * 18.25)

	if snapped(velocity.x,0.01) == 0 and snapped(velocity.y,0.01) == 0 and is_pushed == true and pushback_timer.is_stopped():
		pushback_timer.start(0.3)
	
	fall_down_ledge() #nus unde vrei sa lasi asta
	
	move_and_slide()
	

func set_collision_mask_from_list(list_to_set, value): #value e ori true ori false
	for i in list_to_set:
		set_collision_mask_value(i, value)

func take_damage(attack : Attack):
	#Flash the character white
	modulate = Color(2, 2, 2, 0.8)
	
	#Emit signal
	emit_signal("damage_taken", attack)
	
	#Push back the player
	var pushback_direction = position - attack.attack_position
	pushback_direction = pushback_direction.normalized()
	pushback_direction.x *= 1.5
	pushback_direction.y *= 0.5
	velocity = pushback_direction * PUSHBACK_SPEED * attack.knockback_power
	is_pushed = true
	stun_duration = attack.stun_duration
	
	set_collision_mask_from_list([2,3,4,5], false)
	hitbox_area.set_deferred("monitoring", false) 


	#Substract hearts
	heart_ammount -= attack.attack_damage
	if heart_ammount <= 0:
		game_over()

func game_over():
	camera.reparent(get_node(".."))
	queue_free()

func _on_hitbox_area_entered(area):
	if area.get_parent().is_in_group("npc"):
		pass
	else:
		if !is_pushed:
			var enemy_attack
			if area.get_parent().has_method("get_attack"):
				enemy_attack = area.get_parent().get_attack()
				take_damage(enemy_attack)
			else:
				if area.get_node("../../../..").has_method("get_attack"):
					enemy_attack = area.get_node("../../../..").get_attack()
					take_damage(enemy_attack)

func _on_hitbox_body_entered(body):
	if body.is_in_group("npc"):
		pass
	else:
		if !is_pushed and body.has_method("get_attack"):
			pass
			#var enemy_attack = body.get_attack()
			#take_damage(enemy_attack)

func start_afterimage():
	if afterimage_count == 0:
		afterimage_count = AFTERIMAGE_NUMBER
	var afterimage_node = afterimage_scene.instantiate()
	afterimage_node.get_ready(get_current_frame(), position, fake_direction)
	get_node("..").add_child(afterimage_node)
	
	afterimage_count -= 1
	afterimage_timer.start(AFTERIMAGE_FREQ)

func _on_afterimage_timer_timeout():
	if afterimage_count > 0:
		var afterimage_node = afterimage_scene.instantiate()
		afterimage_node.get_ready(get_current_frame(), position, fake_direction)
		get_node("..").add_child(afterimage_node)
		
		afterimage_count -= 1
		afterimage_timer.start(AFTERIMAGE_FREQ * AFTERIMAGE_NUMBER/afterimage_count)
	else:
		afterimage_count = AFTERIMAGE_NUMBER

func drop_down_ledge():
	position.y += 3
	grab_check_ray_cast.enabled=false
	
func fall_down_ledge():
	var tile_coords=tilemap.local_to_map(tilemap.to_local(global_position))
	var data = tilemap.get_cell_tile_data(1,tile_coords) #1 e layer-u daca vrei sa iei datele de la alte layer numa schimba aia (daca vrei sa detectezi daca stai pe pamant de exmplu sau pe piatra)
	if data:
		var type = data.get_custom_data("type")
		if type == "ledge_1" && is_on_floor() && Input.is_action_pressed("ui_down") && Input.is_action_just_pressed("ui_space"): #daca o sa avem mai multe tipuri de ledge-uri o sa lasam numa in caz general si le numim pe toate ledge xD ca sa nu ne batem capu cu ledge_1&&ledge_2 etc
			drop_down_ledge()

func set_color_default():
	modulate = Color(1,1,1,1)

func _on_pushback_timer_timeout():
	if is_pushed == true:
		is_pushed = false
		pushback_timer.start(0.3)
	else:
		set_color_default()
		set_collision_mask_from_list([2,3,4,5], true)
		hitbox_area.set_deferred("monitoring", true)

func look_for_group(group):
	for i in hitbox_area.get_overlapping_areas():
		if i.get_parent().is_in_group(group):
			return i.get_parent()
	for i in hitbox_area.get_overlapping_bodies():
		if i.is_in_group(group):
			return i
	
	return false

func text_ended():
	is_reading = false

func _on_animated_sprite_2d_animation_finished():
	if player_state == player_states.ATTACKING or player_state == player_states.LANDING:
		player_state = player_states.NONE
		check_available_state()
		is_attacking = false
		atttack_slow_down = 1

func _check_ledge_grab():
	var is_falling = velocity.y >= 0
	var check_hand = not grab_ray_cast.is_colliding() 
	var check_grabbing_height = grab_check_ray_cast.is_colliding()
	var tile = grab_check_ray_cast.get_collision_point()
	var can_grab = is_falling && check_hand && check_grabbing_height && not is_grabbing && (_check_ledge_one_way_grab(tile) || is_on_wall_only()) #sterge && is_on_wall_only() ca sa nu trebuiasca a si d
	
	if can_grab:
		is_grabbing = true
		play_animation("hang")
		#
		#animatie de ledge climb play
		#
		
	if is_on_floor():
		grab_check_ray_cast.enabled=true
	
func _check_ledge_one_way_grab(tile):
	var tile_coords=tilemap.local_to_map(tilemap.to_local(tile))
	var player_coords=tilemap.local_to_map(tilemap.to_local(global_position))
	if tile.x < global_position.x:
		tile_coords.x=tile_coords.x-1
	if player_coords.y > 0:
		player_coords.y = player_coords.y + 1
	else :
		player_coords.y = player_coords.y - 1
	var data = tilemap.get_cell_tile_data(1,tile_coords)
	var data_player = tilemap.get_cell_tile_data(1,player_coords)
	if data:
		var type = data.get_custom_data("Margine")
		if !data_player:
			if type == true :
				grab_check_ray_cast.enabled=false
				return true
func get_current_frame():
	var frame_index = animation.get_frame()
	var animation_sprite_frames = animation.get_sprite_frames()
	return animation_sprite_frames.get_frame_texture(current_animation, frame_index)

func play_animation(new_anim):
	current_animation = new_anim
	animation.animation = current_animation
	animation.play()

func get_attack(attack_name):
	var new_attack = Attack.new()
	match attack_name:
		"attack1":
			new_attack.attack_damage = 10
			new_attack.attack_position = global_position
			return new_attack
		"attack2":
			new_attack.knockback_power = 1
			new_attack.attack_position = global_position
			return new_attack

func is_on_ladder():
	var player_coords=tilemap.local_to_map(tilemap.to_local(global_position))
	player_coords.y += -1
	var data_player = tilemap.get_cell_tile_data(2,player_coords)
	if data_player:
		var type = data_player.get_custom_data("type")
		return type == "ladder"

func check_available_state():
	#Handle states
	if player_state == player_states.NONE:
		if is_on_floor():
			player_state = player_states.IDLE
		else:
			player_state = player_states.JUMPING
			play_animation("jump")
