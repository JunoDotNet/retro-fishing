extends Node3D

@export var ripple_scene: PackedScene
@export var bobber_path: NodePath
@export var ripple_interval: float = 0.8
@export var hooked_interval: float = 0.6

var bobber: Node3D # allows this script to use the bobber to check the variables in that file FINDS THE PATH 
var ripple_timer: float = 0.0 # keeps track of time since last ripple spawned 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bobber = get_node(bobber_path) # SETS ACTUAL NODE from the imported path 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not bobber.is_cast: # if the bobber hasnt been cast then timer is set to zero 
		ripple_timer = 0.0
		return
	
	ripple_timer += delta # adds time since the previous frame to ripple timer 
	
	var current_interval = ripple_interval # state to decide what interval to use 
	
	if bobber.has_bite: # if the bobber has a bite use the hooked interval 
		current_interval = hooked_interval
	
	if ripple_timer >= current_interval: # has enough time past since last ripple 
		spawn_ripple() # spawns the ripple 
		ripple_timer -= current_interval # ripple_timer = ripple_timer - current_interval deduct the time needed for that ripple from the timer 

func spawn_ripple() -> void:
	var ripple = ripple_scene.instantiate() # create a new ripple 
	ripple.name = "RippleInstance" # sets the name of the instance in the scene 
	
	ripple.scale = Vector3.ONE * ripple.min_scale # sets the torus to the minimum scale when first spawned in 
	ripple.visible = false # hide it initally to prevent showing it unintentinoally 
	
	get_tree().current_scene.add_child(ripple) # gets current scene and then adds the ripple node to that scene 
	
	#ripple.global_position = bobber.global_position # this does not work because the bobber goes below the waterline sometimes 
	
	ripple.global_position = Vector3( # sets the the ripple pos ens
		bobber.global_position.x, # bobbers global x pos
		bobber.water_height + 0.02, # water_height from bobber 
		bobber.global_position.z # bobbers global y pos 
	)
	ripple.visible = true # after added and pos is applied make instance visible 
