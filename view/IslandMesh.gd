extends MeshInstance

export (int) var random_seed: int = -6398989897141750821 + 3
export (float) var edge_length: float = 10.0
export (int) var edges_across: int = 100
export (int) var land_cell_limit: int = 4000
export (Resource) var debug_color_dict: Resource
export (int) var river_count: int = 30

export (bool) var stages_in_thread: bool = false


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
	var island_mesh: Mesh = _get_mesh_from_grid(high_level_terrain.grid)
	set_mesh(island_mesh)
	high_level_terrain.perform()

func _on_stage_complete(stage: Stage) -> void:
	print(str(stage))
	var island_mesh: Mesh = _get_mesh_from_grid(high_level_terrain.grid)
	set_mesh(island_mesh)

func _on_all_stages_complete() -> void:
	print("High Level Terrain stages complete")
	var island_mesh: Mesh = _get_mesh_from_grid(high_level_terrain.grid)
	set_mesh(island_mesh)

func _get_mesh_from_grid(grid: Grid) -> Mesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	var island_mesh: Mesh = Mesh.new()

	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in grid.get_triangles():
		for triangle in row:
			var color_dict: Dictionary = triangle.get_river_vertex_colors(debug_color_dict.river_color, grid.get_color(), debug_color_dict.head_color, debug_color_dict.mouth_color)
			for vertex in triangle.get_vertices():
				surface_tool.add_color(color_dict[vertex])
				surface_tool.add_vertex(vertex.get_vector())
	surface_tool.generate_normals()
	var _err = surface_tool.commit(island_mesh)
	
	return island_mesh
