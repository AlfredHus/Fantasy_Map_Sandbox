class_name Temperature
extends Node

## [b]Class:[/b] [code]Temperature[/code][br]
##
## This class handles temperature calculations for Azgaar style maps. It determines
## temperature values based on latitude and elevation, applying predefined
## temperature settings for the equator, tropics, and poles.
## The temperature represents an annual mean temperature.[br]
##
## Additional details can be found here:
## [url]https://azgaar.wordpress.com/2017/06/30/biomes-generation-and-rendering/[/url][br]
##
## [b]Usage:[/b][br]
## This class populates the [code]grid.cells.["temp"][/code] array[br]
## It modifies the grid's temperature values based on its elevation and latitude.[br]
##
## [b]Temperature Zones:[/b][br]
## - Equator temperature: [code]27.0°C[/code][br]
## - North Pole temperature: [code]-30.0°C[/code][br]
## - South Pole temperature: [code]-15.0°C[/code][br]
## - Tropics range: [code]16°N to 20°S[/code][br]
##
## [b]To-Do:[/b][br]
## - Currently, temperature values are HARDCODED.[br]
## - Future improvement: Make these values configurable through options.[br]

# In Azgaars code, these are set via options. For now, they are HARDCODED. 
# FIXME: Make it so these values can be configured.
var _temperature_equator: float = 27.0
var _temperature_north_pole: float = -30.0
var _temperature_south_pole: float = -15.0
var _tropics = [16.0, -20.0]  # Tropics zone

## Computes and assigns temperature values to each grid cell based on latitude[br]
## and elevation. This function first calculates the base temperature at sea[br]
## level and then adjusts it according to altitude.[br]
##
## [b]Temperature Calculation:[/b][br]
## - Uses predefined temperature values for the equator, tropics, and poles.[br]
## - Calculates temperature gradients for both hemispheres.[br]
## - Applies altitude-based temperature drop using an exponent modifier.[br]
##
## [b]Parameters:[/b][br]
## - [param grid]: The [code]Grid[/code] object representing the map's cell data.[br]
## - [param map]: The [code]Map[/code] object containing global map parameters[br]
##   such as latitude boundaries.[br]
##
## [b]Process:[/b][br]
## 1. Initializes the temperature array in [code]grid.cells["temp"][/code].[br]
## 2. Determines latitude-based temperature using [code]calculate_sea_level_temp()[/code].[br]
## 3. Iterates through the grid cells, adjusting temperature for elevation[br]
##    using [code]get_altitude_temperature_drop()[/code].[br]
## 4. Clamps final temperatures to a range of [-128, 127].[br]
##
## [b]Returns:[/b][br]
## - This function modifies [code]grid.cells["temp"][/code] in place.[br]
#
func calculate_temperatures(grid: Grid, map: Map):

	# Setup temperature array 
	grid.cells["temp"].resize(grid.cells["i"].size())
	grid.cells["temp"].fill(0)

	const TROPICAL_GRADIANT: float = 0.15

	var temp_north_tropic: float = _temperature_equator - _tropics[0] * TROPICAL_GRADIANT
	var northern_gradient: float = (temp_north_tropic - _temperature_north_pole) / (90 - _tropics[0])

	var temp_south_tropic: float = _temperature_equator + _tropics[1] * TROPICAL_GRADIANT
	var southern_gradient: float = (temp_south_tropic - _temperature_south_pole) / (90 + _tropics[1])

	var height_exponent_input: float = 2.0 # HARDCODED. FIXME. Need to make this configurable
	var exponent: float = height_exponent_input

	var grid_size: int = grid.cells["i"].size() 
	#for row_cell_id in range(0, grid.cells["i"].size(), grid.cells_x):
	for row_cell_id in range(0, grid_size, grid.cells_x):
		var y: float = grid.points[row_cell_id][1]
		#var lat_N: float = map.map_coordinates["latitude_N"]
		#var lat_T: float = map.map_coordinates["latitude_T"]
		var row_latitude: float = map.map_coordinates["latitude_N"] - (y / grid.height) * map.map_coordinates["latitude_T"]
		var temp_sea_level: float = calculate_sea_level_temp(row_latitude)
		
		# DEBUG.temperature:
		print(str(GeneralUtilities.rn(row_latitude)) + "° sea temperature: " + str(GeneralUtilities.rn(temp_sea_level)) + "°C")

		for cell_id in range(row_cell_id, row_cell_id + grid.cells_x):
			# Get the temperature drop for the cell height
			var temp_altitude_drop: float = get_altitude_temperature_drop(grid.cells["h"][cell_id], height_exponent_input)
			# 
			grid.cells["temp"][cell_id] = int(clamp(temp_sea_level - temp_altitude_drop, -128, 127))

## [b]Function:[/b] [code]calculate_sea_level_temp[/code][br]
##
## Calculates the approximate sea level temperature based on latitude.[br]
## This function estimates temperature variations using predefined values[br]
## for the equator, tropics, and poles. The temperature decreases as you[br]
## move away from the equator and follows a linear gradient beyond the tropics.[br]
##
## [b]Formula:[/b][br]
## - Tropical region: [code]temperature = _temperature_equator - abs(latitude) * 0.15[/code][br]
## - Northern Hemisphere: Uses a linear gradient from the tropics to the pole.[br]
## - Southern Hemisphere: Similar gradient adjusted for southern latitudes.[br]
##
## [b]Parameters:[/b][br]
## - [param latitude]: The latitude at which to calculate sea level temperature.[br]
##   - Positive values represent the Northern Hemisphere.[br]
##   - Negative values represent the Southern Hemisphere.[br]
##
## [b]Returns:[/b][br]
## - [b]float[/b]: The estimated sea level temperature at the given latitude.[br]
#
func calculate_sea_level_temp(latitude: float) -> float:
	var is_tropical: bool = latitude <= 16 and latitude >= -20
	if is_tropical:
		return _temperature_equator - abs(latitude) * 0.15

	if latitude > 0:
		return _temperature_equator - _tropics[0] * 0.15 - (latitude - _tropics[0]) * ((_temperature_equator - _tropics[0] * 0.15 - _temperature_north_pole) / (90 - _tropics[0]))
	else:
		return _temperature_equator + _tropics[1] * 0.15 + (latitude - _tropics[1]) * ((_temperature_equator + _tropics[1] * 0.15 - _temperature_south_pole) / (90 + _tropics[1]))

## Calculates the temperature drop based on altitude. Temperature drops by 6.5°C 
## per 1km of altitude. This is known as the lapse rate.[br]
##
## This function estimates the decrease in temperature due to altitude
## using an exponential formula. The temperature drop follows a lapse rate[
## where higher elevations lead to cooler temperatures.[br]
##
## [b]Parameters:[/b][br]
## - [param h]: The height (altitude) of the cell.[br]
## - [param height_exponent_input]: The exponent used for altitude-based 
## temperature drop calculation.[br]
##
## [b]Returns:[/b][br]
## - [b]float[/b]: The temperature drop in degrees Celsius.[br]
##
func get_altitude_temperature_drop(h: float, height_exponent_input: float) -> float:
	# The earths atmosphere lowest zone is called the troposphere,
	# which has a average height of 18 kilometers (11 miles). This is where
	# earths weather mostly occurs.
	# https://en.wikipedia.org/wiki/Troposphere
	# The temperature of the troposphere decreases with increased altitude, 
	# and the rate of decrease in air temperature is measured with the 
	# Environmental Lapse Rate which is defined as 6.5°C per km as defined by 
	# the International Civil Aviation Organization (ICAO) 
	# Temperature goes down as you go up and vica versa.
	const LAPSE_RATE: float = 6.5
	# Height < 20 is water, so don't calculate the altitude temperature drop
	if h < 20:
		return 0.0	
	# h represents the height in the world which varies from 0 - 100.
	# This meants that height will have a range of 20-18 ** 2 (height can't be
	# less than 20 which is water),  where height_exponent_input = 2 
	# (the default value) to 100-18 **2. Height range = 4 to 6724.
	var height = pow(h - 18, height_exponent_input)
	# Based on the above range, the range of values that can be returned is:
	# 0 to 43.706
	return GeneralUtilities.rn((height / 1000.0) * LAPSE_RATE)
