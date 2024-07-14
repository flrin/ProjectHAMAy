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
var health = 20
var pushback_speed = 300
var can_take_damage = true
var invincibility_timer 

func _ready():
	invincibility_timer = $InvincibilityTimer
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

	if is_chasing == true and is_instance_valid(chasing_player):
		if direction != -sign(position.x - chasing_player.position.x) and follow_timer.is_stopped():
			follow_timer.start(ENEMY_RECEPTIVENESS)


	if can_take_damage:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 50)
		if snapped(velocity.x,0.01) == 0 and snapped(velocity.y,0.01) == 0 and invincibility_timer.is_stopped():
			invincibility_timer.start(0.2)

	#velocity.x = 0

	move_and_slide()
	
	if velocity.x == 0:
		walking_animation.stop()
	else:
		walking_animation.play()
	
	for i in detection_area.get_overlapping_areas():
		if i.is_in_group("attack") and can_take_damage:
			var player = i.get_parent()
			take_damage(1, i.global_position)
			can_take_damage = false


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



func take_damage(ammount, hit_position):
	#Flash the character white
	modulate = Color(2, 2, 2, 0.8)
	
	#Push back the character
	var pushback_direction = position - hit_position
	pushback_direction = pushback_direction.normalized()
	pushback_direction.x *= 1.5
	pushback_direction.y *= 0.5
	velocity = pushback_direction * pushback_speed
	
	#Substract health
	health -= ammount
	if health <= 0:
		die()

func die():
	queue_free()


func _on_invincibility_timer_timeout():
	can_take_damage = true
	modulate = Color(1,1,1,1)
