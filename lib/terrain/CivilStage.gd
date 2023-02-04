class_name CivilStage
extends Stage

var _grid: Grid
var _lake_stage: LakeStage

func _init(grid: Grid, lake_stage: LakeStage):
	_grid = grid
	_lake_stage = lake_stage

func _to_string() -> String:
	return "Civil Stage"

func perform() -> void:
	_locate_settlements()

func _locate_settlements() -> void:
	for row in _grid.get_triangles():
		for triangle in row:
			if not triangle.is_flat():
				continue
			if _lake_stage.triangle_in_water_body(triangle):
				continue
			
			triangle.set_potential_settlement()
