class_name CivilStage
extends Stage

var _grid: Grid
var _lake_stage: LakeStage
var _settlement_cells: Array = []  # Array[SearchCell]
var _road_paths: Array = []  # Array[Array[Triangle]]

func _init(grid: Grid, lake_stage: LakeStage):
	_grid = grid
	_lake_stage = lake_stage

func _to_string() -> String:
	return "Civil Stage"

func perform() -> void:
	_locate_settlements()
	var start_settlement = _pick_starting_settlement()
	_lay_road_network(start_settlement)

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

func _pick_starting_settlement() -> Triangle:
	# Might want to put some rules here, but for now just return any cell
	return _settlement_cells[0]

func _lay_road_network(start_settlement: Triangle) -> void:
	# Debug notes: The dictionary here will show as "null" even if not null while debugging
	var survey_results: Dictionary = _get_cell_cost_survey_from(start_settlement)
	
	# For each town we can create a path back to the start
	for settlement_cell in _settlement_cells:
		var road_path = _get_path_from_survey(settlement_cell, survey_results)
		_road_paths.append(road_path)
	
		# Set road cells as road cells
		for triangle in road_path:
			triangle.set_contains_road()

func _get_path_from_survey(destination: Triangle, survey: Dictionary) -> Array:
	# (survey: Dictionary[Triangle, SearchCell]) -> Array[triangle]
	
	var path: Array = []  # Array[Triangle]
	var destination_cell: SearchCell = survey[destination]
	var road_cell: SearchCell = destination_cell.get_path()
	if not road_cell:
		return path
	while road_cell.get_cost() > 0.0:
		path.append(road_cell.get_triangle())
		road_cell = road_cell.get_path()
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
			var journey_cost: float = search_cell.get_cost() + 1.0
			# TODO: Up the cost if crossing a river, or going up/downz   a steep slope
			
			# Check if there's an exising cell, if so, update it if cost is cheaper
			if neighbour_tri in search_cell_dictionary.keys():
				var neighbour_search_cell = search_cell_dictionary[neighbour_tri]
				if neighbour_search_cell.get_cost() > journey_cost:
					neighbour_search_cell.update_path(journey_cost, search_cell) 
				continue
			
			# Push a new search cell into the queue
			var new_search_cell = SearchCell.new(neighbour_tri, journey_cost, search_cell)
			# TODO: Insert into the list sorted by journey cost
			search_queue.push_back(new_search_cell)
			search_cell_dictionary[neighbour_tri] = new_search_cell
	
	return search_cell_dictionary
