extends MeshInstance

export (int) var random_seed: int = -6398989897141750821 + 3
export (float) var edge_length: float = 10.0
export (int) var edges_across: int = 100
export (int) var land_cell_limit: int = 4000
export (Resource) var debug_color_dict: Resource
export (int) var river_count: int = 30

export (bool) var stages_in_thread: bool = true


var thread: Thread
var high_level_terrain: HighlevelTerrain

func _ready() -> void:
	high_level_terrain = HighlevelTerrain.new(
		random_seed,
		edge_length,
		edges_across,
		land_cell_limit,
		river_count,
		debug_color_dict
	)
	var _err1 = high_level_terrain.connect("all_stages_complete", self, "_on_all_stages_complete")
	var _err2 = high_level_terrain.connect("stage_complete", self, "_on_stage_complete")
	if stages_in_thread:
		thread = Thread.new()
		var _err = thread.start(self, "_stage_thread")
	else:
		_stage_thread()

func _exit_tree():
	if stages_in_thread:
		thread.wait_to_finish()

func _stage_thread() -> void:
	var island_mesh: Mesh = MeshUtils.get_land_mesh(high_level_terrain, debug_color_dict)
	set_mesh(island_mesh)
	high_level_terrain.perform()

func _on_stage_complete(stage: Stage) -> void:
	print(str(stage))
	var island_mesh: Mesh = MeshUtils.get_land_mesh(high_level_terrain, debug_color_dict)
	set_mesh(island_mesh)

func _on_all_stages_complete() -> void:
	var island_mesh: Mesh = MeshUtils.get_land_mesh(high_level_terrain, debug_color_dict)
	set_mesh(island_mesh)
	_create_water_mesh_instances(load("res://materials/water_surface.tres"))
	print("High Level Terrain stages complete")

func _create_water_mesh_instances(water_material: Material) -> void:
	# TODO: Consider how this can be separated from the land mesh in a nice way
	var meshes: Array = MeshUtils.get_water_body_meshes(high_level_terrain)
	for water_mesh in meshes:
		var mesh_instance: MeshInstance = MeshInstance.new()
		mesh_instance.mesh = water_mesh
		# TODO: fix the material properties so colors, etc are visible
		mesh_instance.set_surface_material(0, water_material)
		add_child(mesh_instance)

