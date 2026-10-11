extends MeshInstance3D

@export var cast_distance: float = 8.0 # how far in front of the player the bobber will land 
@export var water_height: float = 0.0 # how high the bobber will appear above the water
@export var bob_height: float = 0.05 # how far the bobber moves up and down 
@export var bob_speed: float = 2.0 # how quickly the bobber bobs
@onready var water_detector: RayCast3D = $WaterDetector

@export var min_bite_time: float = 3.0 # minimum amount of time before fish bites 
@export var max_bite_time: float = 8.0 # max amount of time before fish bites 
var bite_timer: float = 0.0 # counts down until a fish bites
var has_bite: bool = false # tracks if fish is biting

@onready var rod_tip: Marker3D = get_tree().root.get_node("Main/Player/Head/Camera3D/FishingRod/RodTip")
@onready var physics_bobber: RigidBody3D = get_node("../PhysicsBobber")

var is_cast: bool = false # has the bobber been cast 
var camera: Camera3D # ref to player camera
var bob_time: float = 0.0 # tracks time for the bobbing animation

@onready var fishing_status: Label = get_tree().root.get_node("Main/HUD/FishingStatus")
@export var message_duration: float = 3.0 # how long catch message displays 
var message_timer: float = 0.0 # counts down until the message resets. 

@export var ripple_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = get_tree().current_scene.get_node("Player/Head/Camera3D")
	return_to_rod()

func _unhandled_input(event: InputEvent) -> void:
	pass

func cast_bobber() -> void:
	if physics_bobber.is_cast:
		return
	var forward := -camera.global_basis.z
	physics_bobber.global_position = rod_tip.global_position
	physics_bobber.launch(forward)
	return
	var target_position := camera.global_position + forward * cast_distance # calulates where the bobber should land 
	
	water_detector.global_position = Vector3(
		target_position.x,
		target_position.y + 20.0,
		target_position.z	
	)
	water_detector.force_raycast_update()
		
	if not water_detector.is_colliding():
		fishing_status.text = "This isnt water pal"
		return
	
	var water_position: Vector3 = water_detector.get_collision_point()
	water_height = water_position.y
	
	global_position = Vector3(
		target_position.x,
		water_height,
		target_position.z
	)
	is_cast = true
	spawn_ripple()
	
	message_timer = 0.0 # Cancel any previous message countdown.
	fishing_status.text = "Waiting for a bite..."
	bite_timer = randf_range(min_bite_time,max_bite_time) # start a random wait before a fish bites
	
	has_bite = false # reset the bite state for this cast

func _process(delta: float) -> void:
	if not is_cast:
		global_position = rod_tip.global_position + Vector3(0, -0.3, 0)
	
	if is_cast: # only animate bobber after it has been cast 
		pass
	if message_timer > 0.0:
		message_timer -=delta
		
		if message_timer <= 0.0:
			fishing_status.text = "LEFT CLICK TO CAST"

func spawn_ripple() -> void:
	if ripple_scene == null:
		return
	var ripple = ripple_scene.instantiate()
	
	get_tree().current_scene.add_child(ripple)
	
	ripple.global_position = global_position + Vector3(0, 0.02, 0)

func get_water_surface_position() -> Vector3:
	if water_detector.is_colliding():
		return water_detector.get_collision_point()
	return global_position

func return_to_rod() -> void:
	if rod_tip == null:
		print("ERROR: rod_tip was not found")
		return

	global_position = rod_tip.global_position
