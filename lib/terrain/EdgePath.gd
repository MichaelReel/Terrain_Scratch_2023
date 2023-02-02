class_name EdgePath
extends Object
"""Terrain structure describing a chain of edges and points across a grid"""

var _edge_array: Array = []  # Array[Edge]
var _point_array: Array = []  # Array[Vertex]
var _adjacent_triangles: Array = []  # Array[Triangle]
var _lake_stage: LakeStage
var _eroded_depth: float = 0.0


func _init(starting_point: Vertex, lake_stage: LakeStage) -> void:
	_point_array.append(starting_point)
	_lake_stage = lake_stage
	_update_adjacent_triangles()

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

func get_adjacent_mesh_triangles(width: float) -> Array:  # -> Array[Array[Vector]]
	"""Get an array of arrays of vector3 within the sides of the path, scaled to width"""
	var adjacent_scaled_triangles_as_vector_arrays: Array = []
	for terrain_triangle in _adjacent_triangles:
		# Special rules for heads and mouths
		
		# Create a modifed "triangle", to the relative width of the river
		var vector_array: Array = []
		var edge_midstream: Object = _edge_on_midstream(terrain_triangle)
		var point_midstream = _one_point_on_midstream(terrain_triangle)
		for terrain_vertex in terrain_triangle.get_vertices():
			if terrain_vertex in _point_array:
				vector_array.append(_inner_surface_vector(terrain_vertex, width))
			else:
				if edge_midstream:
					vector_array.append(
						_outer_surface_vector_single_point(terrain_vertex, width, edge_midstream)
					)
				else:
					vector_array.append(
						_outer_surface_vector_edge_point(terrain_vertex, width, point_midstream)
					)
		adjacent_scaled_triangles_as_vector_arrays.append(vector_array)
	return adjacent_scaled_triangles_as_vector_arrays

func _inner_surface_vector(terrain_vertex: Vertex, ratio: float) -> Vector3:
	# Points in the path move up relative to the erosion and the relative width
	#   but stay as they are horizontally
	var terrain_pos = terrain_vertex.get_vector()
	return Vector3(
		terrain_pos.x, 
		terrain_pos.y + (ratio * terrain_vertex.get_erosion()),
		terrain_pos.z
	)

func _edge_on_midstream(triangle: Triangle) -> Object:  # Edge | null
	"""Returns an Edge if this triangle has an edge along the midstream of the path"""
	for edge in triangle.get_edges():
		if edge in _edge_array:
			return edge
	return null

func _one_point_on_midstream(triangle: Triangle) -> Object:  # Vertex | null
	"""Returns an Vertex if this triangle has an point along the midstream of the path"""
	for point in triangle.get_vertices():
		if point in _point_array:
			return point
	return null

func _outer_surface_vector_single_point(terrain_vertex: Vertex, ratio: float, opposite: Edge) -> Vector3:
	"""Returns the modifed path edge point, this point is moved towards the center of the opposite edge"""
	# Edge of river surface, move towards midstream
	var terrain_pos = terrain_vertex.get_vector()
	var opposite_center = opposite.get_center()
	return lerp(opposite_center, terrain_pos, ratio)

func _outer_surface_vector_edge_point(terrain_vertex: Vertex, ratio: float, opposite: Vertex) -> Vector3:
	"""Returns the modified path edge point, this point is moved towards the path"""
	# Find the correct edge to move this point towards
	# will be an edge off the opposite point and also in the path
	for edge in opposite.get_connections():
		if not edge in _edge_array:
			continue
		for triangle in edge.get_bordering_triangles():
			if terrain_vertex in triangle.get_vertices():
				var edge_midstream: Object = _edge_on_midstream(triangle)
				return _outer_surface_vector_single_point(terrain_vertex, ratio, edge_midstream)
	
	# Edge of river surface failover
	var terrain_pos = terrain_vertex.get_vector()
	return Vector3(terrain_pos.x, terrain_pos.y, terrain_pos.z)

func _update_adjacent_triangles() -> void:
	var new_point = _point_array.back()
	
	for triangle in new_point.get_triangles():
		if triangle in _adjacent_triangles:
			continue
		if _lake_stage.triangle_in_water_body(triangle):
			continue
			
		_adjacent_triangles.append(triangle)
