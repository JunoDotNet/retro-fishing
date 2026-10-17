
extends RigidBody3D
class_name FishingBobber
signal settled

@export var launch_speed: float = 8.0
@export var launch_upward_force: float = 3.0


var rod_tip: Marker3D


@export var bob_height: float = 0.05
@export var bob_speed: float = 2.0


var bob_time: float = 0.0
var settle_timer: float = 0.0
@export var settle_delay: float = 2.5

var is_cast: bool = false
var is_settled: bool = false
var has_touched_water: bool = false

var water_height: float = 0.0
var settled_position_y: float = 0.0

func _ready() -> void:
	freeze = true

func cast_bobber(forward: Vector3, start_position: Vector3, target_water_height: float) -> void:
	is_settled = false
	settle_timer = 0.0
	bob_time = 0.0
	has_touched_water = false
	water_height = target_water_height
	global_position = start_position
	freeze = false
	sleeping = false
	is_cast = true

	linear_velocity = forward.normalized() * launch_speed
	linear_velocity.y += launch_upward_force


func reset_bobber() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	water_height = 0.0
	settled_position_y = 0.0

	is_cast = false
	is_settled = false
	bob_time = 0.0
	settle_timer = 0.0
	has_touched_water = false

	freeze = true
	sleeping = true
	if rod_tip:
		global_position = rod_tip.global_position + Vector3(0, -0.25, 0)

func _physics_process(delta: float) -> void:
	if not is_cast:
		if rod_tip:
			global_position = rod_tip.global_position + Vector3(0, -0.25, 0)
		return

	# Detect the bobber reaching the water.
	if not has_touched_water:
		if global_position.y > water_height + 0.1:
			return

		has_touched_water = true
		settle_timer = 0.0
		settled_position_y = water_height
		global_position.y = water_height
		linear_velocity.y = 0.0

	if has_touched_water and not is_settled:
		global_position.y = water_height
		linear_velocity.y = 0.0

	# Automatically settle after the timer expires.
	if has_touched_water and not is_settled:
		settle_timer += delta

		if settle_timer >= settle_delay:
			_finish_settling()

	# Animate the bobber vertically after it settles.
	if is_settled:
		bob_time += delta
		var bob_offset = sin(bob_time * bob_speed) * bob_height
		global_position.y = settled_position_y + bob_offset

func _finish_settling() -> void:
	if is_settled:
		return
	is_settled = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
	settled.emit()

func settle() -> void:
	if not is_cast or is_settled or not has_touched_water:
		return

	settled_position_y = water_height
	global_position.y = water_height

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	_finish_settling()
