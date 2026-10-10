extends MeshInstance3D

@export var cast_distance: float = 8.0 # how far in front of the player the bobber will land 
@export var water_height: float = 0.0 # how high the bobber will appear above the water
@export var bob_height: float = 0.05 # how far the bobber moves up and down 
@export var bob_speed: float = 2.0 # how quickly the bobber bobs

@export var min_bite_time: float = 3.0 # minimum amount of time before fish bites 
@export var max_bite_time: float = 8.0 # max amount of time before fish bites 
var bite_timer: float = 0.0 # counts down until a fish bites
var has_bite: bool = false # tracks if fish is biting

var is_cast: bool = false # has the bobber been cast 
var camera: Camera3D # ref to player camera
var bob_time: float = 0.0 # tracks time for the bobbing animation

@onready var fishing_status: Label = get_tree().current_scene.get_node("HUD/FishingStatus") # calls fishing label to scene 
@export var message_duration: float = 3.0 # how long catch message displays 
var message_timer: float = 0.0 # counts down until the message resets. 

@export var ripple_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = get_tree().current_scene.get_node("Player/Head/Camera3D")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		cast_bobber()
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		fishing_status.text = "LEFT CLICK TO CAST"
		message_timer = message_duration # start the message countdown 
		is_cast = false # resets cast 
		has_bite = false # resets has bites
		global_position = Vector3(0, -10, 0) # resets bobber posistion to off the map 
		
	if event.is_action_pressed("reel_in") and has_bite: # if user presses e and has a bite they can reel in the fish 
		fishing_status.text = "YOU CAUGHT A FISH!!" 
		message_timer = 0.0
		is_cast = false # resets cast 
		has_bite = false # resets has bites
		global_position = Vector3(0, -10, 0) # resets bobber posistion to off the map 

func cast_bobber() -> void:
	var forward := -camera.global_basis.z
	
	var target_position := camera.global_position + forward * cast_distance # calulates where the bobber should land 
	
	global_position = Vector3(
		target_position.x,
		water_height,
		target_position.z
	)
	spawn_ripple()
	is_cast = true
	
	message_timer = 0.0 # Cancel any previous message countdown.
	fishing_status.text = "Waiting for a bite..."
	bite_timer = randf_range(min_bite_time,max_bite_time) # start a random wait before a fish bites
	
	has_bite = false # reset the bite state for this cast

func _process(delta: float) -> void:
	if is_cast: # only animate bobber after it has been cast 
		bob_time += delta
		
		if has_bite:
			global_position.y = water_height - 0.05
		else:
			global_position.y = water_height + sin(bob_time * bob_speed) * bob_height # move bobber veritcally using a sine wave 
		
		if not has_bite:
			bite_timer -= delta
			
			if bite_timer <= 0.0:
				has_bite =  true
				fishing_status.text = "FISH ON THE HOOK! PRESS E"
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
