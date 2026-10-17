extends Node3D

@export var ripple_scene: PackedScene
@export var bobber_path: NodePath
@export var ripple_interval: float = 0.8

var bobber: Node3D
var ripple_timer: float = 0.0

func _ready() -> void:
	bobber = get_node_or_null(bobber_path) as Node3D
	if not bobber:
		push_error("RippleSpawner requires a valid bobber node path.")
		set_process(false)
	if not ripple_scene:
		push_error("RippleSpawner requires a ripple scene.")
		set_process(false)

func _process(delta: float) -> void:
	if not bobber or not bobber.is_cast:
		ripple_timer = 0.0
		return
	
	ripple_timer += delta
	if ripple_timer >= ripple_interval:
		spawn_ripple()
		ripple_timer -= ripple_interval

func spawn_ripple() -> void:
	var ripple = ripple_scene.instantiate()
	var has_min_scale := false
	for property in ripple.get_property_list():
		if property.name == "min_scale":
			has_min_scale = true
			break
	if not has_min_scale:
		push_error("RippleSpawner's ripple scene root must define min_scale.")
		ripple.free()
		return

	var min_scale = ripple.get("min_scale")
	ripple.name = "RippleInstance"
	ripple.scale = Vector3.ONE * min_scale
	ripple.visible = false
	get_tree().current_scene.add_child(ripple)
	ripple.global_position = Vector3(
		bobber.global_position.x,
		bobber.water_height + 0.02,
		bobber.global_position.z
	)
	ripple.visible = true
