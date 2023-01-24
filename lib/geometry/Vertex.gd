class_name Vertex
extends Model
"""Vertex data model and tools"""

var _pos: Vector3
var _connections: Array  # Array[Edge]
var _triangles: Array  # Array[Triangles]
var _height_set: bool = false

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

func add_connection(edge: Object) -> void:  # (edge: Edge)
	if not edge in _connections:
		_connections.append(edge)

func add_polygon(triangle: Object) -> void:  # (triangle: Triangle)
	if not triangle in _triangles:
		_triangles.append(triangle)

func get_vector() -> Vector3:
	return _pos

func get_connections() -> Array:
	return _connections

func get_triangles() -> Array:  # -> Array[Triangle]
	return _triangles

static func sort_vert_inv_hortz(a: Vertex, b: Vertex) -> bool:
	"""This will sort by Y desc, then X asc"""
	if a._pos.y > b._pos.y:
		return true
	elif a._pos.y == b._pos.y and a._pos.x < b._pos.x:
			return true
	return false
