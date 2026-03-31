extends CharacterBody2D

enum PlayerState
{
	idle,
	walk,
	jump,
	fall,
	duck,
	slide,
	wall,
	hurt
}

@onready var animated: AnimatedSprite2D = $Animated
@onready var collision: CollisionShape2D = $Collision
@onready var hit_box_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var left_wall_detector: RayCast2D = $LeftWallDetector
@onready var right_wall_detector: RayCast2D = $RightWallDetector

@onready var reload_timer: Timer = $ReloadTimer

@export var max_speed = 150.0
@export var acceleration = 300.0
@export var deceleration = 300.0
@export var slide_deceleration = 100.0
@export var wall_acceleration = 40
@export var wall_jump_velocity = 250

const JUMP_VELOCITY = -300.0
var playerStatus: PlayerState
var direction = 0
var jump_count = 0
@export var max_jump_count = 2

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	match playerStatus:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.slide:
			slide_state(delta)
		PlayerState.wall:
			wall_state(delta)
		PlayerState.hurt:
			hurt_state(delta)
	
	move_and_slide()

func go_to_idle_state():
	playerStatus = PlayerState.idle
	animated.play("idle")

func go_to_walk_state():
	playerStatus = PlayerState.walk
	animated.play("walk")

func go_to_jump_state():
	playerStatus = PlayerState.jump
	animated.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1

func go_to_fall_state():
	playerStatus = PlayerState.fall
	animated.play("fall")

func go_to_duck_state():
	playerStatus = PlayerState.duck
	animated.play("duck")
	set_small_collider()

func exit_from_duck_state():
	set_large_collider()

func go_to_slide_state():
	playerStatus = PlayerState.slide
	animated.play("slide")
	set_small_collider()

func exit_from_slide_state():
	set_large_collider()

func got_to_wall_state():
	playerStatus = PlayerState.wall
	animated.play("wall")
	velocity = Vector2.ZERO
	jump_count = 0

func go_to_hurt_state():
	if playerStatus == PlayerState.hurt:
		return

	playerStatus = PlayerState.hurt
	animated.play("hurt")
	velocity.x = 0
	reload_timer.start()

func idle_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if velocity.x != 0:
		go_to_walk_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
	
	if Input.is_action_pressed("duck"):
		go_to_duck_state()
		return

func walk_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if velocity.x == 0:
		go_to_idle_state()
		return

	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
	
	if Input.is_action_just_pressed("duck"):
		go_to_slide_state()
		return
	
	if !is_on_floor():
		jump_count =+ 1
		go_to_fall_state()
		return

func jump_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
	
	if velocity.y > 0:
		go_to_fall_state()
		return

func fall_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return

	if is_on_floor():
		jump_count = 0
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return
	
	if left_wall_detector.is_colliding() or right_wall_detector.is_colliding():
		got_to_wall_state()
		return

func duck_state(delta):
	apply_gravity(delta)
	direction_update()
	
	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return

func slide_state(delta):
	apply_gravity(delta)
	
	velocity.x = move_toward(velocity.x, 0, slide_deceleration * delta)
	
	if Input.is_action_just_released("duck"):
		exit_from_slide_state()
		go_to_walk_state()
		return
	
	if velocity.x == 0:
		exit_from_slide_state()
		go_to_duck_state()
		return

func wall_state(delta):
	
	velocity.y += wall_acceleration * delta
	
	if left_wall_detector.is_colliding():
		animated.flip_h = false
		direction = 1
	elif right_wall_detector.is_colliding():
		animated.flip_h = true
		direction = -1
	else:
		go_to_fall_state()
		return
	
	if is_on_floor():
		go_to_idle_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		velocity.x = wall_jump_velocity * direction
		go_to_jump_state()
		return

func hurt_state(delta):
	apply_gravity(delta)

func move(delta):
	direction_update()
	
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

func direction_update():
	direction = Input.get_axis("left", "right")
	
	if direction < 0:
		animated.flip_h = true
	elif direction > 0:
		animated.flip_h = false

func can_jump() -> bool:
	return jump_count < max_jump_count

func set_small_collider():
	collision.shape.radius = 5
	collision.shape.height = 10
	collision.position.y = 3
	
	hit_box_collision_shape.shape.size.y = 10
	hit_box_collision_shape.position.y = 3

func set_large_collider():
	collision.shape.radius = 5
	collision.shape.height = 16
	collision.position.y = 0
	
	hit_box_collision_shape.shape.size.y = 15
	hit_box_collision_shape.position.y = 0.5

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LethalArea"):
		hit_lethal_area()	

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		go_to_hurt_state()

func hit_enemy(area: Area2D):
	if velocity.y > 0:
		#inimigo morrer
		area.get_parent().take_damage()
		go_to_jump_state()
	else:
		#player morrer
		go_to_hurt_state()

func hit_lethal_area():
	go_to_hurt_state()

func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()
