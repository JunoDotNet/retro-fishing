extends Node3D

@export var bobber: RigidBody3D
@export var fishing_status: Label

@onready var water_detector: RayCast3D = $WaterDetector1

@export var min_bite_time: float = 3.0
@export var max_bite_time: float = 8.0

var rod_tip: Marker3D
var camera: Camera3D


var bite_timer: float = 0.0
enum FishingState {
	IDLE,
	CAST,
	WAITING_FOR_BITE,
	BITE,
	CAUGHT
}

var current_state: FishingState = FishingState.IDLE
var caught_message_timer: float = 0.0

func _ready() -> void:
	var main = get_tree().current_scene
	rod_tip = main.get_node("Player/Head/Camera3D/FishingRod/RodTip")
	camera = main.get_node("Player/Head/Camera3D")
	bobber.rod_tip = rod_tip
	bobber.settled.connect(_on_bobber_settled)

func change_state(new_state: FishingState) -> void:
	current_state = new_state

	match current_state:
		FishingState.IDLE:
			show_fishing_message("LEFT CLICK TO CAST")
		FishingState.CAST:
			show_fishing_message("BOBBER CAST...")
		FishingState.WAITING_FOR_BITE:
			show_fishing_message("Waiting for a bite...")
		FishingState.BITE:
			show_fishing_message("FISH ON THE HOOK! PRESS E")
		FishingState.CAUGHT:
			show_fishing_message("YOU CAUGHT A FISH!!")

func show_fishing_message(message: String) -> void:
	if caught_message_timer > 0.0 and current_state != FishingState.CAUGHT:
		return
	fishing_status.text = message

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if current_state == FishingState.IDLE or (current_state == FishingState.CAUGHT and not bobber.is_cast):
				var forward := -camera.global_basis.z
				var start_position := rod_tip.global_position + Vector3(0, -0.25, 0)
				var target_position := start_position + forward * 8.0
				water_detector.global_position = Vector3(
					target_position.x,
					target_position.y + 20.0,
					target_position.z
				)
				water_detector.target_position = Vector3(0, -40, 0)
				water_detector.force_raycast_update()

				if water_detector.is_colliding():
					bobber.cast_bobber(
						forward,
						start_position,
						water_detector.get_collision_point().y
					)
					change_state(FishingState.CAST)
				else:
					show_fishing_message("NO WATER FOUND - AIM AT THE WATER")
			elif current_state == FishingState.CAST:
				bobber.settle()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if current_state != FishingState.IDLE or bobber.is_cast:
				reset_fishing()
				
	if event.is_action_pressed("reel_in") and current_state == FishingState.BITE:
		return_bobber_to_rod()
		change_state(FishingState.CAUGHT)
		caught_message_timer = 2.0


func _process(delta: float) -> void:
	if current_state == FishingState.WAITING_FOR_BITE:
		bite_timer -= delta
		if bite_timer <= 0.0:
			change_state(FishingState.BITE)
	if caught_message_timer > 0.0:
		caught_message_timer -= delta
		if caught_message_timer <= 0.0:
			if current_state == FishingState.CAUGHT:
				change_state(FishingState.IDLE)
			elif current_state == FishingState.CAST:
				show_fishing_message("BOBBER CAST...")
			elif current_state == FishingState.WAITING_FOR_BITE:
				show_fishing_message("Waiting for a bite...")
			elif current_state == FishingState.BITE:
				show_fishing_message("FISH ON THE HOOK! PRESS E")
func reset_fishing() -> void:
	return_bobber_to_rod()
	change_state(FishingState.IDLE)
	bite_timer = 0.0
	caught_message_timer = 0.0

func return_bobber_to_rod() -> void:
	bobber.reset_bobber()

func _on_bobber_settled() -> void:
	if current_state != FishingState.CAST:
		return
	change_state(FishingState.WAITING_FOR_BITE)
	bite_timer = randf_range(min_bite_time, max_bite_time)
