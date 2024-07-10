extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DODGE_ACCELERATION = 10

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dodge_accel = 1
var collision_shape

func _ready():
	collision_shape = $CollisionShape2D

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	#Handle dodge
	if dodge_accel == 1:
		if Input.is_action_just_pressed("ui_dodge"):
			dodge_accel = DODGE_ACCELERATION
			set_collision_mask_from_list([2,3,4,5], false)
		else:
			set_collision_mask_from_list([2,3,4,5], true)
	else:
		dodge_accel -= 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED * dodge_accel
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func set_collision_mask_from_list(list_to_set, value): #value e ori true ori false
	for i in list_to_set:
		set_collision_mask_value(i, value)
