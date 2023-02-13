class_name CliffStage
extends Stage
"""Look for features in the terrain that could be exaggerated"""

var _grid: Grid
var _lake_stage: LakeStage
var _color: Color
var _min_slope: float
var _edge_cliff_top_triangle_map: Dictionary = {}  # Dictionary[Edge, Triangle]
var _cliff_chains: Array = []  # Array[Array[Edge]]

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
	_get_all_the_cliff_chains()
	
	_setup_debug_draw()
	
	_split_grid_along_cliff_lines()

func _get_all_the_cliff_chains() -> void:
	"""Identify and record likely places we can extend the landscape to create cliffs"""
	var cliff_edges: Array = []  # Array[Edge]
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
					_edge_cliff_top_triangle_map[low_edge] = cell
	
	# Find all the cliff chains
	var chains: Array = _extract_chains_from_edges(cliff_edges)  # Array[Array[Edge]]
	
	for chain in chains:
		# Only keep chains longer than 3 edges
		if len(chain) > 2:
			_cliff_chains.append(chain)
	
func _setup_debug_draw() -> void:
	for cliff_chain in _cliff_chains:
		# Setup the debug draw
		for cliff_edge in cliff_chain:
			_edge_cliff_top_triangle_map[cliff_edge].set_cliff_edge(cliff_edge)
	
func _split_grid_along_cliff_lines() -> void:
	"""Separate the grid where the cliffs are located"""
	# This is likely to break so much stuff. This will be interesting.
	for cliff_chain in _cliff_chains:
		_split_grid_along_cliff_line(cliff_chain)

func _split_grid_along_cliff_line(cliff_chain: Array) -> void:  # (cliff_chain: Array[Edge])
	# for each non-end point in the cliff line, we need to 
	#  - create an extra point
	#  - create an extra edge
	#  - separate the points vertically
	#  - probably link it with it's twin point in some funky way
	var vertices_in_new_line: Array = []  # Array[Vertex]
	
	for i in range(len(cliff_chain) - 1):
		# Gather info about the existing terrain elements
		var previous_edge: Edge = cliff_chain[i]
		var next_edge: Edge = cliff_chain[i + 1]
		var point: Vertex = previous_edge.shared_point(next_edge)
		var previous_point: Vertex = previous_edge.other_point(point)
		var next_point: Vertex = next_edge.other_point(point)
		var cliff_top_triangle: Triangle = _edge_cliff_top_triangle_map[previous_edge]
		var cliff_base_triangle: Triangle = previous_edge.other_triangle(cliff_top_triangle)
		
		# Create a new edge and replace it in the grid at the bottom of this cliff
		# TODO: Something is missing here:
		var new_previous_point: Vertex = previous_point
		if not vertices_in_new_line.empty():
			new_previous_point = vertices_in_new_line.back()
		
		var new_cliff_base_point: Vertex = next_point
		if next_edge != cliff_chain.back():
			new_cliff_base_point = point.duplicate_to(Vertex.new(0.0, 0.0))
			vertices_in_new_line.append(new_cliff_base_point)
		
		var new_cliff_base_edge: Edge = Edge.new(new_previous_point, new_cliff_base_point)
		cliff_base_triangle.replace_existing_edge_with(previous_edge, new_cliff_base_edge)
		
		# Also have to replace the point in the triangle "touching" the base of the cliff
		
		# TODO
		
		# Raise the top of cliff point upwards
		var additional_height: float = 5.0  # TODO: Need more rules around this
		point.set_height(point.get_height() + additional_height)
		
		
		
