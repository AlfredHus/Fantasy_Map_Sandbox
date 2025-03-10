class_name Precipitation
extends Node

var MAX_PASSABLE_ELEVATION: int = 85



#  simplest precipitation model
func generate_precipitation(grid: Grid, map: Map):
	
	#var wind_directions = {}
	var counter = 0
	
	grid.cells["prec"].resize(grid.cells["i"].size())
	grid.cells["prec"].fill(0)
	var cells_number_modifier: float = pow(grid.cells_desired / 10000.0, 0.25)
	# HARDCODED value of 123 which looks like it comes from the UI in javascript
	var prec_input_modifier: float = 123.0 / 100.0
	var modifier: float = cells_number_modifier * prec_input_modifier

	var westerly: Array = []
	var easterly: Array = []
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
	var i: int = 0
	# DEBUG: The loop looks like it is working correctly
	for c in range(0, grid.cells["i"].size(), grid.cells_x):
		var lat: float = map.map_coordinates["latitude_N"] - (float(i) / grid.cells_y) * map.map_coordinates["latitude_T"]
		var lat_band: int = floor((abs(lat) - 1.0) / 5.0)
		var lat_mod: int = latitude_modifier[lat_band]
		# 30d tiers from 0 to 5 from N to S
		var wind_tier: int = floor((abs(lat - 89.0)) / 30.0) 
		var wind_directions: Dictionary = get_wind_directions(wind_tier)

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
		counter += 1
	if easterly.size() > 0:
		pass_wind(easterly, 120.0 * modifier, -1, grid.cells_x, grid, modifier)
		counter += 1
		
	var vertT = southerly + northerly
	if northerly > 0:
		var bandN: int = int((abs(map.map_coordinates["latitude_N"]) - 1) / 5)
		var lat_modN: float = Statistics.mean(latitude_modifier) if map.map_coordinates["latitude_T"] > 60 else latitude_modifier[bandN]
		var max_precN: float = (float(northerly) / vertT) * 60.0 * modifier * lat_modN
		pass_wind(range(0, grid.cells_x), max_precN, grid.cells_x, grid.cells_y, grid, modifier)
		counter += 1

	if southerly > 0:
		var bandS: int = int((abs(map.map_coordinates["latitude_S"]) - 1) / 5)
		var lat_modS: float = Statistics.mean(latitude_modifier) if map.map_coordinates["latitude_T"] > 60 else latitude_modifier[bandS]
		var max_precS: float = (float(southerly) / vertT) * 60.0 * modifier * lat_modS
		pass_wind(range(grid.cells["i"].size() - grid.cells_x, grid.cells["i"].size()), max_precS, -grid.cells_x, grid.cells_y, grid, modifier)
		counter += 1
	pass
	
func get_wind_directions(tier: int) -> Dictionary:
	# default options, based on Earth data, In Azgaars code there is a 
	# dictionary that holds these values in main.js. 
	var winds: Array = [225, 45, 225, 315, 135, 315]
	var angle: int = winds[tier]
	return {
		"is_west": angle > 40 and angle < 140,
		"is_east": angle > 220 and angle < 320,
		"is_north": angle > 100 and angle < 260,
		"is_south": angle > 280 or angle < 80
	}
	
func pass_wind(source, max_prec, next, steps, grid, modifier):
	var max_prec_init: float = max_prec
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
	# need to make sure we handle both cases explicitly so we don't get
	# an error
	for first in source:
		if first is Array and first.size() > 1:
			max_prec = min(max_prec_init * first[1], 255)
			first = first[0]

		var humidity: float = max_prec - grid.cells["h"][first] # initial water amount
		if humidity <= 0:
			continue # if first cell in row is too elevated, consider wind dry

		var current: int = first
		for s in range(steps):
			#if current < 0 or current >= grid.cells["h"].size():
				#break # prevent invalid index access

			if grid.cells.temp[current] < -5:
				continue # no flux in permafrost
			# In the Azgaar javascript code, "current +  next" is used in the 
			# arrays as an index.For example, 
			# "if (cells.h[current + next] >= 20) {" it is possible that 
			# current _ next results in a out of bounds value. In Javascript
			# this resuls in an undefined being generated and undefined in 
			# it statement turns into a falsy which lets the if statement
			# fail with no out of bounds error being generated.
			# In gdscript which is strictly typed, this results in an error.
			# So for this situation, we need to check to see if current + next
			# is valid, otherwise we ensure that it fails.
			# Something to remember about how Javascript works when translating
			# Javascript code to gdscript.
			var next_index: int = current + next
			var next_is_valid: bool = next_index >= 0 and next_index < grid.cells["h"].size()

			if grid.cells.h[current] < 20:
				# Water cell
				if next_is_valid and grid.cells["h"][next_index] >= 20:
					grid.cells["prec"][next_index] += max(humidity / randf_range(10, 20), 1) # Coastal precipitation
					var temp1 = grid.cells["prec"][next_index]
					#print ("water cell: temp1:", temp1)
					pass
				else:
					humidity = min(humidity + 5 * modifier, max_prec) # Wind gets more humidity passing water cell
					#if humidity == 0:
						#print ("Water cell humidity = 0")
					grid.cells["prec"][current] += 5 * modifier # Water cells precipitation
					var temp2 = grid.cells["prec"][current]
					#print ("else water cell: temp2:", temp2, " humidity: ",humidity )
					pass
			else:
				# Land cell
				var is_passable: bool = next_is_valid and grid.cells["h"][next_index] <= MAX_PASSABLE_ELEVATION
				#var is_passable = true
				#var altitude = grid.cells["h"][next_index]
				#if humidity == 0:
					#print ("Land cell humidity 1 = 0")
				var precipitation: float = get_precipitation(humidity, current, next, modifier, grid) if is_passable else humidity
				grid.cells["prec"][current] += precipitation
				var temp3 = grid.cells["prec"][current]
				var evaporation: int = 1 if precipitation > 1.5 else 0 # Some humidity evaporates back
				#print ("Humidity: ", humidity)
				humidity = GeneralUtilities.minmax(humidity - precipitation + evaporation, 0, max_prec) if is_passable else 0
				#if humidity == 0:
					#print ("Land cell humidity 2 = 0")
				#print ("land cell: temp3:", temp3, "humidity: ", humidity, " precipitation: ", precipitation)
			current += next # Move to next cell
	

			
func get_precipitation(humidity: float, i: int, n: int, modifier: float, grid: Grid) -> float:
	var normal_loss: float = max(humidity / (10.0 * modifier), 1)
	if i + n >= grid.cells.h.size():
		return humidity  # Prevents out-of-bounds access
	var diff: int = max(grid.cells["h"][i + n] - grid.cells["h"][i], 0)
	var h1 = grid.cells["h"][i + n] 
	var h2 = grid.cells["h"][i]
	var temp2 = grid.cells["h"][i + n] / 70.0
	var mod: float = grid.cells["h"][i + n] / 70.0 **2
	var temp3: float = normal_loss + diff * mod
	var temp = GeneralUtilities.minmax(normal_loss + diff * mod, 1.0, humidity)
	#if temp == 0:
		#print ("normal_loss: ", normal_loss, " temp2: ", temp2, " temp3: ", temp, "humidity: ", humidity)
	#return clamp(normal_loss + diff * mod, 1.0, humidity)
	return GeneralUtilities.minmax(normal_loss + diff * mod, 1.0, humidity)
	
	
