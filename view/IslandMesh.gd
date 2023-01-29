extends MeshInstance

export (int) var random_seed: int = -6398989897141750821 + 3
export (float) var edge_length: float = 10.0
export (int) var edges_across: int = 100
export (int) var land_cell_limit: int = 4000
export (Color) var base_color: Color = Color8(24, 64, 24, 255)
export (Color) var land_color: Color = Color8(32, 96, 32, 255)
export (PoolColorArray) var region_colors := PoolColorArray([
	land_color, # Color8(  0,   0, 192, 255),
	land_color, # Color8(  0, 192,   0, 255),
	land_color, # Color8(192,   0,   0, 255),
	land_color, # Color8(  0, 192, 192, 255),
	land_color, # Color8(192, 192,   0, 255),
	land_color, # Color8(192,   0, 192, 255),
])
export (int) var river_count: int = 30
export (Color) var river_color: Color = Color8(32, 32, 192, 255)
export (Color) var head_color: Color = river_color
export (Color) var mouth_color: Color = river_color
export (PoolColorArray) var lake_colors := PoolColorArray([
	river_color, # Color8( 48,  48, 192, 255),
	river_color, # Color8( 32,  32, 192, 255),
	river_color, # Color8( 16,  16, 192, 255),
])
export (bool) var stages_in_thread: bool = true


var thread: Thread

func _ready() -> void:
	if stages_in_thread:
		thread = Thread.new()
		var _err = thread.start(self, "_stage_thread")
	else:
		_stage_thread()

func _exit_tree():
	if stages_in_thread:
		thread.wait_to_finish()

func _stage_thread() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed
	print(str(rng.seed))
	var grid = Grid.new(edge_length, edges_across, base_color)
	var island_stage = IslandStage.new(grid, land_color, land_cell_limit, rng.randi())
	var regions_stage = RegionStage.new(island_stage.get_region(), region_colors, rng.randi())
	var lake_stage = LakeStage.new(regions_stage, lake_colors, rng.randi())
	var height_stage = HeightStage.new(island_stage.get_region(), lake_stage)
	var river_stage = RiverStage.new(grid, lake_stage, river_count, river_color, rng.randi())
	var island_mesh: Mesh
	
	var stages = [
		island_stage,
		regions_stage,
		lake_stage,
		height_stage,
		river_stage,
	]
	
	island_mesh = _get_mesh_from_grid(grid)
	set_mesh(island_mesh)
	
	for stage in stages:
		stage.perform()
		print(str(stage))
		island_mesh = _get_mesh_from_grid(grid)
		set_mesh(island_mesh)
	
	print("Stages Complete")

func _get_mesh_from_grid(grid: Grid) -> Mesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	var island_mesh: Mesh = Mesh.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in grid.get_triangles():
		for triangle in row:
			var color_dict: Dictionary = triangle.get_river_vertex_colors(river_color, grid.get_color(), head_color, mouth_color)
			for vertex in triangle.get_vertices():
				surface_tool.add_color(color_dict[vertex])
				surface_tool.add_vertex(vertex.get_vector())
	surface_tool.generate_normals()
	var _err = surface_tool.commit(island_mesh)
	
	return island_mesh
