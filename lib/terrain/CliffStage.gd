class_name CliffStage
extends Stage
"""Look for features in the terrain that could be exaggerated"""

var _grid: Grid
var _lake_stage: LakeStage
var _color: Color
var _min_slope: float
var _edge_cliff_top_triangle_map: Dictionary = {}  # Dictionary[Edge, Triangle]
var _point_cliff_top_triangles_map: Dictionary = {}  # Dictionary[Vertex, Array[Triangle]]
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
				#       Would have add additional river edges at least
				continue
			
			# Only include cells that are a given minimum slope
			var height_diff: float = cell.get_height_diff()
			if height_diff >= _min_slope:
				var low_edge: Edge = cell.get_lowest_edge()
				var low_point: Vertex = low_edge.lowest_end_point()
				
				# Only include the bottom edges and points of steep slopes
				if low_edge.get_height_diff() <= (height_diff * 0.5):
					cliff_edges.append(low_edge)
					_edge_cliff_top_triangle_map[low_edge] = cell
				elif low_point.get_instance_id() in _point_cliff_top_triangles_map.keys():
					_point_cliff_top_triangles_map[low_point.get_instance_id()].append(cell)
				else:
					_point_cliff_top_triangles_map[low_point.get_instance_id()] = [cell]
	
	# Before processing into chains, remove *both* copies of any duplicated edges
	var dupes: Array = []  # Array[Edge]
	
	for i in range(len(cliff_edges)):
		var edge = cliff_edges[i]
		if cliff_edges.find(edge, i + 1) >= 0:
			dupes.append(edge)
	
	for dupe in dupes:
		# remove both cliff edge copied
		cliff_edges.erase(dupe)
		cliff_edges.erase(dupe)
		# may need to update triangles with cliff points
		# TODO
	
	# Find all the cliff chains
	var chains: Array = _extract_chains_from_edges(cliff_edges)  # Array[Array[Edge]]
	
	for chain in chains:
		# Only keep chains longer than 3 edges
		if len(chain) > 2:
			_cliff_chains.append(chain)
	
func _setup_debug_draw() -> void:
	for cliff_chain in _cliff_chains:
		# Setup the debug draw
		for i in range(len(cliff_chain)):
			var cliff_edge: Edge = cliff_chain[i]
			_edge_cliff_top_triangle_map[cliff_edge].set_cliff_edge(cliff_edge)
			if i + 1 < len(cliff_chain):
				var cliff_point: Vertex = cliff_edge.shared_point(cliff_chain[i + 1])
				if cliff_point.get_instance_id() in _point_cliff_top_triangles_map.keys():
					for triangle in _point_cliff_top_triangles_map[cliff_point.get_instance_id()]:
						triangle.set_cliff_point(cliff_point)
			
	
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
		# Get a pair of edges
		var previous_edge: Edge = cliff_chain[i]
		var next_edge: Edge = cliff_chain[i + 1]
		
		# Find the shared point and end points
		var mid_point: Vertex = previous_edge.shared_point(next_edge)
		var previous_point: Vertex = previous_edge.other_point(mid_point)
		var next_point: Vertex = next_edge.other_point(mid_point)
		
		# Identify the top and the base triangles around the mid point
		var previous_cliff_top_edge_triangle: Triangle = _edge_cliff_top_triangle_map[previous_edge]
		var previous_cliff_base_edge_triangle: Triangle = previous_edge.other_triangle(previous_cliff_top_edge_triangle)
		var next_cliff_top_edge_triangle: Triangle = _edge_cliff_top_triangle_map[next_edge]
		var next_cliff_base_edge_triangle: Triangle = next_edge.other_triangle(next_cliff_top_edge_triangle)
		var cliff_top_point_triangles: Array = (
			_point_cliff_top_triangles_map[mid_point.get_instance_id()]
			if mid_point.get_instance_id() in _point_cliff_top_triangles_map.keys()
			else []
		)
		var known_triangles: Array = cliff_top_point_triangles + [
			previous_cliff_top_edge_triangle, 
			previous_cliff_base_edge_triangle, 
			next_cliff_top_edge_triangle, 
			next_cliff_base_edge_triangle
		]
		var cliff_base_point_triangles: Array = []
		for triangle in mid_point.get_triangles():
			if not triangle in known_triangles:
				cliff_base_point_triangles.append(triangle)
		
		# Create a new edge and replace the edge from the previous point 
		# to the mid point at the bottom of this cliff
		var new_previous_point: Vertex = previous_point
		if not vertices_in_new_line.empty():
			new_previous_point = vertices_in_new_line.back()
		
		var new_cliff_base_mid_point: Vertex = next_point
		if next_edge != cliff_chain.back():
			new_cliff_base_mid_point = mid_point.duplicate_to(Vertex.new())
			vertices_in_new_line.append(new_cliff_base_mid_point)
		
		var new_cliff_base_prev_edge: Edge = Edge.new(new_previous_point, new_cliff_base_mid_point)
		previous_cliff_base_edge_triangle.replace_existing_edge_with(previous_edge, new_cliff_base_prev_edge)
		
		# Also have to replace the point in the triangle "touching" the base of the cliff
		for triangle in cliff_base_point_triangles:
			triangle.replace_existing_point_with(mid_point, new_cliff_base_mid_point)

		# If we're at the end of the chain, we also need to replace the edge on the next (last) edge
		if next_edge == cliff_chain.back():
			# next point is the last point, can just reuse
			var new_cliff_base_next_edge: Edge = Edge.new(new_cliff_base_mid_point, next_point)
			next_cliff_base_edge_triangle.replace_existing_edge_with(next_edge, new_cliff_base_next_edge)
		
		# Raise the top of cliff point upwards
		var additional_height: float = 5.0  # TODO: Need more rules around this
		mid_point.raise_terrain(additional_height)
		
		
		
