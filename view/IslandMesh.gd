extends MeshInstance

func _ready() -> void:

	var grid = Grid.new(10.0, 100, Color8(255,255,255,255))
	var island_mesh: Mesh = get_mesh_from_grid(grid)
	set_mesh(island_mesh)
	
func get_mesh_from_grid(grid: Grid) -> Mesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	var island_mesh: Mesh = Mesh.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in grid.get_triangles():
		for triangle in row:
			var color = triangle.get_color()
			color = color if color else grid._color
			surface_tool.add_color(color)
			for vertex in triangle.get_vertices():
				surface_tool.add_vertex(vertex.get_vector())
	surface_tool.generate_normals()
	var _err = surface_tool.commit(island_mesh)
	
	return island_mesh
