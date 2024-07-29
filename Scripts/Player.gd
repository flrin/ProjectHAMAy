extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const DODGE_ACCELERATION = 5
const PUSHBACK_SPEED  = 300
const AFTERIMAGE_NUMBER = 5
const AFTERIMAGE_FREQ = 0.01
const DEFAULT_SLOW_DOWN = 1

signal damage_taken(ammount)
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
var walking_animation_frames
var jump_counter = 1
var pushback_timer
var dodge_count = 1
var camera
var is_reading = false
var is_attacking = false
var hurtbox_area_scene = load("res://Scenes/HurtBox1.tscn")
var hurtbox_node
var atttack_slow_down

var grab_ray_cast
var grab_check_ray_cast
var is_grabbing=false

var current_animation = "walk"

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
	walking_animation_frames = animation.get_sprite_frames()
	pushback_timer = $PushbackTimer
	grab_check_ray_cast = $GrabCheckRayCast
	grab_ray_cast = $GrabRayCast
	interacted_with_npc.connect(ui.interacted_with_npc)
	heart_ammount = 4
	
func _physics_process(delta):
	#Process collisions

	# Add the gravity.
	if not is_on_floor():
		if is_pushed == false:
			velocity.y += gravity * delta
		else:
			velocity.y += gravity * delta * 2
	
	#Handle attack
	if !is_grabbing:
		if animation.get_animation() != "attack" and Input.is_action_just_pressed("ui_click"):
			animation.set_animation("attack")
			current_animation = "attack"
			animation.play()
			atttack_slow_down = DEFAULT_SLOW_DOWN
	
	if animation.get_animation() == "attack":
		if animation.frame == 5 and hurtbox_node == null:
			is_attacking = true
			hurtbox_node = hurtbox_area_scene.instantiate()
			add_child(hurtbox_node)
		if animation.frame == 9 and is_instance_valid(hurtbox_node):
			hurtbox_node.queue_free()
			hurtbox_node = null
			is_attacking = false
			atttack_slow_down = 1
	
	if animation.get_animation() == "attack":
		atttack_slow_down = lerpf(atttack_slow_down, 0, delta * 3)
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
					animation.animation = "jump"
					current_animation = "jump"
					animation.play()
			else:
				jump_counter = 1
		else:
			if Input.is_action_just_pressed("ui_accept") and is_pushed == false:
				if jump_counter > 1:
					velocity.y = JUMP_VELOCITY
					jump_counter -= 1
					animation.animation = "jump"
					current_animation = "jump"
					animation.play()
	
	if current_animation == "jump":
		hitbox_area.get_node("CollisionShape2D").shape.height = 30
		if is_on_floor() and !animation.is_playing():
			current_animation = "land"
			animation.animation = current_animation
			animation.play()
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
			if is_grabbing : return #daca nu intelegi ce face asta da stiu ca intelegi ca esti baiat destept da freez la caracter mid air il fac sa iasa din functie si pe scurt nu ii se mai aplica nimic din _physics_process . tot cce poate face e sa sara codu de deasupra sau sa stea pe viata agatat din cauza ca nu poate face altceva pe scurt asta e tot codu de stat in aer lmao
	#Handle dodge
	if dodge_accel == 1:
		if Input.is_action_just_pressed("ui_dodge") and is_on_floor() and animation.animation != "attack" and !is_reading:
			if is_pushed == false:
				dodge_accel = DODGE_ACCELERATION
				set_collision_mask_from_list([2,3,4,5], false)
				set_collision_layer_value(2,false)
				hitbox_area.set_deferred("monitoring", false) 
				start_afterimage()
				dodge_count = 1
				modulate = Color(0.43,0.1,0.03,0.823)
		else:
			if dodge_count == 1:
				set_collision_mask_from_list([2,3,4,5], true)
				set_collision_layer_value(2,true)
				hitbox_area.set_deferred("monitoring", true) 
				set_color_default()
				dodge_count = 0
	else:
		dodge_accel -= 0.5

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != fake_direction and direction and is_pushed == false:
		scale.x *= -1
		fake_direction = direction
		
	if animation.get_animation() == "walk":
		if direction == 0: #trebe animatie de idle cand cacam
			animation.stop()
		else :
			animation.play()
		
	if is_pushed == false:
		if direction and (!is_attacking or !is_on_floor()):
			velocity.x = direction * SPEED * dodge_accel * atttack_slow_down
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

func take_damage(ammount, hit_position):
	#Flash the character white
	modulate = Color(2, 2, 2, 0.8)
	
	#Emit signal
	emit_signal("damage_taken", ammount)
	
	#Push back the player
	var pushback_direction = position - hit_position
	pushback_direction = pushback_direction.normalized()
	pushback_direction.x *= 1.5
	pushback_direction.y *= 0.5
	velocity = pushback_direction * PUSHBACK_SPEED
	is_pushed = true
	
	set_collision_mask_from_list([2,3,4,5], false)
	hitbox_area.set_deferred("monitoring", false) 


	#Substract hearts
	heart_ammount -= ammount
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
			take_damage(1, area.global_position)

func _on_hitbox_body_entered(body):
	if body.is_in_group("npc"):
		pass
	else:
		if !is_pushed:
			take_damage(1, body.global_position)

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
	if animation.animation == "attack" or animation.animation == "land":
		animation.animation = "walk"
		current_animation = "walk"
		animation.play()

func _check_ledge_grab():
	var is_falling = velocity.y >= 0
	var check_hand = not grab_ray_cast.is_colliding()
	var check_grabbing_height = grab_check_ray_cast.is_colliding()
	var tile = grab_check_ray_cast.get_collision_point()
	var can_grab = is_falling && check_hand && check_grabbing_height && not is_grabbing && (_check_ledge_one_way_grab(tile) || is_on_wall_only()) #sterge && is_on_wall_only() ca sa nu trebuiasca a si d
	
	if can_grab:
		is_grabbing = true
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
	print(player_coords)
	if player_coords.y > 0:
		player_coords.y = player_coords.y + 1
	else :
		player_coords.y = player_coords.y - 1
	print(player_coords)
	var data = tilemap.get_cell_tile_data(1,tile_coords)
	var data_player = tilemap.get_cell_tile_data(1,player_coords)
	if data:
		var type = data.get_custom_data("Margine")
		if data_player:
			var type_player = data_player.get_custom_data("type")
			print(type_player)
			print(type)
			if type == true && type_player != "ledge_1":
				grab_check_ray_cast.enabled=false
				print(1)
				return true
		else:
			if type == true :
				grab_check_ray_cast.enabled=false
				return true
func get_current_frame():
	var frame_index = animation.get_frame()
	var animation_sprite_frames = animation.get_sprite_frames()
	return animation_sprite_frames.get_frame_texture(current_animation, frame_index)
