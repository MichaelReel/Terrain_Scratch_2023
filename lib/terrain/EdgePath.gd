class_name EdgePath
extends Object
"""Terrain structure describing a chain of edges and points across a grid"""

var _edge_array: Array = []  # Array[Edge]
var _point_array: Array = []  # Array[Vertex]
var _adjacent_triangles: Array = []  # Array[Triangle]
var _eroded_depth: float = 0.0


func _init(starting_point: Vertex) -> void:
	_point_array.append(starting_point)

func _to_string() -> String:
	return str(_point_array)

func extend_by_edge(edge: Edge) -> void:
	_edge_array.append(edge)
	_point_array.append(edge.other_point(_point_array.back()))
	edge.set_river(self)
	_update_adjacent_triangles()
	
func extend_by_vertex(point: Vertex) -> void:
	var edge = _point_array.back().get_connection_to_point(point)
	if edge:
		extend_by_edge(edge)

func edge_length() -> int:
	return len(_edge_array)

func point_length() -> int:
	return len(_point_array)

func erode(erode_depth: float) -> void:
	_eroded_depth += erode_depth
	for point in _point_array:
		point.erode(erode_depth)

func get_eroded_depth() -> float:
	return _eroded_depth

func get_points() -> Array:  # -> Array[Vertex]
	return _point_array

func get_adjacent_triangles() -> Array:  # -> Array[Triangle]
	return _adjacent_triangles

func _update_adjacent_triangles() -> void:
	var new_edge = _edge_array.back()
#	var new_point = _point_array.back()

	for triangle in new_edge.get_bordering_triangles():
		if not triangle in _adjacent_triangles:
			_adjacent_triangles.append(triangle)
	
	
	
