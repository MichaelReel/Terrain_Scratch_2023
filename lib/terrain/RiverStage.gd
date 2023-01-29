class_name RiverStage
extends Stage

var _rivers: Array
var _grid: Grid
var _lake_stage: LakeStage
var _river_count: int
var _river_color: Color
var _rng := RandomNumberGenerator.new()

func _init(
	grid: Grid, lake_stage: LakeStage, river_count: int, river_color: Color, rng_seed: int
) -> void:
	_grid = grid
	_lake_stage = lake_stage
	_river_count = river_count
	_river_color = river_color
	_rng.seed = rng_seed

func _to_string() -> String:
	return "River Stage"

func perform() -> void:
	_setup_rivers()

func _setup_rivers():
	_rivers = []
	
	# For each outlet, get the lowest downhill point not _inside_ the lake
	for lake in _lake_stage.get_regions():
		var outlet_point: Vertex = lake.get_exit_point()
		if not outlet_point:
			printerr("Lake didn't have an exit point, probably empty ¯\\_(ツ)_/¯")
			continue
		
		var neighbour_points = outlet_point.get_connected_points()
		neighbour_points.sort_custom(Vertex, "sort_height")
		# Pick the first lowest point (not inside lake) only
		for neighbour in neighbour_points:
			if neighbour.has_polygon_with_parent(lake):
				continue
			
			var river = create_river(outlet_point.get_connection_to_point(neighbour))
			if not river.empty():
				outlet_point.set_as_head()
				_rivers.append(river)
			
			break
	
	# Include some random points that are not in a lake or river already
	var island_points = _grid.get_island_points()
	island_points = _lake_stage.filter_points_no_lake(island_points)
	shuffle(_rng, island_points)
	
	if len(island_points) > _river_count:
		island_points.resize(_river_count)
	
	for island_point in island_points:
		var neighbour_points = island_point.get_connected_points()
		neighbour_points.sort_custom(Vertex, "sort_height")
		
		for neighbour in neighbour_points:
			var river = create_river(island_point.get_connection_to_point(neighbour))
			if not river.empty():
				island_point.set_as_head()
				_rivers.append(river)
			
			break

func create_river(start_edge: Edge) -> Array:
	"""Create a chain of edges that represent a river"""
	if not start_edge:
		return []
	
	var river: Array = []
	# Get the downhill end, then extend until we hit the coast or a lake
	var next_edge: Edge = start_edge
	var connection_point: Vertex = next_edge.lowest_end_point()
	while (
		not _lake_stage.point_in_water_body(connection_point)
		and not next_edge.has_river()
	):
		river.append(next_edge)
		next_edge.set_river(river)
		# Find the next lowest connected point
		var neighbour_points = connection_point.get_connected_points()
		neighbour_points.sort_custom(Vertex, "sort_height")
		var lowest_neighbour = neighbour_points.front()
		next_edge = connection_point.get_connection_to_point(lowest_neighbour)
		connection_point = lowest_neighbour
	
	# Add the last step, unless it's already a river
	if not next_edge.has_river():
		river.append(next_edge)
		next_edge.set_river(river)
		connection_point.set_as_mouth()
	return river
