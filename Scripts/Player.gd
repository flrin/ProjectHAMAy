extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DODGE_ACCELERATION = 10
const PUSHBACK_SPEED  = 500
const AFTERIMAGE_NUMBER = 10
const AFTERIMAGE_FREQ = 0.1

signal damage_taken(ammount)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dodge_accel = 1
var collision_shape
var hitbox_area
var is_pushed = false
var heart_ammount = 3
var player_model = load("res://Assets/Characters/PlayerCharacter.png")
var afterimage_scene = load("res://Scenes/AfterImage.tscn")
var afterimage_timer
var ui
var afterimage_count = 10
var tilemap

func _ready():
	collision_shape = $CollisionShape2D
	hitbox_area = $HitboxArea
	ui = get_node("../UI/UI")
	damage_taken.connect(ui.change_health)
	set_collision_mask_from_list([2,3,4,5], true)
	afterimage_timer = $AfterimageTimer
	tilemap=get_node("../TileMap")
	
func _physics_process(delta):
	#Process collisions

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() && !Input.is_action_pressed("ui_down"):
		velocity.y = JUMP_VELOCITY

	#Handle dodge
	if dodge_accel == 1:
		if Input.is_action_just_pressed("ui_dodge"):
			dodge_accel = DODGE_ACCELERATION
			set_collision_mask_from_list([2,3,4,5], false)
			hitbox_area.monitoring = false
			start_afterimage()
		else:
			set_collision_mask_from_list([2,3,4,5], true)
			hitbox_area.monitoring = true
	else:
		dodge_accel -= 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction and is_pushed == false:
		velocity.x = direction * SPEED * dodge_accel 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 18.25)
	if velocity.x == 0:
		is_pushed = false
	
	fall_down_ledge() #nus unde vrei sa lasi asta
	
	move_and_slide()

func set_collision_mask_from_list(list_to_set, value): #value e ori true ori false
	for i in list_to_set:
		set_collision_mask_value(i, value)

func take_damage(ammount, hit_position):
	#Emit signal
	emit_signal("damage_taken", ammount)
	
	#Knock back the player
	var pushback_direction = position - hit_position
	pushback_direction = pushback_direction.normalized()
	pushback_direction.x *=2
	velocity = pushback_direction * PUSHBACK_SPEED
	is_pushed = true

	#Substract hearts
	heart_ammount -= ammount
	if heart_ammount <= 0:
		game_over()

func game_over():
	queue_free()

func _on_hitbox_area_entered(area):
	take_damage(1, area.position)

func _on_hitbox_body_entered(body):
	take_damage(1, body.position)

func start_afterimage():
	afterimage_timer.start(AFTERIMAGE_FREQ)


func _on_afterimage_timer_timeout():
	if afterimage_count > 0:
		var afterimage_node = afterimage_scene.instantiate()
		afterimage_node.get_ready(player_model, position)
		get_node("..").add_child(afterimage_node)
		
		afterimage_count -= 1
		afterimage_timer.start(AFTERIMAGE_FREQ)
	else:
		afterimage_count = AFTERIMAGE_NUMBER

func drop_down_ledge():
	position.y += 3

func fall_down_ledge():
	var tile_coords=tilemap.local_to_map(tilemap.to_local(global_position))
	var data = tilemap.get_cell_tile_data(1,tile_coords) #1 e layer-u daca vrei sa iei datele de la alte layer numa schimba aia (daca vrei sa detectezi daca stai pe pamant de exmplu sau pe piatra)
	if data:
		var type = data.get_custom_data("type")
		if type == "ledge_1" && is_on_floor() && Input.is_action_pressed("ui_down") && Input.is_action_just_pressed("ui_space"): #daca o sa avem mai multe tipuri de ledge-uri o sa lasam numa in caz general si le numim pe toate ledge xD ca sa nu ne batem capu cu ledge_1&&ledge_2 etc
			drop_down_ledge()
