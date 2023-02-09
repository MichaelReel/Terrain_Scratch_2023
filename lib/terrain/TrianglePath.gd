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

func get_path_pair_edges() -> Array:  # -> Array[Array[Edge]]
	"""Return a list of edge pairs, where the edges are in clockwise rotation order"""
	
	if no_path():
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

func purposeless() -> bool:
	return (
		no_path() 
		or _destination == null
		or _origin == null
		# or not _destination.is_junction_or_settlement()
		or not _origin.is_junction_or_settlement()
	)

func other_paths_crossed() -> bool:
	# Go through the path triangles, check if the triangle has more than one path
	for triangle in _path:
		if triangle.road_crossing():
			return true
	return false

func remove_from_cells() -> void:
	for triangle in _path:
		triangle.remove_road(self)

static func sort_path_length(a: TrianglePath, b: TrianglePath) -> bool:
	return len(a._path) < len(b._path)
