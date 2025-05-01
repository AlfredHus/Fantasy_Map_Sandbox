extends Node2D
## Data overlay is used to display data on the various diagrams. The types
## of data to display are controlled by the @export variables.
## Data overlays are used for debugging purposes and to help understand
## how the data is applied.
## Here are some general guidance Azgaar Data Overlays have the "az" in their 
## description. This data can be overlayed on the Azgaar maps which also 
## have "az" in their  description. For example, you can overlay precipitation 
## data over the precipitation map of the elevation map.
## [br]
## NOTE: The data overlay works best with diagram sizes of less than 2000 
## voronoi cells. More than that and the displayed text begines to merge 
## making the data unintelligable.

# Export Variables
@export_group("Azgaar Style Map Overlays")
## Use this to display precipiation data on Azgaar style maps.
@export var _display_az_precipitation_data: bool = false
## Use this to display temeprature data on Azgaar style maps.
@export var _display_az_temperature_data: bool = false
## Use this to display elevation data on Azgaar style maps.
@export var _display_az_elevation_data: bool = false
@export_group("Voronoi and Delaunay Diagram Overlays")
## Use this to display the triangle index data over deluanay triangle diagram.
@export var _display_triangle_index_data: bool = false
## Use this to display the voronoi cell vertixes
@export var _display_voronoi_cell_index_data: bool = false

@export var _display_latitude_and_longitude_data: bool = false



# Private variables
var _voronoi: Voronoi # the voronoi data
var _grid: Grid # the grid data
#var _voronoi_cell_dict: Dictionary
var _delaunay: Delaunator
var _points: PackedVector2Array
var _map: Map
var _jittered_grid: bool
var _font : Font


func _ready():
	pass

## Set up the data structures we need to display data.
## [param voronoi] - the voronoi data
## [param grid] - the grid data
## @param
func setup(voronoi: Voronoi, grid:Grid, delaunay: Delaunator, points: PackedVector2Array, map: Map, jittered_grid: bool):
	_grid = grid
	_voronoi = voronoi
	_delaunay = delaunay
	_map = map
	_points = points
	_jittered_grid = jittered_grid
	_font = ThemeDB.fallback_font

## Drawing the various data overlays is controled in the _draw function via
## if statements and the @export variables.
func _draw()  -> void:

 	# Display overlayfor Azgaar style maps
	if _display_az_precipitation_data: _display_az_precipitation_overlay()
	if _display_az_temperature_data: _display_az_temperature_overlay()
	if _display_az_elevation_data: _display_az_elevation_overlay()
	# Display overlay for voronoi and delaunay diagrams
	if _display_triangle_index_data: _display_triangle_index_overlay()
	if _display_voronoi_cell_index_data: _display_voronoi_cell_index_overlay()
	if _display_latitude_and_longitude_data: _display_longitude_and_latitude()
	

# Use these functions with the Azgaar style maps. Will not work with
# with the Voronoi and Delauany Triangle diagrams.

## Display precipitation data on azgaar style maps.
func _display_az_precipitation_overlay() -> void:

	for p in _grid.points_n:
		var precipitation = _grid.cells["prec"][p]

		# Get the position polylabel position to display the value to
		var result: Array[float] = _get_poly_label(p)
		# set up to print out the precipitation value
		_draw_number(Vector2(result[0], result[1]), snapped(precipitation, 0.1))
		#draw_string(_font, Vector2(result[0], result[1]), str(snapped(precipitation, 0.1)), 0, -1, 8, Color.BLACK)			

## Display temperature data on azgaar style maps.
func _display_az_temperature_overlay() -> void:
	
	for p in _grid.points_n:
		var temperature = _grid.cells["temp"][p]

		# Get the position polylabel position to display the value to
		var result: Array[float] = _get_poly_label(p)
		# set up to print out the temperature value
		_draw_number(Vector2(result[0], result[1]), temperature)
		#draw_string(_font, Vector2(result[0], result[1]), str(temperature), 0, -1, 8, Color.BLACK)


func _display_longitude_and_latitude() -> void:
	for p in _grid.points:
		var latitude = _map.get_latitude(p.x, _grid.width, 2)
		var longitude = _map.get_longitude(p.y, _grid.height, 2)
			# Get the position polylabel position to display the value to
		#var result: Array[float] = _get_poly_label(w)  # Use 'w' for the polylabel position

			# Additional logic to display latitude and longitude can be added here
		draw_string(_font, p, str(latitude) + ", " + str(longitude), HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.BLACK)
		
	print ("grid.cells_x: ", _grid.cells_x, " : ", "grid.cells_y: ", _grid.cells_y)
	var grid_size = _grid.get_cols_and_rows()
	print ("grid_cols: ", grid_size["cols"], " : ", "grid_rows: ", grid_size["rows"])
	print ("Size of points: ", _grid.points.size())
	
## Display elevation data on azgaar style maps.
func _display_az_elevation_overlay() -> void:

	for p in _grid.points_n:
		var elevation = _grid.cells["h"][p]
	
		# Get the position polylabel position to display the value to
		var result: Array[float] = _get_poly_label(p)
		# set up to print out the precipitation value
		_draw_number(Vector2(result[0], result[1]), snapped(elevation, 0.1))

		
			
		
# Use these functions with the Voronoi and Delaunay Triangles. Will not work with 
# the Azgaar style maps


## Display the indexes of each of the triangle vertices and the centroid 
## index for the the triangle.		
func _display_triangle_index_overlay():
	var seen : PackedVector2Array
	var triangle_indexes: Array
	var points_of_triangle: Array
		
	for t in _delaunay.triangles.size() / 3:
		points_of_triangle = _voronoi.points_of_triangle(_points, _delaunay, t)
		triangle_indexes = _voronoi.index_of_triangle(_delaunay, t)

		# Calculate the centroid
		var sum_x: float = points_of_triangle[0][0] + points_of_triangle[1][0] + points_of_triangle[2][0]
		var sum_y: float = points_of_triangle[0][1] + points_of_triangle[1][1] + points_of_triangle[2][1]
		var centroid_x: float = sum_x / 3.0
		var centroid_y: float = sum_y / 3.0
		var centroid: Vector2 = Vector2(centroid_x, centroid_y)

		draw_circle(centroid, 2, Color.BLUE)
		_draw_number (centroid, t)
		#draw_string(_font, centroid, str(t), 0, -1, 10, Color.BLACK)

		for p in points_of_triangle:
			for i in triangle_indexes:
				if seen.find(p) == -1:
					_draw_number(p, i)
					#draw_string(_font, p, str(i),0, -1, 10, Color.BLACK)
					seen.append(p)


## DIsplay the index for each Voronoi Cell Vertex (corner)
func _display_voronoi_cell_index_overlay():	
	var seen: Array[Vector2]

	for key in _voronoi.voronoi_cell_dict.keys():
		var index_position : Vector2
		var index: int
		
		# We store when a position has been drawn so we don't draw over existing
		# positions on the screen.
		for i in _voronoi.voronoi_cell_dict[key].size():
			index_position = _voronoi.voronoi_cell_dict[key][i]
			index = _voronoi.voronoi_cell_dict_indexes[key][i]

			# Don't display number if it has already been drawn
			if not seen.has(index_position):
				#draw_position(position)
				_draw_number(index_position, index)
				seen.append(index_position)


# Helper Functions #

## Display a number at a specific position (x,y) on the screen.
func _draw_number(number_position: Vector2, id: int, size_of_font: int = 10, font_color: Color = Color.BLACK) -> void:
	draw_string(_font, number_position, str(id), 6, -1, size_of_font, font_color)


# Get the polylabel position for the voronoi cell (i.e., polygon)
# [param p] is the index into the voronoi cell dictionary which contains
# the vertices for that voronoi cell.
# Returns the polylabel position
func _get_poly_label(p: int) -> Array[float]:
	# var voronoi_cell_dict: Dictionary = _voronoi.get_voronoi_cells()	
	# Set up the array for the voronoi vertices that we are going to 
	# calculate the poly_lable for. Remember that a voronoi cell is a 
	# a polygon.
	# PolyLable takes polygon coordinates in a GeoJSON like format , i.e,
	# an array of arrays of [x,y] points, so we set up an array of 
	# arrays using only the first element of the array of arrays.
	# See here for a description of a GeoJSON polygon:
	# https://datatracker.ietf.org/doc/html/rfc7946#section-3.1.6
	var voronoi_vertice = []
	voronoi_vertice.append([])
		
	# Store the vertices for the specific voronoi
	for vertice in _voronoi.voronoi_cell_dict[p]:
		voronoi_vertice[0].append(Vector2(vertice[0], vertice[1]))
	# get the polylabel position
	var polylabel = PolyLabel.new()
	var result: Array[float] = polylabel.get_polylabel(voronoi_vertice, 1.0, false)
	# Return the polylabel position for the polygon
	return result
		
		
