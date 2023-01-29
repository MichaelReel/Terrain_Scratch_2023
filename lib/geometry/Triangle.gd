class_name Triangle
extends Model
"""Triangle data model and tools"""

var _points: Array  # Array[Vertex]
var _index_row: int
var _index_col: int
var _edges: Array  # Array[Edge]
var _neighbours: Array = []  # Array[Triangle]
var _corner_neighbours: Array = []  # Array[Triangle]
var _parent: Object = null

func _init(points: Array, index_col: int, index_row: int) -> void:  # points: Array[Vertex]
	_points = points
	_index_col = index_col
	_index_row = index_row
	_edges = [
		points[0].get_connection_to_point(points[1]),
		points[1].get_connection_to_point(points[2]),
		points[2].get_connection_to_point(points[0]),
	]
	for point in _points:
		point.add_polygon(self)
	for edge in _edges:
		edge.set_border_of(self)

func _to_string() -> String:
	return "%d,%d: %s" % [_index_row, _index_col, _points]

func update_neighbours_from_edges() -> void:
	for edge in _edges:
		for tri in edge.get_bordering_triangles():
			if tri != self:
				_neighbours.append(tri)
	for point in _points:
		for tri in point.get_triangles():
			if not tri in _neighbours and not tri in _corner_neighbours and not tri == self:
				_corner_neighbours.append(tri)

func get_neighbours_with_parent(parent: Object) -> Array:  # (parent: Region | null) -> Array[Triangle]
	var parented_neighbours = []
	for neighbour in _neighbours:
		if neighbour.get_parent() == parent:
			parented_neighbours.append(neighbour)
	return parented_neighbours

func count_neighbours_with_parent(parent: Object) -> int:  # (parent: Region | null)
	return get_neighbours_with_parent(parent).size()

func get_corner_neighbours_with_parent(parent: Object) -> Array:  # (parent: Region | null) -> Array[Triangle]
	var parented_corner_neighbours = []
	for corner_neighbour in _corner_neighbours:
		if corner_neighbour.get_parent() == parent:
			parented_corner_neighbours.append(corner_neighbour)
	return parented_corner_neighbours

func count_corner_neighbours_with_parent(parent: Object) -> int:  # (parent: Region | null)
	return get_corner_neighbours_with_parent(parent).size()

func get_neighbour_borders_with_parent(parent: Object) -> Array:  # (parent: Region | null) -> Array[Edge]
	var borders : Array = []
	for edge in _edges:
		for tri in edge.get_bordering_triangles():
			if tri != self and tri.get_parent() == parent:
				borders.append(edge)
	return borders

func set_parent(parent: Object) -> void:  # (parent: Region | null)
	_parent = parent

func is_on_grid_boundary() -> bool:
	return len(_neighbours) < len(_edges)

func get_edges_on_grid_boundary() -> Array:
	var boundary_edges : Array = []
	for edge in _edges:
		if len(edge.get_bordering_triangles()) == 1:
			boundary_edges.append(edge)
	return boundary_edges

func get_color():  # -> Color | null:
	if _parent:
		return _parent.get_color()
	return null

func get_vertices() -> Array:  # Array[Vertex]
	return _points

func get_river_vertex_colors(river_color: Color, null_color: Color, head_color: Color, mouth_color: Color) -> Dictionary:  # Dictionary[Vertex, Color]
	var point_color_dict := {}
	for point in _points:
		point_color_dict[point] = get_color()
		if point_color_dict[point] == null:
			point_color_dict[point] = null_color
		if point.has_river():
			point_color_dict[point] = river_color
		if point.is_head():
			point_color_dict[point] = head_color
		if point.is_mouth():
			point_color_dict[point] = mouth_color
	return point_color_dict

func get_edges() -> Array:  # Array[Edge]
	return _edges

func get_parent() -> Object:  # -> Region | null
	return _parent

func get_neighbours() -> Array:  # -> Array[Triangle]
	return _neighbours

func is_surrounded_by_region(region: Object) -> bool:  # (region: Region)
	for point in _points:
		if not point.has_polygon_with_parent(region):
			return false
	return true
