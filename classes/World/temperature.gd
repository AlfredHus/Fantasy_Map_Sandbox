class_name Temperature
extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func calculate_temperatures(grid: Grid, map: Map):

	grid.cells["temp"].resize(grid.cells["i"].size())
	grid.cells["temp"].fill(0)

	# In Azgaars code, these are set via options. For now, they are HARDCODED. 
	# FIXME: Make it so these values can be configured.
	var temperature_equator: float = 25.0
	var temperature_north_pole: float = -40.0
	var temperature_south_pole: float = -22.0
	
	var tropics = [16, -20]  # Tropics zone
	var tropical_gradient: float = 0.15

	var temp_north_tropic: float = temperature_equator - tropics[0] * tropical_gradient
	var northern_gradient: float = (temp_north_tropic - temperature_north_pole) / (90 - tropics[0])

	var temp_south_tropic: float = temperature_equator + tropics[1] * tropical_gradient
	var southern_gradient: float = (temp_south_tropic - temperature_south_pole) / (90 + tropics[1])

	var height_exponent_input = 2.0 # HARDCODED. FIXME. Need to make this configurable
	var exponent: float = height_exponent_input

	for row_cell_id in range(0, grid.cells["i"].size(), grid.cells_x):
		var y: float = grid.points[row_cell_id][1]
		var lat_N = map.map_coordinates["latitude_N"]
		var lat_T = map.map_coordinates["latitude_T"]
		var row_latitude: float = map.map_coordinates["latitude_N"] - (y / grid.height) * map.map_coordinates["latitude_T"]
		var temp_sea_level1: float = calculate_sea_level_temp(row_latitude, temperature_equator, tropics, temperature_north_pole, temperature_south_pole)
		var temp_sea_level: float
		
		## Calculate sea level
		var is_tropical: bool = row_latitude <= 16 and row_latitude >= -20
		if is_tropical:
			temp_sea_level = temperature_equator - abs(row_latitude) * 0.15
		elif row_latitude > 0:
			temp_sea_level = temperature_equator - tropics[0] * 0.15 - (row_latitude - tropics[0]) * ((temperature_equator - tropics[0] * 0.15 - temperature_north_pole) / (90 - tropics[0]))
		else:
			temp_sea_level = temperature_equator + tropics[1] * 0.15 + (row_latitude - tropics[1]) * ((temperature_equator + tropics[1] * 0.15 - temperature_south_pole) / (90 + tropics[1]))
		
		# DEBUG.temperature:
		print(str(GeneralUtilities.rn(row_latitude)) + "° sea temperature: " + str(GeneralUtilities.rn(temp_sea_level)) + "°C")

		for cell_id in range(row_cell_id, row_cell_id + grid.cells_x):
			var temp_altitude_drop: float = get_altitude_temperature_drop(grid.cells["h"][cell_id], height_exponent_input)
			grid.cells["temp"][cell_id] = int(clamp(temp_sea_level - temp_altitude_drop, -128, 127))

func calculate_sea_level_temp(latitude: float, temperature_equator: float,  tropics: Array, temperature_north_pole, temperature_south_pole) -> float:
	var is_tropical: bool = latitude <= 16 and latitude >= -20
	if is_tropical:
		return temperature_equator - abs(latitude) * 0.15

	if latitude > 0:
		return temperature_equator - tropics[0] * 0.15 - (latitude - tropics[0]) * ((temperature_equator - tropics[0] * 0.15 - temperature_north_pole) / (90 - tropics[0]))
	else:
		return temperature_equator + tropics[1] * 0.15 + (latitude - tropics[1]) * ((temperature_equator + tropics[1] * 0.15 - temperature_south_pole) / (90 + tropics[1]))


func get_altitude_temperature_drop(h: float, height_exponent_input: float) -> float:
	if h < 20:
		return 0
	var height = pow(h - 18, height_exponent_input)
	return GeneralUtilities.rn((height / 1000) * 6.5)
