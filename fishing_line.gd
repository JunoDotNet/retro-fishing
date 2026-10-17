extends MeshInstance3D


@export var rod_tip_path: NodePath
@export var bobber_path: NodePath
@export var line_sag: float = 0.8 # controls how far the line curves downwards
@export var line_segments: int = 12 # controls how many segments the line is made of 

var rod_tip: Marker3D
var bobber: Node3D # Stores a reference to the bobber node.
var line_mesh: ImmediateMesh # Stores the mesh that we'll generate to draw the fishing line.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rod_tip = get_node_or_null(rod_tip_path) as Marker3D
	bobber = get_node_or_null(bobber_path) as Node3D
	if not rod_tip or not bobber:
		push_error("FishingLine requires valid rod tip and bobber node paths.")
		set_process(false)
		return
	
	line_mesh = ImmediateMesh.new() # Create an empty mesh that we can build geometry into.
	mesh = line_mesh # allowing the generated geometry to be rendered
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_instance_valid(rod_tip) or not is_instance_valid(bobber):
		return
	line_mesh.clear_surfaces() # Clear the previous frame's geometry.
	
	var start: Vector3 = rod_tip.global_position # Get the global position of the RodTip marker, this is where the fishing line will start
	var finish: Vector3 = bobber.global_position # Get the global pos of the bobber marker, this is where the fishing line will end
	
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES) # Start creating line geometry
	
	var previous_point: Vector3 = start # Store the starting point so the first segment begins at the rod tip.
	
	for i in range(1, line_segments + 1): # generates a series of points connected between bobber and rod 
		var t: float = float(i) / line_segments 
		# Convert the loop counter into a number between 0 and 1.
		# 0 represents the rod end; 1 represents the bobber end.
		
		var point: Vector3 = start.lerp(finish, t) # for indiviual vert find vert along straight path. It finds a pos between start and finish based on the value of t
		
		point.y -= line_sag * 4.0 * t * (1.0 - t) # adjust the vert height to create the actual sag The forumula is zero at both endpoints and largest halfway through 
		
		line_mesh.surface_add_vertex(to_local(previous_point))
		line_mesh.surface_add_vertex(to_local(point))
		# Add a line segment connecting the previous vert to this vert.
		# to_local converts world-space positions into the coordinate
		# space of the FishingLine node, which the mesh uses.
		
		previous_point = point # Save the current point so the next segment connects to it.
		
	# Finish building the mesh for this frame.
	line_mesh.surface_end()
