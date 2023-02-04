class_name DebugColorDict
extends Resource

export (Color) var base_color: Color = Color8(24, 64, 24, 255)
export (Color) var land_color: Color = Color8(32, 96, 32, 255)
export (PoolColorArray) var region_colors := PoolColorArray([
	land_color, # Color8(  0,   0, 192, 255),
	land_color, # Color8(  0, 192,   0, 255),
	land_color, # Color8(192,   0,   0, 255),
	land_color, # Color8(  0, 192, 192, 255),
	land_color, # Color8(192, 192,   0, 255),
	land_color, # Color8(192,   0, 192, 255),
])
export (Color) var river_color: Color = Color8(32, 32, 192, 255)
export (Color) var head_color: Color = river_color # Color8(0, 0, 86, 255)
export (Color) var mouth_color: Color = river_color # Color8(128, 128, 255, 255)
export (PoolColorArray) var lake_colors := PoolColorArray([
	river_color, # Color8( 48,  48, 192, 255),
	river_color, # Color8( 32,  32, 192, 255),
	river_color, # Color8( 16,  16, 192, 255),
])
export (Color) var settlement_color: Color = Color8(64, 64, 64, 255)
