class_name HighlevelTerrain
extends Object
"""
This object is collects stages for generating a highlevel outline of a terrain.
This works out the land edges and the major bodies of water
and can be used as a base reference for other terrain features
"""

signal stage_complete(stage)
signal all_stages_complete()


var grid: Grid
var _island_stage: IslandStage
var _regions_stage: RegionStage
var _lake_stage: LakeStage
var _height_stage: HeightStage
var _river_stage: RiverStage
var _civil_stage: CivilStage

func _init(
	random_seed: int,
	edge_length: float,
	edges_across: int,
	diff_height: float,
	diff_max_multi: int,
	erode_depth: float,
	land_cell_limit: int,
	river_count: int,
	slope_penalty: float,
	river_penalty: float,
	debug_color_map: DebugColorDict
) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed
	grid = Grid.new(edge_length, edges_across, debug_color_map.base_color)
	_island_stage = IslandStage.new(grid,  debug_color_map.land_color, land_cell_limit, rng.randi())
	_regions_stage = RegionStage.new(_island_stage.get_region(), debug_color_map.region_colors, rng.randi())
	_lake_stage = LakeStage.new(_regions_stage, debug_color_map.lake_colors, rng.randi())
	_height_stage = HeightStage.new(_island_stage.get_region(), _lake_stage, diff_height, diff_max_multi, rng.randi())
	_river_stage = RiverStage.new(grid, _lake_stage, river_count, debug_color_map.river_color, erode_depth, rng.randi())
	_civil_stage = CivilStage.new(grid, _lake_stage, slope_penalty, river_penalty)


func perform() -> void:
	var stages = [
		_island_stage,
		_regions_stage,
		_lake_stage,
		_height_stage,
		_river_stage,
		_civil_stage,
	]
	
	for stage in stages:
		stage.perform()
		emit_signal("stage_complete", stage)
	
	emit_signal("all_stages_complete")


func get_lakes() -> Array:  # Array[Region]
	return _lake_stage.get_regions()

func get_rivers() -> Array:  # Array[EdgePath]
	return _river_stage.get_rivers()
