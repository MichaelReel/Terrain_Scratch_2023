class_name MeshUtils
extends Object


static func get_land_mesh(high_level_terrain: HighlevelTerrain, debug_color_dict: DebugColorDict) -> Mesh:
	var grid = high_level_terrain.grid
	var surface_tool: SurfaceTool = SurfaceTool.new()
	var island_mesh: Mesh = Mesh.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in grid.get_triangles():
		for triangle in row:
			var color_dict: Dictionary = triangle.get_river_vertex_colors(
				debug_color_dict.river_color, debug_color_dict.base_color, debug_color_dict.head_color, debug_color_dict.mouth_color
			)
			for vertex in triangle.get_vertices():
				surface_tool.add_color(color_dict[vertex])
				surface_tool.add_vertex(vertex.get_vector())
	surface_tool.generate_normals()
	var _err = surface_tool.commit(island_mesh)
	
	return island_mesh

static func get_water_body_meshes(high_level_terrain: HighlevelTerrain) -> Array:  # -> Array[Mesh]
	var meshes: Array = []
	for lake in high_level_terrain.get_lakes():
		meshes.append(_get_water_body_mesh(lake))
	meshes.append(_get_sea_level_mesh(high_level_terrain.grid))
	return meshes

static func get_river_surface_meshes(high_level_terrain: HighlevelTerrain) -> Array:  # -> Array[Mesh]
	var meshes: Array = []
	for river in high_level_terrain.get_rivers():
		meshes.append(_get_river_surface_mesh(river, high_level_terrain._lake_stage))
	return meshes

static func _get_water_body_mesh(lake: Region) -> Mesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	var lake_mesh: Mesh = Mesh.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle in lake.get_cells():
		for vertex in triangle.get_vertices():
			surface_tool.add_vertex(vertex.get_vector_at_height(lake.get_water_height()))
	
	surface_tool.generate_normals()
	var _err = surface_tool.commit(lake_mesh)
	
	return lake_mesh

static func _get_sea_level_mesh(grid: Grid) -> Mesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	var sea_mesh: Mesh = Mesh.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in grid.get_triangles():
		for triangle in row:
			if triangle.get_parent() != null:
				continue
			
			for vertex in triangle.get_vertices():
				surface_tool.add_vertex(vertex.get_vector_at_height(0.0))
	
	surface_tool.generate_normals()
	var _err = surface_tool.commit(sea_mesh)
	
	return sea_mesh

static func _get_river_surface_mesh(river: EdgePath, lake_stage: LakeStage) -> Mesh:
	var ratio = 0.5
	var surface_tool: SurfaceTool = SurfaceTool.new()
	var river_mesh: Mesh = Mesh.new()
	var drop_depth = Vector3.DOWN * river.get_eroded_depth() * ratio
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for triangle in river.get_adjacent_triangles():
		for vertex in triangle.get_vertices():
			if lake_stage.point_in_water_body(vertex):
				surface_tool.add_vertex(vertex.get_uneroded_vector())
			else:
				surface_tool.add_vertex(vertex.get_uneroded_vector() + drop_depth)
	
	surface_tool.generate_normals()
	var _err = surface_tool.commit(river_mesh)
	
	return river_mesh
