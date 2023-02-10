class_name CliffStage
extends Stage
"""Look for features in the terrain that could be exaggerated"""

var _grid: Grid
var _lake_stage: LakeStage
var _color: Color
var _min_slope: float

func _init(grid: Grid, lake_stage: LakeStage, color: Color, min_slope: float = 5.0):
	_grid = grid
	_lake_stage = lake_stage
	_color = color
	_min_slope = min_slope

func _to_string():
	return "Cliff Stage"

func perform() -> void:
	# Scan the above water cells for steep faces
	for row in _grid.get_triangles():
		for cell in row:
			if _lake_stage.triangle_in_water_body(cell):
				continue
			var height_diff: float = cell.get_height_diff()
			if height_diff >= _min_slope:
				var low_edge: Edge = cell.get_lowest_edge()
				var low_point: Vertex = low_edge.lowest_end_point()
				var edge_height_diff: float = low_edge.get_height_diff()
				if edge_height_diff > (height_diff * 0.5):
					cell.set_cliff_point(low_point)
				else:
					cell.set_cliff_edge(low_edge)
			
	# Find chains of steep faces that don't cross roads
	# Special rules for rivers, possibly
	# For now, mark the triangles for debug
	
