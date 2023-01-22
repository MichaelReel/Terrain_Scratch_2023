class_name Edge
extends Model
"""Edge data model and tools"""

var _a: Vertex
var _b: Vertex
var _borders: Array
var _river: Array

func _init(a: Vertex, b: Vertex) -> void:
	if Vertex.sort_vert_inv_hortz(a, b):
		_a = a
		_b = b
	else:
		_a = b
		_b = a
	_borders = []

func get_points() -> Array:
	return [_a, _b]

func get_bordering_triangles() -> Array:
	return _borders

func has_point(point: Vertex) -> bool:
	return _a == point or _b == point

func shared_point(other: Edge):  # -> Vertex | null:
	if _a == other._a or _a == other._b:
		return _a
	if _b == other._a or _b == other._b:
		return _b
	return null

func shares_a_point_with(other: Edge) -> bool:
	return (
		other.has_point(_a) or
		other.has_point(_b)
	)

func set_border_of(triangle: Triangle) -> void:
	if not triangle in _borders:
		_borders.append(triangle)
