extends Node2D

## A graticule draws a grid pattern that represents latitude and longitude lines on a map.
## This class provides drawing functions and coordinate conversion utilities.
## Provides helper functions to do conversions between latitude/longitude and 
## pixel position
## Latitude lines run east to west and are parallel to each other but measure distance
## north or south. From the equator, latitude increases as you go north or south,
## reaching 90° at each pole. 
## Latitude values (Y-values) range between -90° (South Pole) 
## and +90° (North Pole)
## Longitude lines (also called meridians) run north to south, from pole to pole and 
## measure distance east or west. They converge at the poles.
## Longitude values (X-values) range between -180° and +180°
## Longitude lines are furthest from each other at the equator and meet at the poles.
## When applied to a grid, Latitude is on the Y-axis (North and South) and 
## At the equator, longitude lines are the same distance apart as latitude 
## lines — one degree covers about 111 kilometers (69 miles). 
## By 60 degrees north or south, that distance is down to 56 kilometers (35 miles). 
## By 90 degrees north or south (at the poles), it reaches zero.
## Longitude is on the X-axis (East and West)
## Each degree of latitude is approximately 69 miles (111 kilometers) apart. This 
## gives us a rough scale of distance on the map.
## 
## The latitude/longitude coordinate pair will be [latitude, longitude], which equates to
## the grid pair of [y, x]
## https://en.wikipedia.org/wiki/Graticule_(cartography)
## https://gisgeography.com/latitude-longitude-coordinates/
## https://oceanservice.noaa.gov/facts/longitude.html
## https://oceanservice.noaa.gov/facts/latitude.html
# The latitude/longitude lines assume a equirectangular projection which is a simple
# projection of the globe onto a flat surface. The projection maps meridians (longitude) 
# to equally spaced vertical lines and parallels (latitude) to equally spaced horizontal lines.
# It makes it easy to use latitude and longitude coordinates as a cartesian grid system.


#region Export Variables
@export_group ("General Settings")
 ## Toggle to show/hide the grid
@export var _toggle_grid: bool = false
## Width of the grid in pixels, X-values for longitude     
@export var _grid_width: int = 1920   #
## Height of the grid in pixels, Y-values for latitude 
@export var _grid_height: int = 1080    
## Spacing between longitude (vertical) lines in pixels
@export var _longitude_spacing: int = 120  
## Spacing between latitude (horizontal) lines in pixels
@export var _latitude_spacing: int = 120   
## Color of regular grid lines
@export var _line_color: Color = Color(0.3, 0.3, 0.3, 0.7)  
## Width of regular grid lines
@export var _line_width: float = 1.0       

@export_group("Label Parameters")
## Toggle to show/hide labels
@export var _draw_labels: bool = true      
## Font size for regular labels
@export var _label_font_size: int = 12     
## Color for regular labels
@export var _label_color: Color = Color(0.8, 0.8, 0.8, 1.0)  

@export_group("Geographical Range Parameters")
# These define the real-world coordinates to be mapped to the grid
## Minimum latitude (bottom of grid, southern edge)
@export var _minimum_latitude: float = -90.0   
## Maximum latitude (top of grid, northern edge)
@export var _maximum_latitude: float = 90.0   
## Minimum longitude (left of grid, western edge)
@export var _minimum_longitude: float = -180.0 
## Maximum longitude (right of grid. eastern edge)
@export var _maximum_longitude: float = 180.0  
## Number of decimal places to show in labels
@export var _label_decimal_places: int = 1 

@export_group("Special Line Highlighting Parameters")
# These are used to highlight special geographic locations like Prime
# Meridian, Equator, etc.
## Toggle to highlight important geographic lines
@export var _highlight_special_lines: bool = true  
## Color for special lines (equator, prime meridian, etc.)
@export var _special_line_color: Color = Color(0.8, 0.3, 0.3, 0.8)  
## Width of special lines (thicker than regular)
@export var _special_line_width: float = 2.0      
## Font size for Points of Interest labels
@export var _poi_label_font_size: int = 14      
## Color for Point of Interest labels
@export var _poi_label_color: Color = Color(1.0, 0.8, 0.2, 1.0)  

#endregion


var label_font: Font  # Store the font used for labels
var EARTH_RADIUS: float = 6371.0  # Earth's radius in km, for distance calculations

## Dictionary of special latitudes with their names (in degrees)
## These will be highlighted specially on the grid.
#
# Latitude and Longitude geographic coordinates can be expressed as 
# either Decimal, Minutes, Seconds (DMS), one degree is divided into 
# 60 minutes (of arc), and one minute into 60 seconds (of arc)
# or as Decimal Degrees (DD), decimal fractions of a degree.
# For this grid, DD will be used.
# * NOTE: The location values will be taken from Wikipedia. 
# * There is a certain degree of variability when searching the web.
# https://gisgeography.com/decimal-degrees-dd-minutes-seconds-dms/
# Handy conversion tool to convert DMS to DD: 
# https://www.latlong.net/degrees-minutes-seconds-to-decimal-degrees
#
# The Tropic of Cancer, also known as the Northern Tropic, 
# is the Earth's northernmost circle of latitude where the Sun 
# can be seen directly overhead. This occurs on the June solstice, 
# when the Northern Hemisphere is tilted toward the Sun to its maximum extent
# The Tropic of Cancer is located at 23°26′09.6" (DMS) south of the 
# Equator S or 23.436° S (DD)
# https://en.wikipedia.org/wiki/Tropic_of_Cancer
#
# The Tropic of Capricorn (or the Southern Tropic) is the circle of latitude 
# that contains the subsolar point at the December (or southern) solstice. 
# It is the southernmost latitude where the Sun can be seen directly 
# overhead. It reaches 90 degrees below the horizon at solar midnight 
# on the June Solstice. 
# The Tropic of Capricorn is located at 23°26′09.6" (DMS) south of the 
# Equator S or 23.436° S (DD)
# https://en.wikipedia.org/wiki/Tropic_of_Capricorn
# 
# Both the Tropic of Cancer and the Tropic of Capricorn are considered to 
# be the boundaries of the tropics.
#
# The equator is the circle of latitude that divides Earth into the Northern 
# and Southern hemispheres. It is an imaginary line located at 0 degrees latitude
# https://en.wikipedia.org/wiki/Equator
#
# The Arctic Circle is one of the two polar circles, and the northernmost of 
# the five major circles of latitude as shown on maps of Earth 
# at about 66°33′50.4″ N (DMS) or 66.564° N (DD)
# The Arctic Circle marks the southernmost latitude at which, on the 
# winter solstice in the Northern Hemisphere, the Sun does not rise all day, 
# and on the Northern Hemisphere's summer solstice, the Sun does not set
# https://en.wikipedia.org/wiki/Arctic_Circle
#
# The Antarctic Circle is the most southerly of the five major circles of 
# latitude that mark maps of Earth. The region south of this circle is known 
# as the Antarctic, and the zone immediately to the north is called the 
# Southern Temperate Zone.
# The position of the Antarctic Circle is not fixed and currently 
# runs 66°33′50.4″ (DMS)  or 66.564° N (DD) south of the Equator.
# https://en.wikipedia.org/wiki/Antarctic_Circle
#
# The Arctic Circle and Antarctic Circle are mark the boundaries of the 
# Arctic and Antarctic regions.
#
# Use this structure to set special latitude lines for special locations.
var special_latitudes = {
	0.0: "Equator",
	23.436: "Tropic of Cancer",  
	-23.436: "Tropic of Capricorn", 
	66.564: "Arctic Circle",    
	-66.564: "Antarctic Circle"  
}
## Dictionary of special longitudes with their names (in degrees)
#
# A prime meridian is an arbitrarily chosen meridian (a line of longitude) 
# in a geographic coordinate system at which longitude is defined to be 0°. 
# This divides the body (e.g. Earth) into two hemispheres: 
# the Eastern Hemisphere and the Western Hemisphere (for an 
# east-west notational system). 
# The Prime Meridian runs through Greenwich, England.
# https://en.wikipedia.org/wiki/Prime_meridian
#
# The International Date Line (IDL) is the line extending between the 
# South and North Poles that is the boundary between one 
# calendar day and the next. It does not provide any real value on the 
# fantasy map, but is here more as learning about geography
# The International Date Line roughly follows the 180° line of Longitude
# https://en.wikipedia.org/wiki/International_Date_Line
## Use this structure to set special longitude lines for special locations.
var special_longitudes = {
	0.0: "Prime Meridian",         # 0 degrees - Greenwich Meridian
	-180.0: "International Date Line", # 180° W - International Date Line
	180.0: "International Date Line"   # 180° E - same as -180° (wraps around)
}

## Points of interest with coordinates [latitude, longitude]
## Marked on the grid with special markers
# The Royal Observatory, Greenwich  is an observatory situated on a hill in 
# Greenwich Park in south east London, overlooking the River Thames to the north.
# The location is 51.477° N (DD)
# The North and South Pole are at 90° N and 90° S respectively. For the North Pole,
# all directions are south and all lines of longitude meet there. It works the 
# same for the south pole. For these two values, we set the 
# var points_of_interest = {
# 	"North Pole": [0.0, 90.0],       # North Pole at 90° N
# 	"South Pole": [0.0, -90.0],      # South Pole at 90° S
# 	"Greenwich": [0.0, 51.477],     # Greenwich Observatory (where Prime Meridian passes)
# 	"International Date Line": [180.0, 0.0]  # Point where Date Line crosses Equator
# }
# Use this structure to add markers for points of interest at a specific lat/long coordinate
var points_of_interest = {
	"North Pole": Vector2(90.0, 0.0),       # North Pole at 90° N
	"South Pole": Vector2(-90.0, 0.0),      # South Pole at 90° S
	"Greenwich": Vector2(51.477, 0.0),     # Greenwich Observatory (where Prime Meridian passes)
	"International Date Line": Vector2(0.0, 180.0) # Point where Date Line crosses Equator
}


# This function runs when the node enters the scene tree
func _ready() -> void:
	# Get the default font from Godot's theme system
	label_font = ThemeDB.fallback_font
	#queue_redraw()  # Request the node to be redrawn






# The draw function is called whenever queue_redraw() is called or when the 
# node needs to be redrawn
func _draw() -> void:
	
	if _toggle_grid == true:
		draw_latitude_lines()   # Draw the horizontal latitude lines
		draw_longitude_lines()  # Draw the vertical longitude lines
	
		if _highlight_special_lines:
			draw_special_lines() 
	
		if _draw_labels:
			draw_points_of_interest()
			draw_scale_bar()

## Draw the latitude lines (horizontal lines). Latitude = y-axis (y)
func draw_latitude_lines() -> void:
	
	# Calculate the number of latitude lines based on grid height and spacing
	# For example, if the grid height is 1080 pixels and the latitude spacing is 120 pixels,
	# there will be 9 latitude lines
	var number_latitude_lines: int  = _grid_height / _latitude_spacing

	# Calculate the step size in actual latitude values between lines
	# For example, if the latitude_step is 20, then each latitude will change by 20
	#, i.e., 10.0, 30, 50, etc.
	var latitude_step: float = (_maximum_latitude - _minimum_latitude) / float(number_latitude_lines)
	
	# Draw horizontal lines (latitude). We ensure that we draw a top and bottom latitude line 
	# at 90° and -90°
	for i: int in range(number_latitude_lines + 1):
 		
		# Y position in pixels (as defined in the @export variable)
		var y: float = i * _latitude_spacing 

		# Skip lines outside the visible area
		if y < 0 or y > _grid_height:
			continue
			
		# Draw a line from left to right of the grid at this y position
		draw_line(Vector2(0, y), Vector2(_grid_width, y), _line_color, _line_width)
		
		if _draw_labels:
			# Calculate actual latitude value (inverted since screen Y increases downward)
			# In screen coordinates, Y increases downward, but latitude increases upward
			var latitude_value: float = _maximum_latitude - i * latitude_step
			
			# Format the label with specified decimal places
			var label: String = "%.*f°" % [_label_decimal_places, latitude_value]
			
			# Use fallback font size if _label_font_size is not set properly. Default fallback is 16.
			var font_size: int = ThemeDB.fallback_font_size if _label_font_size <= 0 else _label_font_size
			
			# Draw the label text slightly above the line
			draw_string(label_font, Vector2(5, y - 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _label_color)

			# Draw a marker for the latitude line
			draw_circle(Vector2(5, y), 3, _label_color) 

## Draw the longitude (vertical) lines. This will include a east and west line at
## 180° and -180° respectively> Longitude = x-axis (x)
func draw_longitude_lines() -> void:
	
	# Calculate the number of longitude lines based on grid width and spacing
	var number_longitude_lines: int = _grid_width / _longitude_spacing
	
	# Calculate the step size in actual longitude values between lines
	var longitude_step: float = (_maximum_longitude - _minimum_longitude) / float(number_longitude_lines)
	
	# Draw vertical lines (longitude)
	for i: int in range(number_longitude_lines + 1):
		# X position in pixels (as defined in the @export variable)
		var x: float = i * _longitude_spacing

		# Skip lines outside the visible area
		if x < 0 or x > _grid_width:
			continue
		
		# Draw a line from top to bottom of the grid at this x position
		draw_line(Vector2(x, 0), Vector2(x, _grid_height), _line_color, _line_width)
		
		if _draw_labels:
			# Calculate actual longitude value
			var longitude_value: float = _minimum_longitude + i * longitude_step
			
			# Format the label with specified decimal places
			var label: String = "%.*f°" % [_label_decimal_places, longitude_value]
			
			# Set the font size, using fallback if needed
			var font_size = ThemeDB.fallback_font_size if _label_font_size <= 0 else _label_font_size
			
			# Draw the label text near the top of the line
			draw_string(label_font, Vector2(x + 5, 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _label_color)

## Draw highlighted lines for the special latitudes and longitudes. The position of 
## of the special line is in Decimal Degrees (DD) format in the dictionary. 
## This value is converted to a pixel position on the grid
# The special line structure is in the form of:
# latitude (in Decimal Degree format): "Special Line Name"
# longitude (in Decimal Degree format): "Special Line Name"
func draw_special_lines() -> void:

	# Draw important latitude lines with special formatting
	for latitude in special_latitudes:
		# Only draw if this latitude is within the visible range
		if latitude >= _minimum_latitude and latitude <= _maximum_latitude:
			# Convert the latitude to the pixel Y position on the grid
			var y_pos: float = get_y_from_latitude(latitude)

			# Skip if outside visible area
			if y_pos < 0 or y_pos > _grid_height:
				continue		
			
			# Draw the special line across the full width with special color and width
			draw_line(Vector2(0, y_pos), Vector2(_grid_width, y_pos), _special_line_color, _special_line_width)
			
			# Set font size for the label
			var font_size = ThemeDB.fallback_font_size if _poi_label_font_size <= 0 else _poi_label_font_size
			
			# Draw the name of this special latitude (e.g., "Equator")
			draw_string(label_font, Vector2(_grid_width - 250, y_pos - 10), special_latitudes[latitude], 
						HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _poi_label_color)
	
	# Draw important longitude lines with special formatting
	for longitude in special_longitudes:
		# Only draw if this longitude is within the visible range
		if longitude >= _minimum_longitude and longitude <= _maximum_longitude:
			# Convert the longitude to a pixel X position on the grid
			var x_pos: float = get_x_from_longitude(longitude)
			 
			# Skip if outside visible area
			if x_pos < 0 or x_pos > _grid_width:
				continue
			
			# Draw the special line from top to bottom with special color and width
			draw_line(Vector2(x_pos, 0), Vector2(x_pos, _grid_height), _special_line_color, _special_line_width)
			
			# Set font size for the label
			var font_size:int = ThemeDB.fallback_font_size if _poi_label_font_size <= 0 else _poi_label_font_size
			
			# Draw the name of this special longitude (e.g., "Prime Meridian")
			draw_string(label_font, Vector2(x_pos + 5, 40), special_longitudes[longitude], 
						HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _poi_label_color)

## Draw markers and labels for points of interest (POIs)
# The structure used is in the format of:
# "Point of Interest Name": [latitude, longitude] in Decimal Degree format
func draw_points_of_interest() -> void:

	# Set font size for POI labels
	var font_size: int = ThemeDB.fallback_font_size if _poi_label_font_size <= 0 else _poi_label_font_size
	
	# Loop through all defined points of interest
	for poi_name in points_of_interest:
		# Get coordinates [longitude, latitude]
		# var coords: Array = points_of_interest[poi_name]
		# var x =  points_of_interest[poi_name][0]
		# var y =  points_of_interest[poi_name][1]
		# var longitude: float = coords[0]  # Longitude
		# var latitude: float = coords[1]  # Latitude
		var coordinates: Vector2 = points_of_interest[poi_name]
		var latitude: float =  coordinates.x # Latitude
		var longitude: float =  coordinates.y # Longitude

		# Only draw if this POI is within the visible range
		if longitude >= _minimum_longitude and longitude <= _maximum_longitude and latitude >= _minimum_latitude and latitude <= _maximum_latitude:
			# Convert coordinates to pixel positions
			# var x_pos: float = get_x_from_longitude(longitude)
			# var y_pos: float = get_y_from_latitude(latitude)
			var pixel_position: Vector2 = geographic_coordinate_to_pixel(coordinates)
	
			
			# Skip if outside visible area
			if pixel_position.x < 0 or pixel_position.x > _grid_width or pixel_position.y < 0 or pixel_position.y > _grid_height:
				continue

			# Draw a circle marker at the POI location
			draw_circle(pixel_position, 5, _poi_label_color)
			
			# Draw the name of the POI next to the marker
			draw_string(label_font, Vector2(pixel_position.x + 10, pixel_position.y), poi_name, 
						HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _poi_label_color)


## Draws a scale bar at the bottom of the map showing approximate distances
func draw_scale_bar() -> void:
	var bar_length: int = 200  # Length of scale bar in pixels
	var bar_height: int = 5    # Height of scale bar
	var margin: int = 20       # Margin from bottom-left corner
	
	# Position at bottom-left of the map
	var start_position: Vector2 = Vector2(margin, _grid_height - margin)
	var end_position: Vector2 = Vector2(margin + bar_length, _grid_height - margin)
	
	# Calculate approximate real-world distance represented by the bar
	var start_point: Vector2 = pixel_to_geographic_coordinate(start_position)
	var end_point: Vector2 = pixel_to_geographic_coordinate(Vector2(start_position.x + bar_length, start_position.y))
	var distance_km: float = haversine_distance_between_points(start_point, end_point)
	# The distance using the Pythagorean theorem is here just for test purposes
	# so I can see how far off it is from the haversine distance
	var distance_pythagorean: float = pythagorean_distance_between_points(start_point, end_point)
	
	# Round number for display
	var rounded_distance: int = int(round(distance_km / 100.0) * 100)
	
	# Draw the scale barf
	draw_line(start_position, end_position, _label_color, bar_height)
	draw_line(start_position, Vector2(start_position.x, start_position.y - 10), _label_color, 2)
	draw_line(end_position, Vector2(end_position.x, end_position.y - 10), _label_color, 2)
	
	# Draw the distance label
	var distance_label: String = str(rounded_distance) + " km"
	draw_string(label_font, Vector2(start_position.x + bar_length/2 - 20, start_position.y - 15), 
				distance_label, HORIZONTAL_ALIGNMENT_LEFT, -1, _label_font_size, _label_color)

## Calculate distance between two geographic points using the Haversine formula
## This is not as accurate for a equirectangular projection.
## https://en.wikipedia.org/wiki/Haversine_formula
## *Note: The radius for Earth is used for this calculation.
## Returns distance in kilometers
func haversine_distance_between_points(start_point: Vector2, end_point: Vector2) -> float:
	# Extract coordinates (assuming [latitude, longitude] format)
	# deg_to_rad is a Godot function:
	# https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#class-globalscope-method-deg-to-rad
	# Convert degrees to radians
	var lat1: float = deg_to_rad(start_point.x)
	var lon1: float = deg_to_rad(start_point.y)
	var lat2: float = deg_to_rad(end_point.x)
	var lon2: float = deg_to_rad(end_point.y)
	
	# Haversine formula components
	var lat: float = lat2 - lat1
	var lon: float = lon2 - lon1
	var a: float = sin(lat/2) ** 2 + cos(lat1) * cos(lat2) * sin(lon/2) ** 2
	var c: float = 2 * atan2(sqrt(a), sqrt(1-a))
	
	# Calculate distance
	return EARTH_RADIUS * c

## Calculate distance between two geographic points using the Pythagorean theorem
func pythagorean_distance_between_points(start_point: Vector2, end_point: Vector2) -> float:
	
	var lat1: float = deg_to_rad(start_point.x)
	var lon1: float = deg_to_rad(start_point.y)
	var lat2: float = deg_to_rad(end_point.x)
	var lon2: float = deg_to_rad(end_point.y)
	
	var x: float = (lon2 - lon1) * cos((lat1 + lat2) / 2)
	var y: float = (lat2 - lat1)
	var distance: float = sqrt(x * x + y * y) * EARTH_RADIUS

	return distance


## Convert latitude (in Decimal Degree format) to y pixel position on the grid
## This only works for equirectangular projection which is what the fantasy map is
## currently
## https://en.wikipedia.org/wiki/Equirectangular_projection
# Refer to the comments in get_x_from_longitude() for more details
# on the calculations.
func get_y_from_latitude(latitude: float) -> float:

	# Calculate the range of latitudes
	var latitude_range: float = _maximum_latitude - _minimum_latitude
	
	# Calculate the position as a ratio (0.0 to 1.0) of the latitude range
	# * Note: The formula is inverted (_maximum_latitude - latitude) because
	# * in screen coordinates, Y increases downward, but latitude increases upward
	var latitude_position = (_maximum_latitude - latitude) / latitude_range
	
	# Convert the ratio to actual pixel position
	return latitude_position * _grid_height

## Convert longitude (in Decimal Degree format) to x pixel position on the grid
## This only works for equirectangular projection which is what the fantasy map is
## currently
func get_x_from_longitude(longitude: float) -> float:
	# Calculate the range of longitudes, which is -180 to 180 degrees, for a total range of 360 degrees
	var longitude_range: float = _maximum_longitude - _minimum_longitude
	
	# Calculate the position as a ratio (0.0 to 1.0) of the longitude range
	# i.e., calculate where the longitude falls in a total longitude span
	# between 0.0 and 1.0:
	#  - Longitude -180 = 0.0
	#  - Longitude 0 = 0.5
	#  - Longitude 180 = 1.0
	# This is a simple linear interpolation to find the position
	# of the longitude within the range of longitudes
	# between _minimum_longitude and _maximum_longitude
	var longitude_position = (longitude - _minimum_longitude) / longitude_range
	
	# Convert the normalized longitude position to the actual pixel position on the grid
	# Example: If _grid_width = 1920:
	# - Longitude 0 degrees = 0.5 * 1920 = 960 pixels (center)
	# - Longitude 180 degrees = 1.0 * 1920 = 1920 pixels (right edge)	
	# - Longitude -180 degrees = 0.0 * 1920 = 0 pixels (left edge)
	return longitude_position * _grid_width


## Convert pixel coordinates on the map to geographic coordinates (latitude, longitude)
func pixel_to_geographic_coordinate(pixel_position: Vector2) -> Vector2:
	# Calculate Longitude from x position
	var longitude_range: float = _maximum_longitude - _minimum_longitude
	var longitude: float = _minimum_longitude + (pixel_position.x / _grid_width) * longitude_range

	# Calculate Latitude from y position (inverted)
	var latitude_range: float = _maximum_latitude - _minimum_latitude
	var latitude: float = _maximum_latitude - (pixel_position.y / _grid_height) * latitude_range

	return Vector2(latitude, longitude)

## Convert geographic coordinates (latitude, longitude) to pixel coordinates on the grid
func geographic_coordinate_to_pixel(geographic_position: Vector2) -> Vector2:

	var latitude: float = geographic_position.x
	var longitude: float = geographic_position.y

	# Calculate pixel position from latitude and longitude
	var x: float = get_x_from_longitude(longitude)
	var y: float = get_y_from_latitude(latitude)

	return Vector2(x, y)

## Update grid dimensions
func update_grid_size(new_width: int, new_height: int) -> void:
	# Make sure that the new width and height are valid
	if new_width <= 0 || new_height <= 0:
		push_error("Invalid grid size. Width and height must be positive integers.")
		return

	_grid_width = new_width
	_grid_height = new_height
	queue_redraw()  # Request redraw to show the changes

## Update line spacing
func update_spacing(new_longitude_spacing: int, new_latitude_spacing: int) -> void:
	_longitude_spacing = new_longitude_spacing
	_latitude_spacing = new_latitude_spacing
	queue_redraw()  # Request redraw to show the changes
	
## Update geographical range
func update_geo_range(new_min_lat: float, new_max_lat: float, new_min_long: float, new_max_long: float) -> void:
	_minimum_latitude = new_min_lat
	_maximum_latitude = new_max_lat
	_minimum_longitude = new_min_long
	_maximum_longitude = new_max_long
	queue_redraw()  # Request redraw to show the changes

## Add a new point of interest to the map
func add_point_of_interest(name: String, longitude: float, latitude: float) -> void:
	points_of_interest[name] = [longitude, latitude]
	queue_redraw()  # Request redraw to show the changes


	## Override _input to handle mouse interactions
func _input(event: InputEvent) -> void:
	if _toggle_grid == true:

		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				# Handle left-click
				var mouse_pos: Vector2 = get_local_mouse_position()
				var geo_pos: Vector2 = pixel_to_geographic_coordinate(mouse_pos)
				
				# Example: Print the clicked coordinates
				print("Clicked at pixel: ", mouse_pos)
				print("Geographic coordinates: ", geo_pos)
			
	

