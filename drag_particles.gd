extends GPUParticles3D
@onready var impact_splash: GPUParticles3D = $"../ImpactSplash"

var previous_position: Vector3

var previous_y: float 
var surface_skid_timer: float = 0.0

@export var skid_effect_duration: float = 0.35
@export var skid_spread: float = 75.0

var impact_triggered: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	previous_position = get_parent().global_position # get bobbers global posistion for first frame 
	emitting = false # while loading do not emit 
	
	previous_y = get_parent().global_position.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var bobber = get_parent() # set bobber in scene to be able to use variables from its script 
	var current_position: Vector3 = bobber.global_position # set current posistion to the same posistion as the bobber
	
	if(
		bobber.is_cast
		and not bobber.is_settled
		and not impact_triggered
		and current_position.y <= bobber.water_height + 0.15
	):
		surface_skid_timer = skid_effect_duration
		impact_triggered = true
		
		impact_splash.global_position = current_position
		
		impact_splash.restart()
		impact_splash.emitting = true
		
	if surface_skid_timer > 0.0:
		surface_skid_timer = maxf(surface_skid_timer - delta, 0.0)
	
	if not bobber.is_cast or bobber.is_settled: # only create particles if bobber is cast 
		emitting = false
		previous_position = current_position
		impact_triggered = false
		return
			
	var movement: Vector3 = current_position - previous_position # find movement from subtracting current from previous 
	var speed: float = movement.length() / maxf(delta, 0.001)
	if surface_skid_timer > 0.0:
		emitting = speed > 0.01 # emit more particles when the bobber moves faster 
	else:
		emitting = speed > 2.0
	
	if emitting:
		var trail_direction: Vector3 = -movement.normalized()	
		var material := process_material as ParticleProcessMaterial
		if material:
			if surface_skid_timer > 0.0:
				material.direction = Vector3(
					trail_direction.x,
					0.0,
					trail_direction.z
				).normalized()
				material.spread = 15.0
				material.initial_velocity_min = 0.9
				material.initial_velocity_max = 2.0
				material.gravity = Vector3(0, -1, 0)
			else:
				material.spread = 5.0
				material.direction = trail_direction
				material.initial_velocity_min = 0.1
				material.initial_velocity_max = 0.4
	previous_position = current_position
