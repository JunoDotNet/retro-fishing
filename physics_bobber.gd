
extends RigidBody3D

@export var launch_speed: float = 8.0
@export var launch_upward_force: float = 3.0

@onready var rod_tip: Marker3D = get_node("/root/Main/Player/Head/Camera3D/FishingRod/RodTip")
@onready var camera: Camera3D = get_node("/root/Main/Player/Head/Camera3D")
@onready var fishing_status: Label = get_node("/root/Main/HUD/FishingStatus")

@onready var water_detector: RayCast3D = $"../WaterDetector1"


@export var bob_height: float = 0.05
@export var bob_speed: float = 2.0

var bob_time: float = 0.0

var is_cast: bool = false
var is_settled: bool = false

var water_height: float = 0.0
var has_bite: bool = false
@export var min_bite_time: float = 3.0
@export var max_bite_time: float = 8.0

var bite_timer: float = 0.0

var message_timer: float = 0.0
@export var message_duration: float = 3.0


func _ready() -> void:
	freeze = true
	global_position = rod_tip.global_position + Vector3(0, -0.25, 0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not is_cast:
				cast_bobber()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if is_cast and not is_settled:
				call_deferred("break_on_water")
			elif is_cast and is_settled:
				call_deferred("reset_bobber")


func cast_bobber() -> void:
	var forward := -camera.global_basis.z
	var target_position := camera.global_position + forward * 8.0
	is_settled = false

	# Position the existing ray above the target and check for water.
	water_detector.global_position = Vector3(
		target_position.x,
		target_position.y + 20.0,
		target_position.z
	)
	water_detector.target_position = Vector3(0, -40, 0)
	water_detector.force_raycast_update()

	if not water_detector.is_colliding():
		fishing_status.text = "This isnt water pal"
		return
	
	var water_position: Vector3 = water_detector.get_collision_point()
	water_height = water_position.y
	has_bite = false
	

	# If water is found, launch the physics bobber.
	global_position = rod_tip.global_position + Vector3(0, -0.25, 0)
	freeze = false
	sleeping = false
	is_cast = true
	bite_timer = randf_range(min_bite_time, max_bite_time)
	

	linear_velocity = forward.normalized() * launch_speed
	linear_velocity.y += launch_upward_force

	fishing_status.text = "RIGHT CLICK TO STOP THE BOBBER"

func break_on_water() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
	is_settled = true
	fishing_status.text = "Waiting for a bite..."

func reset_bobber() -> void:
	freeze = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	global_position = rod_tip.global_position + Vector3(0, -0.25, 0)
	is_cast = false
	is_settled = false
	has_bite = false
	bite_timer = 0.0
	message_timer = 0.0
	bob_time = 0.0

	freeze = true
	sleeping = true
	fishing_status.text = "LEFT CLICK TO CAST"



func _physics_process(delta: float) -> void:
	if not is_cast:
		global_position = rod_tip.global_position + Vector3(0, -0.25, 0)
		
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0 and not is_cast:
			fishing_status.text = "LEFT CLICK TO CAST"
	
	if not is_cast:
		return

	if is_settled and not has_bite:
		bite_timer -= delta

		if bite_timer <= 0.0:
			has_bite = true
			fishing_status.text = "FISH ON THE HOOK! PRESS E"
			
	if has_bite and Input.is_action_just_pressed("reel_in"):
		reset_bobber()
		fishing_status.text = "YOU CAUGHT A FISH!!"
		message_timer = message_duration

	if is_settled and is_cast:
		bob_time += delta
		global_position.y = water_height + sin(bob_time * bob_speed) * bob_height
	
		
