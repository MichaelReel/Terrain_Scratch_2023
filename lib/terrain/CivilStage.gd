class_name CivilStage
extends Stage

var _grid: Grid
var _lake_stage: LakeStage
var _settlement_cells: Array = []  # Array[SearchCell]
var _road_paths: Array = []  # Array[TrianglePath]
var _junctions: Array = []  #Array[Triangle]
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

func get_junctions() -> Array:  # -> Array[Triangle]
	return _junctions

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
	var picked_settlements: Array = []
	var diff: int = len(_settlement_cells) / 4
	for i in range(0, len(_settlement_cells), diff):
		picked_settlements.append(_settlement_cells[i])
	return picked_settlements

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
	
	# Go through each path and remove it if it serves no purpose
	var remove_roads: Array = []  # Array[TrianglePath]
	for road in _road_paths:
		if road.purposeless():
			remove_roads.append(road)
	
	for road in remove_roads:
		road.remove_from_cells()
		_road_paths.erase(road)

func _get_path_from_survey(origin: Triangle, survey: Dictionary) -> TrianglePath:
	# (survey: Dictionary[Triangle, SearchCell]) -> Array[triangle]
	
	var path: TrianglePath = TrianglePath.new(origin)
	var origin_cell: SearchCell = survey[origin]
	var road_cell: SearchCell = origin_cell.get_path()
	if not road_cell:
		return path
	while road_cell.get_cost() > 0.0:
		var triangle = road_cell.get_triangle()
		var has_road: bool = triangle.contains_road()
		triangle.add_road(self)
		path.append(triangle)
		road_cell = road_cell.get_path()
		
		# If this triangle already had road, we can just end our path here
		if has_road:
			triangle.set_junction()
			_junctions.append(triangle)
			break
	
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
