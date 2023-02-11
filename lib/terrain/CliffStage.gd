class_name CliffStage
extends Stage
"""Look for features in the terrain that could be exaggerated"""

var _grid: Grid
var _lake_stage: LakeStage
var _color: Color
var _min_slope: float

func _init(grid: Grid, lake_stage: LakeStage, color: Color, min_slope):
	_grid = grid
	_lake_stage = lake_stage
	_color = color
	_min_slope = min_slope

func _to_string():
	return "Cliff Stage"

func perform() -> void:
	# Scan the above water cells for steep faces
	# Find chains of steep faces that don't cross roads, rivers
	var cliff_edges: Array = []  # Array[Edge]
	var edge_triangle_map: Dictionary = {}  # Dictionary[Edge, Triangle]
	for row in _grid.get_triangles():
		for cell in row:
			if _lake_stage.triangle_in_water_body(cell):
				# Ignore cells in water bodies
				continue
			
			if cell.contains_road():
				# Ignore cells with roads
				continue
			
			if cell.touches_river():
				# Ignore cells with rivers for now
				# TODO: Special waterfall rules for rivers, possibly
				continue
			
			# Only include cells that are a given minimum slope
			var height_diff: float = cell.get_height_diff()
			if height_diff >= _min_slope:
				var low_edge: Edge = cell.get_lowest_edge()
				
				# Only include the bottom edges of steep slopes
				if low_edge.get_height_diff() <= (height_diff * 0.5):
					cliff_edges.append(low_edge)
					edge_triangle_map[low_edge] = cell
	
	# Find all the cliff chains
	var chains: Array = _extract_chains_from_edges(cliff_edges)  # Array[Array[Edge]]
	
	var kept_chains: Array = []  # Array[Array[Edge]]
	for chain in chains:
		# Only keep chains longer than 3 edges
		if len(chain) > 2:
			kept_chains.append(chain)
	
			# Setup the debug draw
			for edge in chain:
				edge_triangle_map[edge].set_cliff_edge(edge)
	
