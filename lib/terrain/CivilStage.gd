class_name CivilStage
extends Stage

var _grid: Grid
var _lake_stage: LakeStage
var _settlement_cells: Array = []  # Array[SearchCell]
var _road_paths: Array = []  # Array[TrianglePath]
var _slope_penalty: float
var _river_penalty: float

const _NORMAL_COST: float = 1.0

func _init(grid: Grid, lake_stage: LakeStage, slope_penalty: float, river_penalty: float):
	_grid = grid
	_lake_stage = lake_stage
	_slope_penalty = slope_penalty
	_river_penalty = river_penalty

func _to_string() -> String:
	return "Civil Stage"

func perform() -> void:
	_locate_settlements()
	var start_settlements = _pick_starting_settlements()
	_lay_road_network(start_settlements)

func get_road_paths() -> Array:  # -> Array[TrianglePath]
	return _road_paths

func _locate_settlements() -> void:
	for row in _grid.get_triangles():
		for triangle in row:
			if not triangle.is_flat():
				continue
			if _lake_stage.triangle_in_water_body(triangle):
				continue
			if not _lake_stage.triangle_beside_water_body(triangle):
				continue
			
			triangle.set_potential_settlement()
			_settlement_cells.append(triangle)

func _pick_starting_settlements() -> Array:  # -> Array[Triangle]
	# Might want to put some rules here, but for now just return any cell
	return [_settlement_cells.front(), _settlement_cells.back()]

func _lay_road_network(start_settlements: Array) -> void:  # (start_settlements: Array[Triangle])
	# Debug notes: The dictionary here will show as "null" even if not null while debugging
	var surveys: Array = []  # Array[Dicionary]
	for start_settlement in start_settlements:
		surveys.append(_get_cell_cost_survey_from(start_settlement))
	
	# For each town we can create a path back to the start
	for settlement_cell in _settlement_cells:
		for survey in surveys:
			var road_path = _get_path_from_survey(settlement_cell, survey)
			_road_paths.append(road_path)

	# TODO: Removing crossing roads will not work
	#       All roads will convene at settlements and cannot help but cross
	#       Some paths will even follow each other for some length
	#       Need to optimise this as we're duplicating a lot of meshes
	
	
#	# Look for places roads cross, and remove the longer paths
#	# When each path is completed, the path is added to the affected triangles
#	# Find the crossings, order the paths by length and remove the longest
#	var crossing_road_list: Array = []  # Array[TrianglePath]
#	for road_path in _road_paths:
#		if road_path.other_paths_crossed():
#			crossing_road_list.append(road_path)
#
#	crossing_road_list.sort_custom(TrianglePath, "sort_path_length")
#
#	while not crossing_road_list.empty():
#		var crossing_road: TrianglePath = crossing_road_list.pop_back()
#		# Check this road hasn't had it's crossings removed already
#		if not crossing_road.other_paths_crossed():
#			continue
#		# Otherwise, remove it from it's triangles and the overall list
#		crossing_road.remove_from_cells()
#		_road_paths.erase(crossing_road)

func _get_path_from_survey(origin: Triangle, survey: Dictionary) -> TrianglePath:
	# (survey: Dictionary[Triangle, SearchCell]) -> Array[triangle]
	
	var path: TrianglePath = TrianglePath.new(origin)
	var origin_cell: SearchCell = survey[origin]
	var road_cell: SearchCell = origin_cell.get_path()
	if not road_cell:
		return path
	while road_cell.get_cost() > 0.0:
		path.append(road_cell.get_triangle())
		road_cell = road_cell.get_path()
	path.complete(road_cell.get_triangle())
	return path

func _get_cell_cost_survey_from(start_settlement: Triangle) -> Dictionary:  # -> Dictionary[Triangle, SearchCell]
	"""A breadth first search from start, try to link each settlement to one of the nearest"""
	var start_search_cell: SearchCell = SearchCell.new(start_settlement, 0.0)
	var search_queue: Array = [start_search_cell]  # Array[SearchCell]
	var search_cell_dictionary: Dictionary = {start_settlement: start_search_cell}  # Dictionary[Triangle, SearchCell]
	
	while not search_queue.empty():
		var search_cell = search_queue.pop_front()
		# Get neighbour cells to valid path
		for neighbour_tri in search_cell.get_triangle().get_neighbours():
			if _lake_stage.triangle_in_water_body(neighbour_tri):
				continue
			
			# Up the cost for each new step
			var journey_cost: float = search_cell.get_cost()
			journey_cost += _NORMAL_COST
			
			# Up the cost if crossing a river
			var shared_edge = search_cell.get_triangle().get_shared_edge(neighbour_tri)
			if shared_edge.has_river():
				journey_cost += _river_penalty
			
			# Up the cost a little if going up/down a slope
			journey_cost += abs(
				neighbour_tri.get_center().y - search_cell.get_triangle().get_center().y
			) * _slope_penalty
			
			# Check if there's an exising cell, if so, update it if cost is cheaper
			if neighbour_tri in search_cell_dictionary.keys():
				var neighbour_search_cell = search_cell_dictionary[neighbour_tri]
				if neighbour_search_cell.get_cost() > journey_cost:
					neighbour_search_cell.update_path(journey_cost, search_cell) 
				continue
			
			# Push a new search cell into the queue
			var new_search_cell = SearchCell.new(neighbour_tri, journey_cost, search_cell)
			search_cell_dictionary[neighbour_tri] = new_search_cell
			
			# Insert into the list sorted by journey cost
			var ind = search_queue.bsearch_custom(new_search_cell, self, "_sort_by_cost")
			search_queue.insert(ind, new_search_cell)
	
	return search_cell_dictionary

static func _sort_by_cost(a: SearchCell, b: SearchCell) -> bool:
	return a.get_cost() < b.get_cost()
