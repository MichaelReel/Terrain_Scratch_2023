class_name LakeStage
extends Stage

var _region_stage: RegionStage
var _colors: PoolColorArray
var _regions: Array = []  # Array[Region]
var _expansion_done: bool = false
var _margins_done: bool = false
var _perimeter_done: bool = false
var _rng := RandomNumberGenerator.new()


func _init(region_stage: RegionStage, colors: PoolColorArray, rng_seed: int):
	_region_stage = region_stage
	_colors = colors
	_rng.seed = rng_seed

func _to_string() -> String:
	return "Lake Stage"

func perform() -> void:
	_setup_regions()
	
	while not _expansion_done or not _perimeter_done or not _margins_done:
		if not _expansion_done:
			var done = true
			for region in _regions:
				if not region.expand_into_parent(_rng):
					done = false
			if done:
				_expansion_done = true
			continue
		
		if not _margins_done:
			_expand_margins()
			_margins_done = true
			
		if not _perimeter_done:
			for region in _regions:
				var _lines: Array = region.get_perimeter_lines(false)
			_perimeter_done = true

func _expand_margins() -> void:
	for region in _regions:
		region.expand_margins()

func _setup_regions() -> void:
	for parent_region in _region_stage.get_regions():
		# The parent region might not be big enough to have subregions
		var start_triangles = parent_region.get_some_triangles(_rng, len(_colors))
		for i in range(len(start_triangles)):
			_regions.append(Region.new(start_triangles[i], _colors[i], parent_region))
