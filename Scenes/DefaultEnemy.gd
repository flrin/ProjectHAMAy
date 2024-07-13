extends CharacterBody2D


const SPEED = 80.0
const JUMP_VELOCITY = -400.0
const ENEMY_RECEPTIVENESS = 0.2 #how quickly the enemies percive the player

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = -1
var walking_animation
var detection_area
var example_frame = load("res://Assets/Characters/EnemyAnimation1/ZombieWalkRemake1.png")
var is_chasing
var chasing_player
var temp_scale = -1
var follow_timer

func _ready():
	detection_area = $Area2D
	scale.x *= -1
	walking_animation = $AnimatedSprite2D
	walking_animation.play()
	follow_timer = $FollowTimer

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var direction = Input.get_axis("ui_left", "ui_right")
	#if direction:
	#	velocity.x = direction * SPEED
	#else:
	#	velocity.x = move_toward(velocity.x, 0, SPEED)

	if is_chasing == true:
		if direction != -sign(position.x - chasing_player.position.x) and follow_timer.is_stopped():
			follow_timer.start(ENEMY_RECEPTIVENESS)


	
	velocity.x = direction * SPEED

	#velocity.x = 0

	move_and_slide()
	
	if velocity.x == 0:
		walking_animation.stop()
	else:
		walking_animation.play()


func start_chasing(player):
	is_chasing = true
	chasing_player = player

func _on_player_detection_area_body_entered(body):
	if body.is_in_group("player"):
		start_chasing(body)


func _on_follow_timer_timeout():
	direction = -sign(position.x - chasing_player.position.x)
	temp_scale *= -1
	scale.x *= -1
