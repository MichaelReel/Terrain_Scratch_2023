class_name EdgePath
extends Object
"""Terrain structure describing a chain of edges and points across a grid"""

var _edge_array: Array = []  # Array[Edge]
var _point_array: Array = []  # Array[Vertex]

func _init(starting_point: Vertex) -> void:
	_point_array.append(starting_point)

func _to_string() -> String:
	return str(_point_array)

func extend_by_edge(edge: Edge) -> void:
	_edge_array.append(edge)
	_point_array.append(edge.other_point(_point_array.back()))
	edge.set_river(self)
	
func extend_by_vertex(point: Vertex) -> void:
	var edge = _point_array.back().get_connection_to_point(point)
	if edge:
		extend_by_edge(edge)

func edge_length() -> int:
	return len(_edge_array)

func point_length() -> int:
	return len(_point_array)

func erode(erode_depth: float) -> void:
	for point in _point_array:
		point.erode(erode_depth)
