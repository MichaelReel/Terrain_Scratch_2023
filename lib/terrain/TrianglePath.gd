class_name TrianglePath
extends Object

var _origin: Triangle
var _destination: Triangle
var _path: Array = []  # Array[Triangle]


func _init(origin: Triangle) -> void:
	_origin = origin

func append(road: Triangle) -> void:
	_path.append(road)

func complete(destination: Triangle) -> void:
	_destination = destination
	# Set road cells as road cells
	for triangle in _path:
		triangle.set_contains_road()

func get_path_pair_edges() -> Array:  # -> Array[Array[Edge]]
	"""Return a list of edge pairs, where the edges are in clockwise rotation order"""
	
	if _path.empty():
		return []
	
	var edge_list: Array = [_origin.get_shared_edge(_path.front())]  # Array[Edge]
	for i in range(len(_path) - 1):
		edge_list.append(_path[i].get_shared_edge(_path[i+1]))
	edge_list.append(_path.back().get_shared_edge(_destination))
	
	var edge_pair_list: Array = []  # Array[Array[Edge]]
	for i in range(len(edge_list) - 1):
		edge_pair_list.append(_path[i].order_clockwise(edge_list[i], edge_list[i + 1]))
	
	return edge_pair_list

func no_path() -> bool:
	return _path.empty()
