class_name IslandStage
extends Stage
"""Stage for creating the initial island surface area"""

var _grid: Grid
var _island_region: Region
var _cell_limit: int
var _expansion_done: bool = false
var _perimeter_done: bool = false
var _rng := RandomNumberGenerator.new()

func _init(grid: Grid, land_color: Color, cell_limit: int, rng_seed: int):
	_grid = grid
	var start_triangle = grid.get_middle_triangle()
	_island_region = Region.new(start_triangle, land_color)
	_cell_limit = cell_limit
	_rng.seed = rng_seed

func perform() -> void:
	while not _expansion_done or not _perimeter_done:
		if not _expansion_done:
			_island_region.expand_into_parent(_rng)
			
			if _island_region.get_cell_count() >= _cell_limit:
				_expansion_done = true
			continue
		
		if not _perimeter_done:
			var _lines := _island_region.get_perimeter_lines()
			_perimeter_done = true
