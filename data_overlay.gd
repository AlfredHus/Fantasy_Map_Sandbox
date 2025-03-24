extends Node2D
## Data overlay is used to display data on the various diagrams. The types
## of data to display are controlled by the @export variables.
## Data overlays are used for debugging purposes and to help understand
## how the data is applied.
## [br]
## NOTE: The data overlay works best with diagram sizes of less than 2000 
## voronoi cells. More than that and the displayed text begines to merge 
## making the data unintelligable.

# Export Variables
## Use this to display precipiation data on Azgaar style maps.
@export var _display_az_precipitation_data: bool = false
## Use this to display temeprature data on Azgaar style maps.
@export var _display_az_temperature_data: bool = false
## Use this to display elevation data on Azgaar style maps.
@export var _display_az_elevation_data: bool = false

# Private variables
var _voronoi: Voronoi # the voronoi data
var _grid: Grid # the grid data
var _voronoi_cell_dict: Dictionary

func _ready():
	pass

## Set up the data structures we need to display data.
## [param voronoi] - the voronoi data
## [param grid] - the grid data
func setup(voronoi: Voronoi, grid:Grid):
	_grid = grid
	_voronoi = voronoi

## Drawing the various data overlays is controled in the _draw function via
## if statements and the @export variables.
func _draw()  -> void:

 	# Display Data points for Azgaar style maps
	if _display_az_precipitation_data: display_az_precipitation_data()
	if _display_az_temperature_data: display_az_temperature_data()
	if _display_az_elevation_data: display_az_elevation_data()
	
## Display precipitation data on azgaar style maps.
func display_az_precipitation_data() -> void:
	var voronoi_cell_dict: Dictionary = _voronoi.get_voronoi_cells()	
	var font : Font
	font = ThemeDB.fallback_font

	for p in _grid.points_n:
		var precipitation = _grid.cells["prec"][p]

		# Get the position polylabel position to display the value to
		var result: Array[float] = _get_poly_label(p)
		# set up to print out the precipitation value
		draw_string(font, Vector2(result[0], result[1]), str(snapped(precipitation, 0.1)), 0, -1, 8, Color.BLACK)			

## Display temperature data on azgaar style maps.
func display_az_temperature_data() -> void:
	var voronoi_cell_dict: Dictionary = _voronoi.get_voronoi_cells()	
	var font : Font
	font = ThemeDB.fallback_font
	
	for p in _grid.points_n:
		var temperature = _grid.cells["temp"][p]

		# Get the position polylabel position to display the value to
		var result: Array[float] = _get_poly_label(p)
		# set up to print out the temperature value
		draw_string(font, Vector2(result[0], result[1]), str(temperature), 0, -1, 8, Color.BLACK)
	
	## Display precipitation data on azgaar style maps.
func display_az_elevation_data() -> void:
	var voronoi_cell_dict: Dictionary = _voronoi.get_voronoi_cells()	
	var font : Font
	font = ThemeDB.fallback_font

	for p in _grid.points_n:
		var elevation = _grid.cells["h"][p]
	
		# Get the position polylabel position to display the value to
		var result: Array[float] = _get_poly_label(p)
		# set up to print out the precipitation value
		draw_string(font, Vector2(result[0], result[1]), str(snapped(elevation, 0.1)), 0, -1, 8, Color.BLACK)			

# Get the polylabel position for the voronoi cell (i.e., polygon)
# [param p] is the index into the voronoi cell dictionary which contains
# the vertices for that voronoi cell.
# Returns the polylabel position
func _get_poly_label(p: int) -> Array[float]:
	var voronoi_cell_dict: Dictionary = _voronoi.get_voronoi_cells()	
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
	for vertice in voronoi_cell_dict[p]:
		voronoi_vertice[0].append(Vector2(vertice[0], vertice[1]))
	# get the polylabel position
	var polylabel = PolyLabel.new()
	var result: Array[float] = polylabel.get_polylabel(voronoi_vertice, 1.0, false)
	# Return the polylabel position for the polygon
	return result
		
		
