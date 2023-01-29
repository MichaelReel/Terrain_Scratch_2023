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

func _init(
	random_seed: int,
	edge_length: float,
	edges_across: int,
	land_cell_limit: int,
	river_count: int,
	debug_color_map: DebugColorDict
) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed
	grid = Grid.new(edge_length, edges_across, debug_color_map.base_color)
	_island_stage = IslandStage.new(grid,  debug_color_map.land_color, land_cell_limit, rng.randi())
	_regions_stage = RegionStage.new(_island_stage.get_region(), debug_color_map.region_colors, rng.randi())
	_lake_stage = LakeStage.new(_regions_stage, debug_color_map.lake_colors, rng.randi())
	_height_stage = HeightStage.new(_island_stage.get_region(), _lake_stage)
	_river_stage = RiverStage.new(grid, _lake_stage, river_count, debug_color_map.river_color, rng.randi())


func perform() -> void:
	var stages = [
		_island_stage,
		_regions_stage,
		_lake_stage,
		_height_stage,
		_river_stage,
	]
	
	for stage in stages:
		stage.perform()
		emit_signal("stage_complete", stage)
	
	emit_signal("all_stages_complete")
