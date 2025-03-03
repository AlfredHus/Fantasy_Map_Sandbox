class_name Precipitation
extends Node

var MAX_PASSABLE_ELEVATION: int = 85



#  simplest precipitation model
func generate_precipitation(grid: Grid, map: Map):
	
	var wind_directions = {}
	
	grid.cells["prec"].resize(grid.cells["i"].size())
	grid.cells["prec"].fill(0)
	var cells_number_modifier: float = pow(grid.cells_desired / 10000.0, 0.25)
	# HARDCODED value of 123 which looks like it comes from the UI in javascript
	var prec_input_modifier: float = 123.0 / 100.0
	var modifier: float = cells_number_modifier * prec_input_modifier

	var westerly = []
	#westerly.resize(grid.cells["i"].size())
	var easterly = []
	#easterly.resize(grid.cells["i"].size())
	var southerly: int = 0
	var northerly: int = 0
	
	# precipitation modifier per latitude band
 	# x4 = 0-5 latitude: wet through the year (rising zone)
	# x2 = 5-20 latitude: wet summer (rising zone), dry winter (sinking zone)
	# x1 = 20-30 latitude: dry all year (sinking zone)
	# x2 = 30-50 latitude: wet winter (rising zone), dry summer (sinking zone)
	# x3 = 50-60 latitude: wet all year (rising zone)
	# x2 = 60-70 latitude: wet summer (rising zone), dry winter (sinking zone)
	# x1 = 70-85 latitude: dry all year (sinking zone)
	# x0.5 = 85-90 latitude: dry all year (sinking zone)
	
	var latitude_modifier = [4.0, 2.0, 2.0, 2.0, 1.0, 1.0, 2.0, 2.0, 2.0, 2.0, 3.0, 3.0, 2.0, 2.0, 1.0, 1.0, 1.0, 0.5]

	
	 # Define wind directions based on latitude and prevailing winds
	var temp = range(0, grid.cells["i"].size(), grid.cells_x)
	var i = 0
	for c in range(0, grid.cells["i"].size(), grid.cells_x):
		#var c = i  # Start index of the row
		var lat = map.map_coordinates["latitude_N"] - (float(i) / grid.cells_y) * map.map_coordinates["latitude_T"]
		var lat_band = floor((abs(lat) - 1.0) / 5.0)
		var lat_mod = latitude_modifier[lat_band]
		# 30d tiers from 0 to 5 from N to S
		var wind_tier = floor((abs(lat - 89.0)) / 30.0) 
		wind_directions = get_wind_directions(wind_tier)

		if wind_directions["is_west"]:
			westerly.append([c, lat_mod, wind_tier])
		if wind_directions["is_east"]:
			easterly.append([c + grid.cells_x - 1, lat_mod, wind_tier])
		if wind_directions["is_north"]:
			northerly += 1
		if wind_directions["is_south"]:
			southerly += 1
		i += 1
			
	# Distribute winds by direction
	if westerly.size() > 0:
		pass_wind(westerly, 120.0 * modifier, 1, grid.cells_x, grid, modifier)
	if easterly.size() > 0:
		pass_wind(easterly, 120.0 * modifier, -1, grid.cells_x, grid, modifier)

	var vertT = southerly + northerly
	if northerly > 0:
		var bandN = int((abs(map.map_coordinates["latitude_N"]) - 1) / 5)
		
		#var lat_modN = latitude_modifier[bandN] if map.map_coordinates["latitude_T"] <= 60 else latitude_modifier.reduce(func(a, b): return a + b) / latitude_modifier.size()
		var lat_modN = Statistics.mean(latitude_modifier) if map.map_coordinates["latitude_T"] > 60 else latitude_modifier[bandN]
		var max_precN = (float(northerly) / vertT) * 60.0 * modifier * lat_modN
		pass_wind(range(0, grid.cells_x), max_precN, grid.cells_x, grid.cells_y, grid, modifier)

	if southerly > 0:
		var bandS = int((abs(map.map_coordinates["latitude_S"]) - 1) / 5)
		#var lat_modS = latitude_modifier[bandS] if map_coordinates["latT"] <= 60 else latitude_modifier.reduce(func(a, b): return a + b) / latitude_modifier.size()
		var lat_modS = Statistics.mean(latitude_modifier) if map.map_coordinates["latitude_T"] > 60 else latitude_modifier[bandS]
		var max_precS = (float(southerly) / vertT) * 60.0 * modifier * lat_modS
		pass_wind(range(grid.cells["i"].size() - grid.cells_x, grid.cells["i"].size()), max_precS, grid.cells_x, grid.cells_y, grid, modifier)

	
func get_wind_directions(tier: int) -> Dictionary:
	# default options, based on Earth data, In Azgaars code there is a 
	# dictionary that holds these values in main.js. 
	var winds: Array = [225, 45, 225, 315, 135, 315]
	var angle = winds[tier]
	return {
		"is_west": angle > 40 and angle < 140,
		"is_east": angle > 220 and angle < 320,
		"is_north": angle > 100 and angle < 260,
		"is_south": angle > 280 or angle < 80
	}
	
func pass_wind(source: Array, max_prec: float, next: int, steps: int, grid: Grid, modifier: float):
	var max_prec_init = max_prec

	# In the javascript code, "source" can either be an array of 
	# tuples, [23,3,6]... or a contiguous array, [0,1,2,3,4]
	# This is the original javascript:
		#for (let first of source) {
		  #if (first[0]) {
			#maxPrec = Math.min(maxPrecInit * first[1], 255);
			#first = first[0];
		  #}
	# If source is a contigous array and the code tries to access the first
	# element, it fails since the first is an integer and not an array
	# This works in javascript, but causes an error in gdscript, so we 
	for first in source:
		var cell_index = first if first is int else first[0]
		var mod = 1.0 if first is int else first[1]
		
		#if first[0]:
		if cell_index != 0:
			#max_prec = min(max_prec_init * first[1], 255)
			#first = first[0]
			max_prec = min(max_prec_init * mod, 255)
			#first = index  # Ensure first is always an integer
		# Ensure the index exists in the grid before accessing it
		if not grid.cells["h"].has(cell_index):
			continue

		# initial water amount
		#var height_index = first[0] if first is Array else first
		#var humidity = max_prec - grid.cells["h"][first]
		var humidity = max_prec - grid.cells["h"][cell_index]
		#  if first cell in row is too elevated consider wind dry
		if humidity <= 0:
			continue

		for s in range(steps):
			#var current = first + (s * next)
			var current = cell_index + (s * next)
			
			# Ensure the current index is valid before accessing it
			if not grid.cells["temp"].has(current) or not grid.cells["h"].has(current):
				continue
			# no flux in permafrost
			if grid.cells["temp"][current] < -5:
				continue
			
			if grid.cells["h"][current] < 20:
				# water cell
				#if grid.cells["h"].has(current + next) and grid.cells["h"][current + next] >= 20:
				#if grid.cells["h"][current + next] >= 20:
					##  coastal precipitation
					#grid.cells["prec"][current + next] += max(humidity / randf_range(10.0, 20.0), 1)
				if grid.cells["h"].has(current + next) and grid.cells["h"][current + next] >= 20:
					# Coastal precipitation
					grid.cells["prec"][current + next] += max(humidity / randf_range(10.0, 20.0), 1)
				else:
					# wind gets more humidity passing water cell
					humidity = min(humidity + 5 * modifier, max_prec)
					# water cells precipitation (need to correctly pour water through lakes)
					grid.cells["prec"][current] += 5 * modifier
				continue

			# land cell
			var is_passable = grid.cells["h"][current + next] <= MAX_PASSABLE_ELEVATION
			
			var precipitation = get_precipitation(humidity, current, next, modifier, grid) if is_passable else humidity
			grid.cells["prec"][current] += precipitation
			var evaporation = 1 if precipitation > 1.5 else 0
			# some humidity evaporates back to the atmosphere
			humidity = clamp(humidity - precipitation + evaporation, 0, max_prec) if is_passable else 0
			
			
func get_precipitation(humidity: float, i: int, n: int, modifier, grid: Grid) -> float:
	var normal_loss = max(humidity / (10.0 * modifier), 1)
	var diff = max(grid.cells["h"][i + n] - grid.cells["h"][i], 0)
	var mod = pow(grid.cells["h"][i + n] / 70.0, 2)
	return clamp(normal_loss + diff * mod, 1, humidity)
