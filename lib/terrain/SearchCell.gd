class_name SearchCell
extends Object

var _triangle: Triangle
var _cost_to_nearest: float
var _path_to_nearest: SearchCell

func _init(triangle: Triangle, cost: float, path: Object = null) -> void:  # (path: SearchCell | null)
	_triangle = triangle
	_cost_to_nearest = cost
	_path_to_nearest = path

func get_triangle() -> Triangle:
	return _triangle

func get_cost() -> float:
	return _cost_to_nearest

func get_path() -> Object:  # -> SearchCell | null
	return _path_to_nearest
