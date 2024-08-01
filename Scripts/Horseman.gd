extends CharacterBody2D


const SPEED = 80.0
const JUMP_VELOCITY = -400.0
const ENEMY_RECEPTIVENESS = 0.2 #how quickly the enemies percive the player
const ATTACK_COOLDOWN = 2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = -1
var animation
var detection_layer1
var detection_layer2
var example_frame = load("res://Assets/Characters/EnemyAnimation1/ZombieWalkRemake1.png")
var chasing_player
var temp_scale = -1
var follow_timer
var health = 20
var pushback_speed = 300
var can_take_damage = true
var invincibility_timer 
var detection_area
var away_counter = 0
var attack_timer 
var can_attack = true
var horseman_attack_scene = load("res://Scenes/HorsemanAttack.tscn")

var mob_state = mob_states.IDLE

enum mob_states {
	IDLE,
	CHASING,
	ATTACKING
}

func _ready():
	invincibility_timer = $InvincibilityTimer
	detection_layer1 = $DetectionLayer1
	detection_layer2 = $DetectionLayer2
	scale.x *= -1
	animation = $AnimatedSprite2D
	follow_timer = $FollowTimer
	detection_area = $Area2D
	attack_timer = $AttackTimer

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	if mob_state == mob_states.CHASING and is_instance_valid(chasing_player):
		if direction != -sign(position.x - chasing_player.position.x) and follow_timer.is_stopped():
			follow_timer.start(ENEMY_RECEPTIVENESS)
	
	if can_take_damage and mob_state == mob_states.CHASING:
		velocity.x = direction * SPEED 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 50)
		if snapped(velocity.x,0.01) == 0 and snapped(velocity.y,0.01) == 0 and invincibility_timer.is_stopped():
			invincibility_timer.start(0.2)
	
	
	

	if mob_state == mob_states.CHASING:
		if velocity.x == 0:
			animation.play("idle")
		else:
			animation.play("walk")
	
	for i in detection_area.get_overlapping_areas():
		if i.is_in_group("attack") and can_take_damage:
			var player = i.get_node("../../../..")
			var attack_name = i.get_node("../../..").attack_name
			if player.has_method("get_attack"):
				take_damage(player.get_attack(attack_name))
				can_take_damage = false
	
	if mob_state == mob_states.CHASING:
		var is_player = false
		for i in detection_layer1.get_overlapping_bodies():
			if i.is_in_group("player"):
				is_player = true
		if !is_player:
			away_counter += delta
			pass
	
	if away_counter >= 10:
		if mob_state == mob_states.CHASING:
			mob_state = mob_states.IDLE
			animation.play("idle")
		else:
			away_counter = 0
	
	move_and_slide()

func start_chasing(player):
	mob_state = mob_states.CHASING
	chasing_player = player

func _on_player_detection_layer1_body_entered(body):
	if body.is_in_group("player") and mob_state == mob_states.IDLE:
		start_chasing(body)


func _on_follow_timer_timeout():
	if is_instance_valid(chasing_player):
		direction = -sign(position.x - chasing_player.position.x)
		temp_scale *= -1
		scale.x *= -1



func take_damage(attack : Attack):
	#Flash the character white
	modulate = Color(2, 2, 2, 0.8)
	
	#Push back the character
	var pushback_direction = global_position - attack.attack_position
	
	pushback_direction = pushback_direction.normalized()
	pushback_direction.x *= 1.5
	pushback_direction.y *= 0.5
	velocity = pushback_direction * pushback_speed * attack.knockback_power
	
	#Substract health
	health -= attack.attack_damage
	if health <= 0:
		die()

func die():
	queue_free()


func _on_invincibility_timer_timeout():
	can_take_damage = true
	modulate = Color(1,1,1,1)

func get_attack():
	var new_attack = Attack.new()
	
	new_attack.attack_damage = 1
	new_attack.attack_position = global_position
	new_attack.knockback_power = 1
	new_attack.knockback_damage = 0
	new_attack.stun_duration = 0.3
	
	return new_attack


func _on_detection_layer2_body_entered(body):
	if body.is_in_group("player") and mob_state != mob_states.ATTACKING and can_attack:
		mob_state = mob_states.ATTACKING
		animation.stop()
		animation.play("attack")
		can_attack = false
		
		var horse_attack_node = horseman_attack_scene.instantiate()
		horse_attack_node.get_ready("enemy")
		add_child(horse_attack_node)



func _on_animated_sprite_2d_animation_finished():
	attack_timer.start(ATTACK_COOLDOWN)
	animation.play("walk")
	mob_state = mob_states.CHASING


func _on_attack_timer_timeout():
	can_attack = true
	var is_player = false
	for i in detection_layer2.get_overlapping_bodies():
		if i.is_in_group("player"):
			animation.stop()
			animation.play("attack")
			mob_state = mob_states.ATTACKING
			is_player = true
			can_attack = false
			
			var horse_attack_node = horseman_attack_scene.instantiate()
			horse_attack_node.get_ready("enemy")
			add_child(horse_attack_node)
	
	if !is_player:
		animation.play("walk")
		mob_state = mob_states.CHASING
