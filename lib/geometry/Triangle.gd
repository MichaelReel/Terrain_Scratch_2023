class_name Triangle
extends Model
"""Triangle data model and tools"""

var _points: Array
var _index_row: int
var _index_col: int
var _edges: Array
var _neighbours: Array = []
var _corner_neighbours: Array = []
var _parent: Object = null

func _init(points: Array, index_col: int, index_row: int) -> void:
	_points = points
	_index_col = index_col
	_index_row = index_row
	_edges = [
		points[0].get_connection_to_point(points[1]),
		points[1].get_connection_to_point(points[2]),
		points[2].get_connection_to_point(points[0]),
	]
	for point in _points:
		point.add_polygon(self)
	for edge in _edges:
		edge.set_border_of(self)

func update_neighbours_from_edges() -> void:
	for edge in _edges:
		for tri in edge.get_bordering_triangles():
			if tri != self:
				_neighbours.append(tri)
	for point in _points:
		for tri in point.get_triangles():
			if not tri in _neighbours and not tri in _corner_neighbours and not tri == self:
				_corner_neighbours.append(tri)

func _to_string() -> String:
	return "%d,%d: %s" % [_index_row, _index_col, _points]
