extends CharacterBody2D

enum SkeletonState
{
	walk,
	hurt
}

@onready var animated: AnimatedSprite2D = $Animated
@onready var hitbox: Area2D = $Hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector

const SPEED = 30.0
const JUMP_VELOCITY = -400.0

var skeletonStatus: SkeletonState
var direction = 1

func _ready() -> void:
	go_to_walk_state()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match skeletonStatus:
		SkeletonState.walk:
			walk_state(delta)
		SkeletonState.hurt:
			hurt_state(delta)
	
	move_and_slide()

func go_to_walk_state():
	skeletonStatus = SkeletonState.walk
	animated.play("walk")

func go_to_hurt_state():
	skeletonStatus = SkeletonState.hurt
	animated.play("hurt")
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO

func walk_state(_delta):
	velocity.x = SPEED * direction
	
	if wall_detector.is_colliding():
		scale.x *= -1
		direction *= -1
	
	if not ground_detector.is_colliding():
		scale.x *= -1
		direction *= -1

func hurt_state(_delta):
	pass

func take_damage():
	go_to_hurt_state()
