extends MeshInstance3D

@export var lifetime: float = 0.8
@export var max_scale: float = 0.8 
@export var min_scale: float = 0.2

var elapsed: float = 0.0
var ripple_material: StandardMaterial3D

func _ready() -> void:
	var material := get_active_material(0)
	if material is StandardMaterial3D:
		ripple_material = material.duplicate() # duplicates the material so if mulitple rings appear they dont all share the same alpha 
		ripple_material.resource_local_to_scene = true
		ripple_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		set_surface_override_material(0, ripple_material) # tells this mesh to use the copied material instead of the original one from surface 0 


func _process(delta: float) -> void:
	elapsed += delta

	if elapsed >= lifetime:
		queue_free()
		return

	var progress: float = elapsed / lifetime

	var ripple_scale: float = lerpf(min_scale, max_scale, progress)
	scale = Vector3.ONE * ripple_scale
	
	var alpha: float
	if progress < 0.2:
		alpha = progress / 0.2
	else:
		alpha = 1.0 - ((progress - 0.2) / 0.8)

	if ripple_material:
		var color := ripple_material.albedo_color
		color.a = alpha
		ripple_material.albedo_color = color
