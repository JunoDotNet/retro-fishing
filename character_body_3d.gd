extends CharacterBody3D


const SPEED = 5.0
@export var acceleration: float = 20.0
@export var deceleration: float = 15.0
@export var air_control: float = 0.4
const JUMP_VELOCITY = 4.5

@export var mouse_sensitivity: float = 0.002 # allows players to control mouse senesitivity 
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D # finds camera node in player node

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # hides cursor and locks the cursor inside the game window 

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("player_left", "player_right", "player_forward", "player_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var current_acceleration = acceleration if is_on_floor() else acceleration * air_control
	
	if direction:
		velocity.x = move_toward(
			velocity.x,
			direction.x * SPEED,
			current_acceleration * delta
		)
		velocity.z = move_toward(
			velocity.z,
			direction.z * SPEED,
			current_acceleration * delta
		)
	else:
		var horizontal_velocity := Vector3(velocity.x, 0, velocity.z)
		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO,
			deceleration * delta
		)

		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z


	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: #checks if input is mouse movement 
		rotate_y(-event.relative.x * mouse_sensitivity)  # Rotates the entire player left or right based on horizontal mouse movement.
		# The minus sign makes moving the mouse right turn the player to the right.
		
		head.rotate_x(-event.relative.y * mouse_sensitivity) # Rotates only the camera up or down based on vertical mouse movement.
		# Restricts vertical camera rotation so the player cannot flip upside down.
		# The limits are converted from degrees to radians because Godot uses radians.
		head.rotation.x = clamp(
			head.rotation.x,
			deg_to_rad(-85),
			deg_to_rad(85)
		)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
