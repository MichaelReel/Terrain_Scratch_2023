class_name Vertex
extends Model
"""Vertex data model and tools"""

var _pos: Vector3
var _connections: Array  # Array[Edge]
var _triangles: Array  # Array[Triangles]
var _height_set: bool = false
var _river: Array  # Array[Edge]
var _exit_for: Object = null  # Region | null
var _is_head: bool = false
var _is_mouth: bool = false

func _init(x: float, z: float) -> void:
	_pos = Vector3(x, 0.0, z)
	_connections = []
	_triangles = []

func _to_string() -> String:
	return str(_pos)

func get_connection_to_point(point: Vertex) -> Object:  # --> Edge | null
	for con in _connections:
		if con.other_point(self) == point:
			return con
	return null

func has_connection_to_point(point: Vertex) -> bool:
	return get_connection_to_point(point) != null

func has_polygon_with_parent(parent: Object) -> bool:  # (parent: Region | null)
	for triangle in _triangles:
		if triangle.get_parent() == parent:
			return true
	return false

func height_set() -> bool:
	return _height_set

func set_height(height: float) -> void:
	_height_set = true
	_pos.y = height

func get_height() -> float:
	return _pos.y

func add_connection(edge: Object) -> void:  # (edge: Edge)
	if not edge in _connections:
		_connections.append(edge)

func add_polygon(triangle: Object) -> void:  # (triangle: Triangle)
	if not triangle in _triangles:
		_triangles.append(triangle)

func get_vector() -> Vector3:
	return _pos

func get_vector_at_height(height: float) -> Vector3:
	return Vector3(_pos.x, height, _pos.z)

func get_connections() -> Array:  # -> Array[Edge]
	return _connections

func get_connected_points() -> Array:  # -> Array[Vertex]
	var connected_points := []
	for con in _connections:
		connected_points.append(con.other_point(self))
	return connected_points

func get_triangles() -> Array:  # -> Array[Triangle]
	return _triangles

func set_river(river: Array) -> void:  # (river: Array[Edge])
	_river = river

func has_river() -> bool:
	return true if _river else false

func set_as_exit_point(lake: Object) -> void:  # (lake: Region | null)
	_exit_for = lake

func is_exit() -> bool:
	return true if _exit_for else false

func set_as_head() -> void:
	_is_head = true

func is_head() -> bool:
	return _is_head

func set_as_mouth() -> void:
	_is_mouth = true

func is_mouth() -> bool:
	return _is_mouth

static func sort_vert_inv_hortz(a: Vertex, b: Vertex) -> bool:
	"""This will sort by Y desc, then X asc"""
	if a._pos.y > b._pos.y:
		return true
	elif a._pos.y == b._pos.y and a._pos.x < b._pos.x:
			return true
	return false

static func sort_height(a: Vertex, b: Vertex) -> bool:
	return a.get_height() <= b.get_height()
