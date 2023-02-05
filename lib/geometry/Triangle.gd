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
var _is_potential_settlement: bool = false
var _contains_road: bool = false

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

func get_river_vertex_colors(debug_color_dict: DebugColorDict) -> Dictionary:  # Dictionary[Vertex, Color]
	"""This is just for creating the development and debug meshes"""
	var river_color = debug_color_dict.river_color
	var null_color = debug_color_dict.base_color
	var head_color = debug_color_dict.head_color
	var mouth_color = debug_color_dict.mouth_color
	var settlement_color = debug_color_dict.settlement_color
	var road_color = debug_color_dict.road_color
	var point_color_dict := {}
	
	if _is_potential_settlement:
		for point in _points:
			point_color_dict[point] = settlement_color
		return point_color_dict
	
	if _contains_road:
		for point in _points:
			point_color_dict[point] = road_color
		return point_color_dict
		
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

func get_shared_edge(triangle: Triangle) -> Object:  # -> Edge | null
	for edge in _edges:
		if edge.other_triangle(self) == triangle:
			return edge
	return null

func get_parent() -> Object:  # -> Region | null
	return _parent

func get_neighbours() -> Array:  # -> Array[Triangle]
	return _neighbours

func is_surrounded_by_region(region: Object) -> bool:  # (region: Region)
	for point in _points:
		if not point.has_polygon_with_parent(region):
			return false
	return true

func get_center() -> Vector3:
	return (_points[0].get_vector() + _points[1].get_vector() + _points[2].get_vector()) / 3.0

func get_normal() -> Vector3:
	return (_points[1].get_vector() - _points[0].get_vector()).cross(_points[1].get_vector() - _points[2].get_vector())

func get_height_in_plane(x: float, z: float) -> float:
	var normal: Vector3 = get_normal()
	var position: Vector3 = _points[1].get_vector()
	# nx(x - px) + ny(y - py) + nz(z - pz) = 0
	# ny(y - py) = -(nz(z-pz)+nx(x-px))
	# y - py = -(nz(z-pz)+nx(x-px)) / ny
	# y = py-(nz(z-pz)+nx(x-px))/ny
	return position.y - (normal.z * (z - position.z) + normal.x * (x - position.x)) / normal.y
	
func is_flat() -> bool:
	return (
		_points[0].get_height() == _points[1].get_height() 
		and _points[0].get_height() == _points[2].get_height()
	)

func set_potential_settlement() -> void:
	_is_potential_settlement = true

func set_contains_road() -> void:
	_contains_road = true
