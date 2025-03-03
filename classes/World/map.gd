class_name Map
extends Node
## Code ported from Azgaars Fanatasy Map
## https://github.com/Azgaar/Fantasy-Map-Generator


var size
var latitude
var longitude
var map_coordinates = {}

# Code ported from main.js:
# https://github.com/Azgaar/Fantasy-Map-Generator/blob/master/main.js
func get_size_and_latitude(template: String, grid: Grid) -> Array:
	
	# FIXME: I don't handle the pre-defined images (europe, etc) since I 
	# don't have the image import code working. Will add those when I 
	# get it working.
	
	# JAVASCRIPT CODE:  const part = grid.features.some(f => f.land && f.border)
	var part: bool = false
	# if land goes over map borders
	for f in grid.features:
		if typeof(f) != TYPE_DICTIONARY:
			continue
		if f["land"] and f["border"]:
			part = true
			break 
	
	var maximum = 80 if part == true else 100
	
	# JAVASCRIPT CODE : const lat = () => gauss(P(0.5) ? 40 : 60, 20, 25, 75);
	var expected = 40 if ProbabilityUtilities.P(0.5) else 60
	var lat1 = ProbabilityUtilities.gauss(expected, 20, 25, 75) # latitude shift
	# Single line version using annonymous function
	var lat = func() -> float:
		return ProbabilityUtilities.gauss(40 if ProbabilityUtilities.P(0.5) else 60, 20, 25, 75)
	
	if (!part):
		if template == "pangea":
			return [100, 50, 50];
		if template == "shattered" && ProbabilityUtilities.P(0.7):
			return [100, 50, 50];
		if template == "continents" && ProbabilityUtilities.P(0.5):
			return [100, 50, 50];
		if template == "archipelago" && ProbabilityUtilities.P(0.35):
			return [100, 50, 50];
		if template == "highIsland" && ProbabilityUtilities.P(0.25):
			return [100, 50, 50];
		if template == "lowIsland" && ProbabilityUtilities.P(0.1):
			return [100, 50, 50];	
			
	if (template == "pangea"):
		return [ProbabilityUtilities.gauss(70, 20, 30, maximum), lat.call(), 50];
	if (template == "volcano"):
		return [ProbabilityUtilities.gauss(20, 20, 10, maximum), lat.call(), 50];
	if (template == "mediterranean"):
		return [ProbabilityUtilities.gauss(25, 30, 15, 80), lat.call(), 50];
	if (template == "peninsula"):
		return [ProbabilityUtilities.gauss(15, 15, 5, 80), lat.call(), 50];
	if (template == "isthmus"):
		return [ProbabilityUtilities.gauss(15, 20, 3, 80), lat.call(), 50];
	if (template == "atoll"):
		return [ProbabilityUtilities.gauss(3, 2, 1, 5, 1), lat.call(), 50];

	return[ProbabilityUtilities.gauss(30, 20, 15, maximum), lat.call(), 50]
	
# Code ported from main.js:
# https://github.com/Azgaar/Fantasy-Map-Generator/blob/master/main.js
# define map size and position based on template
func define_map_size(template: String, grid: Grid):
	var values: Array = get_size_and_latitude(template, grid)
	size = values[0]
	latitude = values[1]
	longitude = values[2]

# Code ported from main.js:
# https://github.com/Azgaar/Fantasy-Map-Generator/blob/master/main.js
# Calculate map position on globe	
func calculate_map_coordinates(grid:Grid):
	var size_fraction = size/100
	var latitude_shift = latitude/100
	var longitude_shift = longitude/100
	
	var latitude_T = GeneralUtilities.rn(size_fraction * 180, 1)
	var latitude_N = GeneralUtilities.rn(90 - (180 - latitude_T) * latitude_shift, 1)
	var latitude_S = GeneralUtilities.rn(latitude_N - latitude_T, 1)
	
	var longitude_T = GeneralUtilities.rn(min((grid.width/grid.height) * latitude_T, 360), 1)
	var longitude_E = GeneralUtilities.rn(180 - (360 - longitude_T) * longitude_shift, 1)
	var longitude_W = GeneralUtilities.rn(longitude_E - longitude_T, 1)
	
	map_coordinates = {
		"latitude_T" : latitude_T,
		"latitude_N" : latitude_N,
		"latitude_S": latitude_S,
		"longitude_T": longitude_T,
		"longitude_E ": longitude_E,
		"longitude_W": longitude_W	
	}
	
	
	
