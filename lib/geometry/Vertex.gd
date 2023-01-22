class_name Vertex
extends Model
"""Vertex data model and tools"""

var _pos: Vector3
var _connections: Array
var _polygons: Array
var _height_set: bool = false

func _init(x: float, z: float) -> void:
	_pos = Vector3(x, 0.0, z)
	_connections = []
	_polygons = []

func add_connection(edge: Edge) -> void:
	if not edge in _connections:
		_connections.append(edge)

func add_polygon(triangle: Triangle) -> void:
	if not triangle in _polygons:
		_polygons.append(triangle)

func get_connection_to_point(point: Vertex):  # --> Edge | null
	for con in _connections:
		if con.other_point(self) == point:
			return con
	return null

func has_connection_to_point(point: Vertex) -> bool:
	return get_connection_to_point(point) != null

func get_triangles() -> Array:
	return _polygons

static func sort_vert_inv_hortz(a: Vertex, b: Vertex) -> bool:
	"""This will sort by Y desc, then X asc"""
	if a._pos.y > b._pos.y:
		return true
	elif a._pos.y == b._pos.y and a._pos.x < b._pos.x:
			return true
	return false
