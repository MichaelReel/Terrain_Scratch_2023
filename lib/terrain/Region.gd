class_name Region
extends Utils
"""A specific area that a grid cell can belong to"""

var _parent  # Region | null
var _color: Color
var _cells: Array = []  # Array[Triangle]
var _perimeter_points: Array = []  # Array[Vertex]
var _perimeter_lines: Array = []  # Array[Edge]
var _inner_perimeter: Array = []  # Array[Vertex]
var _region_front: Array  # Array[Triangle
var _exit_point: Vertex
var _perimeter_height: float = 0.0
var _perimeter_outlined: bool = false

func _init(start_triangle: Triangle, color: Color, parent: Region = null) -> void:
	_parent = parent
	_color = color
	_region_front = [start_triangle]

func add_triangle_as_cell(triangle: Triangle) -> void:
	# Integrate this cell from the the region edges
	triangle.set_parent(self)
	_cells.append(triangle)
	_region_front.erase(triangle)
	
	# Add neighbours with specific parent to the region frontier
	for neighbour in triangle.get_neighbours_with_parent(_parent):
		if not neighbour in _region_front:
			_region_front.append(neighbour)
			
	# Preload edges on the grid boundary into perimeter_lines
	if triangle.is_on_grid_boundary():
		_perimeter_lines.append_array(triangle.get_edges_on_grid_boundary())

func remove_triangle_as_cell(triangle: Triangle) -> void:
	triangle.set_parent(_parent)
	_cells.erase(triangle)

func expand_into_parent(rng: RandomNumberGenerator) -> void:
	shuffle(rng, _region_front)
	add_triangle_as_cell(_region_front.back())

func expand_margins() -> void:
	var border_cells: Array = []
	for cell in _cells:
		if cell.count_neighbours_with_parent(self) < 3:
			border_cells.append(cell)
		elif cell.count_corner_neighbours_with_parent(self) < 9:
			border_cells.append(cell)
	# Return the border cells to the parent
	for border_cell in border_cells:
		remove_triangle_as_cell(border_cell)

func get_some_triangles(count: int, rng: RandomNumberGenerator) -> Array:  # -> Array[Triangle]
	"""Get upto count random cells from this region"""
	var actual_count := int(min(count, len(_cells)))
	var random_cells = _cells.slice(0, actual_count)
	shuffle(rng, random_cells)
	return random_cells

func identify_perimeter_points() -> void:
	var region_points : Array = _get_points_in_region()
	for point in region_points:
		if point.has_polygon_with_parent(_parent):
			_perimeter_points.append(point)
	
	for outer_point in _perimeter_points:
		for point in outer_point.get_connected_points():
			if (
				not point in _perimeter_points 
				and point in region_points
				and not point in _inner_perimeter
			):
				_inner_perimeter.append(point)

func get_color() -> Color:
	return _color

func get_outer_perimeter_points() -> Array:
	return _perimeter_points

func get_inner_perimeter_points() -> Array:
	return _inner_perimeter

func has_exit_point() -> bool:
	return true if _exit_point else false
	
func set_exit_point(point: Vertex) -> void:
	_exit_point = point
	
func get_exit_point() -> Vertex:
	return _exit_point

func get_cell_count() -> int:
	return len(_cells)

func set_water_height(perimeter_height: float) -> void:
	_perimeter_height = perimeter_height

func get_perimeter_lines() -> Array:  # -> Array[Vertex]
	if _perimeter_outlined:
		return _perimeter_lines
		
	var region_front := _region_front.duplicate()
	
	# using the _region_front, get all the lines joining to parented cells
	while not region_front.empty():
		var outer_triangle : Triangle = region_front.pop_back()
		var borders : Array = outer_triangle.get_neighbour_borders_with_parent(self)
		_perimeter_lines.append_array(borders)
	
	# Identify chains by tracking each point in series of perimeter lines
	var chains: Array = _get_chains_from_lines(_perimeter_lines)
	
	# Set the _perimeter to the longest chain
	var max_chain: Array = chains.back()
	for chain in chains:
		if len(max_chain) < len(chain):
			max_chain = chain
			
	_perimeter_lines = max_chain
	
	# Include threshold triangles that are not on the perimeter path
	_add_non_perimeter_boundaries()
	
	_perimeter_outlined = true
	return _perimeter_lines

func _add_non_perimeter_boundaries() -> void:
	"""
	Find triangles on the boundary front that aren't against the perimeter and
	assume they're inside the total shape. Add them and any unparented neighbours
	to the blob.
	"""
	# TODO: Potentially refactor this with add_triangle_as_cell
	var remove_from_front: Array = []
	# Discover all the non perimeter triangles
	for front_triangle in _region_front:
		var has_edge_in_perimeter := false
		for edge in front_triangle.get_edges():
			if edge in _perimeter_lines:
				has_edge_in_perimeter = true
				break
		# This frontier triangle does not have an edge on the main perimeter
		# This is basically add_triangle_as_cell but with a delayed erase
		if not has_edge_in_perimeter:
			front_triangle.set_parent(self)
			_cells.append(front_triangle)
			remove_from_front.append(front_triangle)
			# Is there are any triangles adjacent that are null parented, add to end of _region_front
			for neighbour_triangle in front_triangle.get_neighbours():
				if neighbour_triangle.get_parent() == null and not neighbour_triangle in _region_front:
					_region_front.append(neighbour_triangle)
	
	# Remove non-perimeter triangles from the frontier, delayed erase
	for front_triangle in remove_from_front:
		_region_front.erase(front_triangle)

func _get_points_in_region() -> Array:  # Array[Vertex]
	"""Get all the points within the region"""
	var points: Array = []
	for triangle in _cells:
		for point in triangle.get_points():
			if not point in points:
				points.append(point)
	return points
