extends Node2D
# Port to Godot 4.1.3 - Tom Blackwell - 18 Mar 2024
# Source URL - [url]https://github.com/Volts-s/Delaunator-GDScript-4[/url]
# License: MIT, ISC
# Original source that the above was ported from:
# @hiulit: [url]https://github.com/hiulit/Delaunator-GDScript/tree/master[/url]
# License: MIT, ISC


# TERMINOLOGY
# SOurce: https://en.wikipedia.org/wiki/Voronoi_diagram
#
# A Voronoi diagram is a partition of a plane into regions 
# close to each of a given set of objects.  In the simplest case, these 
# objects are just finitely many points in the plane 
# (called seeds, sites, or generators). 
# For each seed there is a corresponding region, called a Voronoi cell,
# consisting of all points of the plane closer to that seed than to any other.
# 
# Voronoi Cell: This is a closed polygon that is defined by 3 or more vertices.
# Each Voronoi Cell will contain the initial points that were used as a 
# seed to create the Delaunay Triangulation.
#
# IMPORTANT STRUCTURES AND VARIABLES
# ==================================
# voronoi_cell_sites: A  PackedVector2Array() that will hold the associated point
# for that Voronoi Cell. TThe array contains the coordinate of the point that
# is owned by the Voronoi Cell. The location of the point in the Array is an 
# index into the Voronoi Cell Dict dictionary that wil contain the vertices
# of that voronoi cell. This associates each point to its Voronoi Cell.
#
# points: The points are the seeds used to create the Delaunay Triangulation.
#
# voronoi_cell_dict: A dictionary that contains the id of the Voronoi Cell (key)
# and the vertices that make up the voronoi cell. This dictionary has an 
# association with the voronoi_cell_sites array as described in the voronoi_cell
# comments above.
#
# Both the halfedges and triangle array are indexed by the half-edge ID [e]
# delaunay.triangles[e]: this gives the point ID where the half-edge starts.
#
# delaunay.halfedges[e]: this returns either the opposite half-edge in the 
# adjacent triangle or -1 if there is no adjacent triangle

# These are the exported values all set to false which will result in a 
# blank screen. 
# If you do not set _random_points, _poisson_distribution
# or _jittereed_grid to true, it will use the default_seed_points.

## the data overlay node which allows you to overlay data on the various
## diagrams
## NOTE: Currently moving the data overlay functions from main.gd to this
## node. Work in progress
@onready var data_overlay = $DataOverlay

################################ Imports ######################################
###############################################################################
const MapRegionScene := preload("res://map_region.tscn")

############################ Export Variables ##################################
################################################################################
# These variables are used to configure the map or diagrams. 
# TODO: Move some of these to a UI at some point.
## Use this to set a specific set of points for debugging purposes
@export var _random_points: bool = false
## Use Poisson when you want to generate a voronoi only.
@export var _poisson_distribution: bool = false
## Use jittered points when creating a Azgaar style fantasy map.
@export var _jittered_grid: bool = false
## Use the initial points. Normally used for testing.
@export var _initial_points: bool = false
## Use this for getting the points from an image. NOTE: Does not currently work.
@export var _points_from_image: bool = false
## When using random points, you need to set the seed to the number of points
@export var _default_seed_points: int = 100
## Set this if you want to change the voronoi cells using your mouse.
@export var _use_mouse_to_draw: bool = false
## Set this if you want to see the triangles in the diagram
@export var _draw_triangles: bool = false
## Set this if you want the triangles to be filled with a random color
@export var _draw_filled_in_triangles: bool = false
## Set this if you want to see the triangle edges only
@export var _draw_triangle_edges: bool = false
@export var _draw_packed_triangle_edges: bool = false
## Set this to draw arrows that show the direction of the triangle segments
@export var _draw_triangle_edges_with_arrows: bool = false
## Set this if you want to see the voronoi cells with random colors
@export var _draw_voronoi_cells: bool = false
@export var _draw_packed_voronoi_cells: bool = false
## Set this if you only want to see the voronoi cells that are convex hulls
@export var _draw_voronoi_cells_convex_hull: bool = false
## Set this if you want to see the edges of the voronoi cell.
@export var _draw_voronoi_edges: bool = false
## Set this if you want to see the points that were provided to Delaunay
@export var _draw_points: bool = false
@export var _draw_packed_points: bool = false
## Set this if you want to see the centroids of the voronoi cells.
@export var _draw_centroids: bool = false
## Use this for setting the size of a Azgaar style map
@export var _cells_desired = 10000
## Set this if you want to see an example of a clickable polygon diagram
@export var _draw_clickable_voronoi: bool = false
## Set this if you to see variables in the console
@export var debug_mode: bool = false
@export var sampling_min_distance: float = 10
@export var sampling_poisson_max_tries: int = 30
#@export var area: Rect2 = Rect2(0, 0, 1152, 648)
@export var area: Rect2 

## Use these to display the various triangle center types
@export_group("Triangle centers")
## Set this if you want to see the circumcenters
@export var _draw_triangle_circumcenters: bool = false
## Set this if you want to see the triangle centers
@export var _draw_triangle_centers: bool = false
## Set this if you want to see the triangle incenters
@export var _draw_triangle_incenters: bool = false
## Set this to draw circles representing the circumcenters
@export var _draw_triangle_circumcenters_circles: bool = false

@export_group("Debug Modes")
@export var debug_triangles: bool = false
@export var debug_voronoi_cells: bool = false
@export var debug_adjacent_triangles: bool = false
@export var debug_triangle_edges: bool = false

@export_group("Map Modes")
@export var draw_voronoi_elevation: bool = false
## To generate the fanatsy map, you need to select "Jittered Grid"
@export var _draw_voronoi_fantasy_heightmap: bool = false
## Lets you choose the type of Azgaar style map template to use
@export_enum("volcano", "highIsland", "lowIsland", "continents", "archipelago", "atoll", \
				"mediterranean", "peninsula", "pangea", "isthmus", "shattered","taklamakan", \
			 	"oldWorld", "fractious") var _selected_world
## To generate the elevations, you need to also select "Jittered Grid"
@export var _draw_fantasy_map_elevations: bool = false
## Dwaw a feature map for Azgaar style maps
@export var _draw_az_feature_map: bool = false
## Dwaw a temperature map for Azgaar style maps
@export var _draw_az_temperature_map: bool = false
## Dwaw a precipitation map for Azgaar style maps
@export var _draw_az_precipitation_map: bool = false

@export_group("Map Generation")
@export var _generate_fantasy_map: bool = false
@export var _generate_feature_map: bool = false
@export var _generate_water_land_map: bool = false:
	set(value):
		_generate_water_land_map = value
		queue_redraw

@export_group("Display Data Points")
## Set this if you want to display the ID of the voronoi cell
@export var _draw_voronoi_cell_site_position_data: bool = false
## Set this if you want to display the voronoi cell ID and site coordinates
@export var _draw_voronoi_points_position_data: bool = false
## Set this if you want to have a clickable voronoi cell
@export var _draw_triangle_position_data: bool = false
@export var _draw_triangle_packed_position_data: bool = false
# NOTE: flags are cumulative when you need to check if more than one flag is 
# selected. So if you want to check if Corners and Mid Points are selected
# the value to check against is 1 + 2  = 3 (export_flags are increment in powers
# of two, i.e., 0 = no selection, 1, 2, 4, 8 etc. For the associated enum we use
# TrianglePositionData we check for both by having the BOTH emum set to 3
@export_flags ("Corners", "Mid Points") var triangle_position_data = 0
# Enums used for export values
enum TrianglePositionData {CORNERS = 1, MID_POINTS = 2, BOTH = 3}
## Use this to display whether a cell is a border cell
@export var _draw_border_data: bool = false
## Use this to display the boundary points
@export var _draw_boundary_data: bool = false
## Use this to display precipiation data on Azgaar style maps.
@export var _display_az_precipitation_data: bool = false
## Use this to display temeprature data on Azgaar style maps.
@export var _display_az_temperature_data: bool = false
## Use this to display elevation data on Azgaar style maps.
@export var _display_az_elevation_data: bool = false

@export_group("Relationships")
## Set to draw lines to the neighbors of a Voronoi Site when selecting the Voronoi Cell
@export var draw_neighbor_lines: bool = false
## Set to hightlight edges around a point
@export var _draw_edges_around_point: bool = false

# In Azgaars code, configuration values are extract from the UI input vales
# These values mimic that.
@export_group("Configuration Values")
## Used to set the lake deep depressions as defined in the Lakes class
@export var _lake_elevation_limit_output: int = 20





############################### Public Variables ########################################

############################### Private Variables ########################################

# Each point is a vertex of a triangle as built by Delaunator.
# A point may be shared by more than one triangle.
# Each point will lie in exactly one of the voronoi cells (or voronoi regions)
# These points are also called Voronoi sites or generators
var points := PackedVector2Array()


var delaunay: Delaunator
var packed_delaunay: Delaunator
var voronoi: Voronoi
var packed_voronoi: Voronoi
var polylabel: PolyLabel
var debug: Debug
var elevation: Elevation
var grid: Grid
var pack: Pack # Packed Grid
var heightmap_generator: HeightMapGenerator
var features: Features
var lakes: Lakes
var map: Map
var temperature: Temperature
var precipitation: Precipitation


#var voronoi_cells:= PackedVector2Array()
#var coordinates := PackedVector2Array()
var size: Vector2i
#var centroids := PackedVector2Array()
var delay_timer: float = 0.0
var delay_timer_limit: float = 0.5

var triangle_coordinates := PackedVector2Array()
var triangle_edges_coordinates := PackedVector2Array()
var adjacent_triangle_edges_coordinates := PackedVector2Array()
var halfedge_coordinates := PackedVector2Array()

var halfedges := PackedInt32Array()


var moving: bool = false

var image_data
var image: Image

# The dictionary holds all of the voronoi cells and their vertexes.
#var voronoi_cell_dict: Dictionary  = {}

# This array will contain the voronoi sites (the points) for each Voronoi
# cell. The position in the array is the key (id) for that voronoi cell
# that contains the point.
var voronoi_cell_sites:= PackedVector2Array()

enum world_choices {
	VOLCANO,
	HIGH_ISLAND,
	LOW_ISLAND,
	CONTINENTS,
	ARCHIPELAGO,
	ATOLL,
	MEDITERRANEAN,
	PENINSULA,
	PANGEA,
	ISTHMUS,
	SHATTERED,
	TAKLAMAKAN,
	OLD_WORLD,
	FRACTIOUS,
}

# Used to determine the size of the initial points. These are used for 
# Debugging. There are three sizes depending on the need. The LARGE size is the
# default. You can use the smaller sizes if you want to see less points in
# the diagram.
enum _InitialPointSize {LARGE, MEDIUM, SMALL}

## Variables used to measure the time it takes to do something
var _time_now: int 
var _time_elapsed: int

#var initial_points := PackedVector2Array() 
#var initial_points_small := PackedVector2Array() 
#var initial_points_small_1 := PackedVector2Array() 
var jittered_grid_points := PackedVector2Array()
#var interior_points := PackedVector2Array()
#var exterior_points := PackedVector2Array()
var boundary_points := PackedVector2Array()





func _ready()  -> void:
#   viewpoint width and height are set in the project settings. General -> Window -> Viewport Height
#   and Viewport Width. 
	

	
	
	size = get_viewport().size
	print ("Viewport Size: ", size.x, ":", size.y)
		
	if _random_points:
		grid = Grid.new(_default_seed_points, area)
		points = grid.set_random_points(size)
		print("Random points:", points.size())
	elif _poisson_distribution:
		grid = Grid.new(_cells_desired, area)
		points = grid.set_points_by_poisson_distribution(sampling_min_distance, sampling_poisson_max_tries)
		print("Poisson points:", points.size())
	elif _jittered_grid:
		print ("Starting Jittered Grid creation... creating %s cells" % _cells_desired)
		_time_now  = Time.get_ticks_msec()
		#grid = Grid.new(_cells_desired, area)
		#points = grid.set_jittered_grid_points()
		calculate_voronoi()
		_time_elapsed = Time.get_ticks_msec() - _time_now
		print("Jittered Grid creation took %s seconds" % (float(_time_elapsed) / 1000))
	elif _points_from_image:
		### TEST CODE FOR IMAGE HANDLING. CURRENTlY DOES NOT WORK##
		# FIXME
		var image_texture_resource = preload("res://world.png")
		image = image_texture_resource.get_image()
		print ("Image size = ", image.get_data_size())
		print ("Image height and width ", image.get_height(), ":", image.get_width())
		#image.resize(area.size.x, area.size.y)
		print ("Resized Image size = ", image.get_data_size())
		print ("Resized Image height and width ", image.get_height(), ":", image.get_width())
		var pds: PoissonDiscSampling = PoissonDiscSampling.new()
		area.size.x = image.get_width()
		area.size.y - image.get_height()	
		var area1 = Rect2(0, 0, image.get_width(), image.get_height())
		var image_data = image.get_data()
		print ("image data size = ", image_data.size())
		points = pds.generate_points(sampling_min_distance, area1, sampling_poisson_max_tries, Vector2(INF, INF))
		#points = pds.generate_points_on_image(14, 40, image_texture_resource, area, Vector2(1.2, 1.2))
		grid = Grid.new(_cells_desired, area)
		grid.points = points
		
		#var point_distance = []
		#var i = 0
		#point_distance.resize(points.size())
		#for p in points:
			#var pixelIndex = (round(p[0]) + round(p[1]) * image.get_width()) * 3
			#var c = pow(image_data[pixelIndex] / 255, 2.7)
			#point_distance[i] = c
			#i += 1
			#
			#pass
		#pass
		
		#var image_error = image.save_png("res://world_resized.png")
		#if image_error != OK:
			#print("Image Save Failure! with error code: ", image_error)
		#image_data = image.get_data()
		##print (image_data)
		## Create a grid of points
		#grid = Grid.new(_cells_desired, area)	
		##grid = Grid.new(image.get_data_size(), area)
		#points = grid.points
		#self.boundary_points = grid.boundary_points
		##print("Jittered grid points:", points.size())
		## Add a border to the points to pseudo-clip the voronoi diagram
		#for i in self.boundary_points:
			#points.append(i)
	elif _initial_points:
		grid = Grid.new(_cells_desired, area)
		points = grid.set_initial_points(grid.InitialPointSize.LARGE)
		print("Initial points:", points.size())
	else:
		print ("WARNING! No points selected")
		

	
	var start = Time.get_ticks_msec();
	# When you call the Delaunator constructor, it will start _init first and then call 
	# the actual constructor
	# The constructor will return a new delaunay traingulation of 2D points
	#
	#if !_draw_fantasy_map_elevations && !_jittered_grid:
	if _poisson_distribution || _random_points || _initial_points:
		##Set up the delaunay triangulation
		delaunay = Delaunator.new(points)
		## Set up the voronoi structure
		voronoi = Voronoi.new(points, grid, delaunay, area)
	
	#voronoi.setup_centroids()
	#print ("Centroids1: ", voronoi.centroids1)
	
	elevation = Elevation.new(voronoi)
	
	elevation.generate_elevation(3)
	#elevation.generate_elevation_from_image()
	var world_selected: String = "volcano" # default is volcano
	match _selected_world:
		world_choices.VOLCANO:
			world_selected = "volcano"
		world_choices.HIGH_ISLAND:
			world_selected = "highIsland"
		world_choices.LOW_ISLAND:
			world_selected = "lowIsland"
		world_choices.CONTINENTS:
			world_selected = "continents"
		world_choices.ARCHIPELAGO:
			world_selected = "archipelago"
		world_choices.ATOLL:
			world_selected = "atoll"
		world_choices.MEDITERRANEAN:
			world_selected = "mediterranean"
		world_choices.PENINSULA:
			world_selected = "peninsula"
		world_choices.PANGEA:
			world_selected = "pangea"
		world_choices.ISTHMUS:
			world_selected = "isthmus"
		world_choices.SHATTERED:
			world_selected = "shattered"
		world_choices.TAKLAMAKAN:
			world_selected = "taklamakan"
		world_choices.OLD_WORLD:
			world_selected = "oldWorld"
		world_choices.FRACTIOUS:
			world_selected = "fractious"
	
	# Give the voronoi and grid data to the data overlay functions
	data_overlay.setup(voronoi, grid)
	# Generate Azgaars Fantasy Map
	#if _jittered_grid or _poisson_distribution == true: generate_fantasy_map(world_selected)
	if _jittered_grid == true: generate_azgaar_style_fantasy_map(world_selected)
	

	
	#if _points_from_image == true:
		#draw_voronoi_fantasy_heightmap_from_image()

	halfedges = delaunay.get_half_edges()
	


	
	#get_edges_around_point_all_triangles(points, delaunay)

	#draw_edges_around_point_test(0)
	

	# get vertices of the voronoi cells. The get_voronoi_cells function
	# also builds a dictionary of the voronoi cells.q
	#voronoi_cells = get_voronoi_cells(points, delaunay)
	
	var voronoi_cells2 = voronoi.get_voronoi_cells()

	#voronoi_cell_sites = voronoi.get_voronoi_cell_sites()
	
	# This provides a clicable version of the Voronoi cells.
	if _draw_clickable_voronoi:
		var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()
		for key in voronoi_cell_dict:
			var map_region : MapRegion = MapRegionScene.instantiate()
			add_child(map_region)
			map_region.shape = voronoi_cell_dict[key]
			map_region.region_selected.connect(_on_MapRegion_selected.bind(key))	


	var debug = Debug.new(grid)
	
	if debug_mode: print ("===============Debug Data=============\n")
	if debug_mode: print("PRINTING TRIANGLE DATA")
	if debug_mode: print ("=======================\n")

	# Debug data structures
	if debug_triangles: debug.print_triangles_data(points, delaunay, voronoi)
	if debug_voronoi_cells: debug.print_voronoi_cell_data(points, delaunay, voronoi)
	if debug_adjacent_triangles: debug.print_triangles_adjacent_to_triangles(delaunay, voronoi)
	if debug_triangle_edges: debug.print_triangle_edges_data(voronoi)
	if debug_mode: print ("Triangle Edges: Size (", voronoi.halfedge_coordinates.size(), ") Coords: ",voronoi.halfedge_coordinates)
	if debug_mode: print ("Triangle Edges Coordinates: Size(", voronoi.triangle_edges_coordinates.size(), ") Coords: ", voronoi.triangle_edges_coordinates)
	if debug_mode: print ("Adjacent Triangle Edges Coordinates: Size(", voronoi.adjacent_triangle_edges_coordinates.size(), ") Coords: ", voronoi.adjacent_triangle_edges_coordinates, "\n")
	
	if debug_mode: print("Printing Halfedges")
	if debug_mode: print("delaunay.halfedges: Size(", delaunay.halfedges.size(), "): ", delaunay.halfedges, "\n")
	
	if debug_mode: print("Printing Hulls")
	if debug_mode: print("delaunay.hull: ", delaunay.hull, "\n")
	
	if debug_mode: print("Printing Points")
	if debug_mode: print("points:: Size(", points.size(), ") ", points, "\n")
	
	if debug_mode: print("Printing the Voronoi Cells sites Points coordinates")
	if debug_mode: print ("voronoi cells sites: Size(",voronoi_cell_sites.size(), ") ",  voronoi_cell_sites, "\n")
	
	if debug_mode: print("Printing the Delaunay Coordinates")
	if debug_mode: print("delaunay.coords: Size(", delaunay.coords.size(), ") ",  delaunay.coords, "\n")
	
	if debug_mode: print("Printing Voronoi Cells Dictionary: Key and Vertices for the Voronoi Cell")
	if debug_mode: print ("Size: (", voronoi.voronoi_cell_dict.size(), ") ",voronoi.get_voronoi_cells(), "\n")
	
	if debug_mode: print ("Printing Voronoi Vertices")
	if debug_mode: print ("Size: (", voronoi.voronoi_vertices.size(), ") ", voronoi.voronoi_vertices, "\n")

	if debug_mode: print ("Printing Triangle Centers")
	if debug_mode: print ("Size: (", voronoi.get_triangle_centers().size(), ") ", voronoi.get_triangle_centers(), "\n")

	#var top_left_corner = voronoi._top_left_corner(points, area)
	#print ("=================> top Left Corner: ", top_left_corner, "Coords: ", points[top_left_corner])
	
	#var voronoi_vertices: PackedVector2Array = voronoi.add_voronoi_vertices(points, delaunay)


	#
	#var converted_image: Array[float] = elevation.load_grayscale_image("E:/Godot Projects/My Projects/polygon-island-generation/europe1.png")
	#print (converted_image)
	
	
	
	var relax = 0;
	
	#print ("POINTS: ", points)
	#print ("TCentroids: ", voronoi.centroids)
	#print ("SIZE OF CENTROIDS + ", voronoi.centroids.size())
	
	#if relax > 0:
		#for i in relax:
			#points.clear()
			#points.resize(voronoi.centroids.size())
			#var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()
			#for key in voronoi_cell_dict.keys():
				#points[key] = voronoi.calculate_centroid(voronoi_cell_dict[key])
				#voronoi.centroids[key] = voronoi.calculate_centroid(voronoi_cell_dict[key])
				#print ("=====>Centroids" , voronoi.centroids)
						#
			##for j in voronoi.centroids.size():
				##points[j] = voronoi.centroids[j]
			#delaunay = Delaunator.new(points)
			#voronoi = Voronoi.new(points, grid, delaunay, area)	
			#elevation = Elevation.new(voronoi)
			#elevation.generate_elevation(3)


# Set up the following data structures.
# Delaunay triangulation
# Voronoi cells and vertices. Note. Voronoi is used to set up generic voronoi 
# diagrams as well as setting up grid.cells and grid.vertices to be used in 
# the azgaar map generation.
# grid.cells["i"] is set up in grid.place_points
# all_points contains all points, inncluding the boundary boudary points
func calculate_voronoi():
	grid = Grid.new(_cells_desired, area)
	# Place points sets up the boundary points and the jittered points
	# We will combine later in this function and pass the combined
	# points to Delanator.
	grid.place_points()
	
	#points = grid.set_jittered_grid_points()
	# These are the points before appending the boundary points. 
	points = grid.points
	#grid.points_n = grid.points.size()

	
	var all_points: Array
	all_points.append_array(grid.points)
	
	# Append the boundary points to the end of the points array. We can then 
	# access the points excluding the boundary points by using grid.points_n
	# which is the size of the points minus the boundary points.
	#points.append_array(grid.exterior_boundary_points)
	all_points.append_array(grid.exterior_boundary_points)
	
	grid.all_points = all_points
	# Set up the delaunay triangulation
	delaunay = Delaunator.new(all_points)
	# Set up the voronoi structure.
	# The voronoi constructor will set up the cells and vertices
	# dictionarys and assign them to the grid class
	# We pass voronoi the the combined points (points + boundary points)
	# and the size of the points minus the boundary points. In voronoi, the 
	# grid.cells dictionary only contains the points - the  boundary points.
	voronoi = Voronoi.new(all_points, grid, delaunay, area)
	pass
	

# points contain the points before any bounaries are added.
# boundary contains the boundary points that are appended to all_points
# which is what is used to create the delaunay triangles and voronoi diagram.
func calculate_voronoi_new(grid: Grid, points: Array, boundary: Array) -> Dictionary:
	var packed_grid: Grid
	var temp = points.size()
	#packed_grid = Grid.new(points.size(), area)
	packed_grid = Grid.new(_cells_desired, area)
	packed_grid.points_n = points.size()
	pack.points_n = points.size()
	
	# Store the number of points before appending the boundary
	grid.points_n = points.size()
	
	var all_points: Array
	all_points.append_array(points)
	#all_points.append_array(boundary)
	#points.append_array(boundary)
	#var temp1 = points.size()
	
	# Calculate Delaunay triangulation
	#var vector_points = PackedVector2Array(points)
	var vector_points: PackedVector2Array
	# Brute foce the conversion to packedvector2array from array
	
	
	for p in all_points:
		vector_points.append(Vector2(p[0], p[1]))
	pack.all_points = vector_points
	#print ("Vector_points: ", vector_points)
	#packed_delaunay = Delaunator.new(points)
	packed_delaunay = Delaunator.new(vector_points)
	pack.points = vector_points
	
	

	# Calculate Voronoi diagram
	#packed_voronoi = Voronoi.new(points, packed_grid, packed_delaunay, area)
	packed_voronoi = Voronoi.new(vector_points, packed_grid, packed_delaunay, area)

	# Extract cells and vertices
	var cells = packed_grid.cells
	cells["i"] = []  # Array of indexes
	for i in range(points.size()):
		cells["i"].append(i)
	
	var vertices = packed_grid.vertices

	return {"cells": packed_grid.cells, "vertices": packed_grid.vertices}
# Calculate Delaunay and then Voronoi diagram for the packed grid.
func calculate_voronoi_packed(points: Array, boundary: Array) -> Dictionary:
	var packed_grid: Grid
	var temp = points.size()
	#packed_grid = Grid.new(points.size(), area)
	packed_grid = Grid.new(_cells_desired, area)
	packed_grid.points_n = points.size()
	pack.points_n = points.size()
	var all_points: Array
	all_points.append_array(points)
	all_points.append_array(boundary)
	#points.append_array(boundary)
	#var temp1 = points.size()
	
	# Calculate Delaunay triangulation
	#var vector_points = PackedVector2Array(points)
	var vector_points: PackedVector2Array
	# Brute foce the conversion to packedvector2array from array
	for p in all_points:
		vector_points.append(Vector2(p[0], p[1]))
	#print ("Vector_points: ", vector_points)
	#packed_delaunay = Delaunator.new(points)
	packed_delaunay = Delaunator.new(vector_points)
	pack.points = vector_points
	
	

	# Calculate Voronoi diagram
	#packed_voronoi = Voronoi.new(points, packed_grid, packed_delaunay, area)
	packed_voronoi = Voronoi.new(vector_points, packed_grid, packed_delaunay, area)

	# Extract cells and vertices
	var cells = packed_grid.cells
	cells["i"] = []  # Array of indexes
	for i in range(points.size()):
		cells["i"].append(i)
	
	var vertices = packed_grid.vertices

	return {"cells": packed_grid.cells, "vertices": packed_grid.vertices}

# regraph uses the data from the grid class as a starting point.
# It uses the grid.cells, grid.points and grid.features
# It creates new vaviables cells["p"], "g", and "h" to store the new data 
# that is created
# "p" - vertices coordinates [x, y], integers
# "g" - indexes of a source cell in grid. The only way to find correct grid 
# cell parent for pack cells
#  

func reGraph():
	var new_cells = {"p": [], "g": [], "h": []} # Store new data
	var spacing2 = grid.spacing ** 2
	
	# gridcells = grid.cells
	# points grid.points
	# features = grid.features
	#var quadtree = QuadTree.new(Rect2(Vector2.ZERO, Vector2(10000, 10000))) # Define appropriate bounds
	pack = Pack.new()
	for i in grid.cells["i"]:
		var height = grid.cells["h"][i]
		var type = grid.cells["t"][i]
		
		 # Exclude all deep ocean points
		if height < 20 && type != -1 && type != -2:
			continue
		# Exclude non-coastal lake points
		if type == -2 && (i % 4 == 0 || grid.features[grid.cells["f"][i]]["type"] == "lake"):
			continue 

		# for each point from the existing grid.points grid, add them to the 
		# new variables, 
		var x = grid.points[i].x
		var y = grid.points[i].y
		#add_new_point(i, x, y, height)
		new_cells["p"].append([x, y])
		new_cells["g"].append(i)
		new_cells["h"].append(height)

		# Add additional points for coastal cells
		if type == 1 || type == -1:
			if grid.cells["b"][i]:
				continue # Not for near-border cells
			for e in grid.cells["c"][i]:
				if i > e:
					continue
				if grid.cells["t"][e] == type:
					var dist2 = (y - grid.points[e].y) ** 2 + (x - grid.points[e].x) ** 2
					if dist2 < spacing2:
						continue # Too close
					#var x1 = snappedf((x + grid.points[e].x) / 2, 0.1)
					#var y1 = snappedf((y + grid.points[e].y) / 2, 0.1)
					var x1 = GeneralUtilities.rn((x + grid.points[e].x) / 2, 1)
					var y1 = GeneralUtilities.rn((y + grid.points[e].y) / 2, 1)					
					#add_new_point(i, x1, y1, height)
					new_cells["p"].append([x, y])
					new_cells["g"].append(i)
					new_cells["h"].append(height)
	#print ("new_cells[p]: ", new_cells["p"])
	var packed_grid = calculate_voronoi_packed(new_cells["p"], grid.exterior_boundary_points)
	
	var temp_cells = {"v": [], "c": [], "b": []} # Store tempdata
	
	#pack.cells.points =  new_cells["p"]
	pack.cells["p"] = new_cells["p"]
	pack.cells["g"] = new_cells["g"]
	pack.cells["h"] = new_cells["h"]
	
	
	
	#for p in packed_grid.cells["v"]:
		#if p != null:
			#temp_cells["v"].append(p)
	#for p in packed_grid.cells["c"]:
		#if p != null:
			#temp_cells["c"].append(p)
	#for p in packed_grid.cells["b"]:
		#if p != null:
			#temp_cells["b"].append(p)
			#
#
	#for i in range(grid.points.size()):
		#pack.cells["i"].append(i)
	pack.cells["v"] = packed_grid.cells["v"]
	pack.cells["c"] = packed_grid.cells["c"]
	pack.cells["b"] = packed_grid.cells["b"]
	#pack.cells["v"] = temp_cells["v"]
	#pack.cells["c"] = temp_cells["c"]
	#pack.cells["b"] = temp_cells["b"]
	pack.cells["i"] = packed_grid.cells["i"]
	
	
	
	pack.vertices["p"] = packed_grid.vertices["p"]
	pack.vertices["v"] = packed_grid.vertices["v"]
	pack.vertices["c"] = packed_grid.vertices["c"]

	pass
	
	

	# Insert all points into quadtree
	#for index in range(new_cells["p"].size()):
		#quadtree.insert(Vector2(new_cells["p"][index][0], new_cells["p"][index][1]), index)

	# Store quadtree in pack
	#pack.cells.q = quadtree

func add_new_point(i, x, y, height, new_cells):
	new_cells["p"].append([x, y])
	new_cells["g"].append(i)
	new_cells["h"].append(height)

# This function is to isolate the implementaton of Azgaars Fantasy Map
func generate_azgaar_style_fantasy_map(world_selected: String):
		heightmap_generator = HeightMapGenerator.new(grid, voronoi, world_selected)
		features = Features.new(grid, pack)
		features.markup_grid(grid)
		lakes = Lakes.new()
		map = Map.new()
		temperature = Temperature.new()
		precipitation = Precipitation.new()
		lakes.add_lakes_in_deep_depression(grid, _lake_elevation_limit_output)
		lakes.open_near_sea_lakes(grid, world_selected)
		map.define_map_size(world_selected, grid)
		map.calculate_map_coordinates(grid)
		temperature.calculate_temperatures(grid, map)
		precipitation.generate_precipitation(grid, map)
		reGraph()
		#features.markup_grid_packed_new(pack)
		#features.specify(grid)
		#grid.print_min_max_values()
		#var grid_f_size = grid.f.size()
		#print ("Size of grid.f: ", grid.f.size())
		pass


# Code taken from Godot documenation to start to undersdtand how the mouse
# can be used to interact with the voronoi diagram and to help me understand
# how the cooridnates are working and verify them	
# UR: https://docs.godotengine.org/en/stable/tutorials/inputs/mouse_and_input_coordinates.html
var selected_index = -1  # No site selected initially
func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()
		print("Mouse Click/Unclick at: ", event.position)
		var click_position = event.position
		# The selected site is used when you are going to draw the lines from
		# the Voronoi Cell to its neihbors
		selected_index = find_nearest_site(click_position, delaunay)
		print ("====> Selected Cell: ", selected_index)
		#draw_edges_around_point_test(selected_index)
		for key in voronoi_cell_dict:
			var bool_result : bool = Geometry2D.is_point_in_polygon(click_position, voronoi_cell_dict[key])
			if bool_result == true:
				display_voronoi_cell_data(key, delaunay, voronoi)
		# For now, only redraw the voronoi diagram if you are drawing the lines
		# from the Voronoi Cell to its neighbors
		if (draw_neighbor_lines == true):
			queue_redraw()
		if (_draw_edges_around_point == true):
			queue_redraw()
	elif event is InputEventMouseMotion:
		#print("Mouse Motion at: ", event.position)
		pass
		
	if _use_mouse_to_draw and event is InputEventMouseMotion:
		moving = true		

# Find the nearest index to the provided position. This function is used
# for displaying the voronoi site and its neighbors
func find_nearest_site(position: Vector2, delaunay:Delaunator) -> int:
	var min_distance = INF
	var nearest_index = -1

	# Find the nearest point to the clicked position
	for i in range(points.size()):
		var distance = position.distance_to(points[i])
		if distance < min_distance:
			min_distance = distance
			nearest_index = i
	#var first_occurance = delaunay.triangle[1]
	return nearest_index
	
# Display data about the voronoi cell when you mouse click on the cell. Data
# goes to console
# TODO: Possiblly change this so it is displayed on the map.	
func display_voronoi_cell_data(key: int, delaunay: Delaunator, voronoi: Voronoi):
	print ("Voronoi Cell : ", key)
	print ("Voronoi cell Coords: ", voronoi.voronoi_cell_dict[key])
	print ("Voronoi Cell Vertices: ", voronoi.vertices_of_voronoi_cell(key))
	#print ("Voronoi Cell Indexes: ", voronoi.voronoi_cell_dict_indexes[selected_index])
	print ("Point is: ", points[key])
	#print ("Centroid is: ", voronoi.centroids[key])
	#print ("Elevation: ", elevation.voronoi_cell_elevation[key])
	#print ("Height: ", heightmap_generator.heights[key])
	
func _on_MapRegion_selected(id : int):
	print ("Region #" + str(id) + " was selected.")

func _process(_delta)  -> void:
	if moving:
		if get_global_mouse_position().x >= 0 and get_global_mouse_position().y >= 0:
			delay_timer += 0.1
			if delay_timer > delay_timer_limit:
				delay_timer -= delay_timer_limit
				points.append(get_global_mouse_position())
				delaunay = Delaunator.new(points)
				queue_redraw() # replaces update in Godot 4
			moving = false


func _draw()  -> void:
	
	if _draw_filled_in_triangles: draw_filled_in_triangles(points, delaunay)
	#draw_triangle_data(points, delaunay)
	if _draw_voronoi_cells: draw_voronoi_cells1(points, delaunay)
	if _draw_packed_voronoi_cells: draw_packed_voronoi_cells1(pack.points, packed_delaunay)
	#if _draw_voronoi_cells: draw_voronoi_cells_dict()
	
	if _draw_triangles: draw_triangles(points, delaunay)
	
	#if _draw_triangle_edges: draw_triangle_edges(points, delaunay)
	#if _draw_triangle_edges: draw_triangle_edges_dictionary(voronoi)
	#if _draw_triangle_edges: test_draw_triangle_edges(voronoi.halfedge_coordinates)
	#if _draw_triangle_edges: test1_draw_triangle_edges()
	if _draw_triangle_edges_with_arrows: draw_triangle_edges_with_arrows(points, delaunay)
	
	if _draw_voronoi_cells_convex_hull: draw_voronoi_cells_convex_hull(points, delaunay)

	#if _draw_voronoi_edges: draw_voronoi_edges(points, delaunay)

	#6if _draw_points: draw_points()
	
	if _draw_centroids: draw_centroids()

	if _draw_triangle_circumcenters: draw_triangle_circumcenters()
	if _draw_triangle_circumcenters_circles: draw_circumcenter_circle()	
	
	if _draw_triangle_centers: draw_triangle_centers()
	
	if _draw_triangle_incenters: draw_triangle_incenters()

	# Draw position data on the displayed diagram
	#if _draw_voronoi_cell_site_position_data: draw_point_location_data()
	#if _draw_voronoi_points_position_data: draw_voronoi_cell_position_data()
	
	#var top_left_corner = voronoi._top_left_corner(points, area)
	#print ("=================> top Left Corner: ", top_left_corner, "Coords: ", points[top_left_corner])
	#draw_circle(points[top_left_corner], 2, Color.RED)
	#draw_water_vertices()
	#draw_arrow_line(points, delaunay)
	
	if draw_voronoi_elevation: draw_voronoi_cell_elevation()
	
	if _draw_voronoi_fantasy_heightmap: draw_voronoi_fantasy_heightmap()
	if _draw_fantasy_map_elevations: draw_voronoi_fantasy_elevations()
	if _generate_water_land_map: draw_water_land_map()
	#if _points_from_image: draw_voronoi_fantasy_heightmap_from_image()
	# Draw the feature map for Azgaar style maps
	if _draw_az_feature_map: draw_az_feature_map()
	# Draw the temperature map for Azgaar style maps
	if _draw_az_temperature_map: draw_az_temperature_map()
	# Dwaw the precipitation map for Azgaar style maps
	if _draw_az_precipitation_map: draw_az_precipitation_map()
	
	if _draw_triangle_edges: draw_triangle_edges(points, delaunay)
	#if _draw_packed_triangle_edges: draw_packed_triangle_edges(pack.points, packed_delaunay)
	# pack cells are arrays, so we need to convert them to a packed array for
	# the draw functions. Part of the todo transition away from packed arrays
	# when possible
	#var packed_points: PackedVector2Array = array_to_packed_vector2(pack.cells["p"])
	
	if _draw_packed_voronoi_cells: draw_packed_voronoi_cells1(pack.cells["p"], packed_delaunay)
	#print (pack.cells["p"])
	#if _draw_voronoi_edges: draw_voronoi_edges(points, delaunay)
	#if _draw_packed_triangle_edges: draw_packed_triangle_edges(packed_points, packed_delaunay)
	if _draw_voronoi_edges: draw_voronoi_edges(points, delaunay)
	elif _draw_packed_triangle_edges: draw_packed_triangle_edges(pack.cells["p"], packed_delaunay)
	
	if _draw_points: draw_points()
	if _draw_packed_points: draw_packed_points()
	if _draw_voronoi_cell_site_position_data: draw_point_location_data()
	if _draw_voronoi_points_position_data: draw_voronoi_cell_position_data()
	
	if  _draw_triangle_packed_position_data: display_triangle_position_data(pack.cells["p"])
	elif _draw_triangle_position_data: display_triangle_position_data(points)

 	# Display Data points for Azgaar style maps
	if _display_az_precipitation_data: display_az_precipitation_data()
	if _display_az_temperature_data: display_az_temperature_data()
	if _display_az_elevation_data: display_az_elevation_data()

	# Highlight selected site and its neighbors
	if (draw_neighbor_lines): draw_neighbors()
	
	#if (selected_index != -1 and _draw_edges_around_point): draw_edges_around_point_test()
	if (selected_index != -1 and _draw_edges_around_point): draw_edges_around_point(selected_index)
	#if (selected_index != -1 and _draw_edges_around_point): draw_edges_around_point_4(delaunay, selected_index)
	
	#draw_triangle_data(points, delaunay)
	#if (selected_index != -1 and _draw_edges_around_point): draw_triangles_around_point(points, delaunay, selected_index)
	
	save_image()


func array_to_packed_vector2(arr: Array) -> PackedVector2Array:
	var packed_array: PackedVector2Array = PackedVector2Array()
	for vec in arr:
		if vec is Array and vec.size() == 2:  # Check if it's a tuple (2-element array)
			packed_array.push_back(Vector2(vec[0], vec[1]))  # Convert to Vector2
	return packed_array

# Draw lines from the selected point to its neighbors.
func draw_neighbors():
	if (draw_neighbor_lines == true):
		if selected_index != -1:
			var selected_point = points[selected_index]
		# Draw a blue circle to show the selected 
			draw_circle(selected_point, 7, Color(0, 0, 1))
			# Get neighbors and draw lines to them
			var neighbors = voronoi.get_voronoi_neighbors(selected_index, delaunay)
			for neighbor_index in neighbors:
				# Draw yellow lines to the neighbors
				var neighbor_point = points[neighbor_index]
				draw_line(selected_point, neighbor_point, Color.YELLOW, 2)


#func get_random_points(seed_points = _default_seed_points) -> PackedVector2Array:
	#var new_points := PackedVector2Array() 
	##new_points.resize(initial_points.size() + seed_points)
	#new_points.resize(seed_points)
	#print ("seed_points: ", seed_points)
	#for i in range(new_points.size()):
		#if i >= initial_points.size():
			#var new_point = Vector2(randi() % int(size.x), randi() % int(size.y))
			## Uncomment these lines if you need points outside the boundaries.
##			new_point *= -1 if randf() > 0.5 else 1
##			new_point *= 1.15 if randf() > 0.5 else 1
			#new_point.x = int(new_point.x)
			#new_point.y = int(new_point.y)
			#new_points[i] = new_point
		#else:
			#new_points[i] = initial_points[i]
	#print ("Number of Random points: ", new_points.size())
#
	#return new_points

	
# HELPER FUNCTIONS
# ###################
# Source Link: https://mapbox.github.io/delaunator/
# Source Link: https://github.com/Volts-s/Delaunator-GDScript-4/blob/master/DATA_STRUCTURES.md
# The half-edges of triangle t are 3*t, 3*t + 1, and 3*t + 2. 
# Triangle ids and half-edges are related.
###############################################################################
# The following methods are used to draw the various properties of a Deluanay
# and Voronoi
	
# Constructing triangles

# A triangle is formed from three consecutive half-edges, 
# 3*t, 3*t + 1, 3*t + 2. Each half-edge e starts at points[e], 
# so we can connect those three points into a triangle. 

# This function can do one of two things:
# 1. It can draw the triangle edge. It matches the diagram 
# on:https://mapbox.github.io/delaunator/ called "Dwawing triangle edges"	
func draw_triangles(points: PackedVector2Array, delaunay: Delaunator):
	# set the background color to white and the line color to black. Could do that
	# in project settings by setting the Rendering -> Environment -> Default Clear Color 
	# as well.
	RenderingServer.set_default_clear_color(Color.WHITE)
	for t in delaunay.triangles.size() / 3:
		#print ("t is: ",t, "size of triangles is: ",delaunay.triangles.size() )
		draw_polyline(voronoi.points_of_triangle(points, delaunay, t), Color.BLACK)
		#print ("==> Triangle Coordinates: ", "(", voronoi.points_of_triangle(points, delaunay, t), ")")		
		#draw_polyline(voronoi.adjacent_triangle_edges_coordinates, Color.RED)
		
func draw_filled_in_triangles(points: PackedVector2Array, delaunay: Delaunator):
	#print("draw_triangles: ", delaunay.triangles.size(), " points: ", points.size())
	for t in delaunay.triangles.size() / 3:
		var color = Color(randf(), randf(), randf(), 1)
		draw_polygon(voronoi.points_of_triangle(points, delaunay, t), PackedColorArray([color]))	
		
func draw_single_triangles(triangle_points: PackedVector2Array):
	draw_polyline(triangle_points, Color.BLACK)
		
#######
# Delaunay edges
#######
# We can draw all the triangle edges without constructing the triangles themselves. 
# Each edge is two half-edges. A half-edge e starts at points[delaunay.triangles[e]]. 
# Its opposite delaunay.halfedges[e] starts at the other end, so that tells us the 
# two endpoints of the edge. However, the half-edges along the convex hull won’t 
# have an opposite, so delaunay.halfedges[e] will be -1, and points[delaunay.halfedges[e]] 
# will fail. To reliably find the other end of the edge, we need to instead use 
# points[nextHalfedge(e)]. We can loop through the half-edges and pick half of them to draw.
#
# function forEachTriangleEdge(points, delaunay, callback)
func draw_triangle_edges(points: PackedVector2Array, delaunay: Delaunator):
	var seen : PackedVector2Array
	for e in delaunay.triangles.size():
		var temp_e = delaunay.halfedges[e] # used for DEBUG purposes
		if e > delaunay.halfedges[e]:
			var next_e: int = voronoi.next_half_edge(e)
			# A half-edge e starts at points[delaunay.triangles[e]]
			# delaunay.triangles[e] gets the point id where the half-edge 
			# starts. The point id is used to get the coordinates of the 
			# point as stored in the points[] array
			var p: Vector2 = points[delaunay.triangles[e]]
			# delaunay.triangles[next_half_edge(e)] gets the opposite 
			# half-edge point id in the adjacent triangle or -1 if there is no adjacent
			# triangle. The point id is used to get the coordinates of the 
			# point as stored in the points[] array
			var q: Vector2 = points[delaunay.triangles[voronoi.next_half_edge(e)]]
			# get a different position for display the next shared index
			var mid_point = lerp( p, q, .5) 
			#print("e:", e, " next_half_edge(e):", next_e, " point:", delaunay.triangles[next_e], " point e: ", delaunay.triangles[e])
			#print the edge data being printed
			if _draw_triangle_position_data:
				#print ("Drawing a line for Edge ID: ", e, " from : ", p, " to ", q)
				#print ("Indexes for Edge ID:", " from: ", delaunay.triangles[e], " to: ", delaunay.triangles[voronoi.next_half_edge(e)])
				pass
			# Since a triangle edge point can be shared, this means each time
			# it is shared, its index changes. When you display the index
			# it keeps overwriting and you get a blob. So we make a choice
			# to not overwrite. We lerp the shared index so it shows up in a
			# different position on the line so we can see that value. 
			# Displaying the IDs only works when you have a small diagram.
			# If the diagram gets to big, you just get blobs.
			# You can also look at the data being printed in the output console
			# to see the edge data beig drawn.
			if _draw_triangle_position_data:
				if triangle_position_data == TrianglePositionData.MID_POINTS or triangle_position_data == TrianglePositionData.BOTH:
					draw_position_with_id_at_location(mid_point, p, delaunay.triangles[e], 10, Color.BLUE)
					draw_circle(mid_point, 3, Color.BLUE)
				if seen.find(p) == -1:
				# draw the position id for each triangle point
					if triangle_position_data == TrianglePositionData.CORNERS or triangle_position_data == TrianglePositionData.BOTH:
						draw_position_with_id_at_location(p, p, delaunay.triangles[e], 10, Color.BLACK)
						#draw_position_with_two_ids_at_location(p, p, delaunay.triangles[e], e, 10, Color.BLACK)
					seen.append(p)
				#else:
					#mid_point = lerp (p, q, .8)
					#draw_position_with_id_at_location(mid_point, p, e, 10, Color.RED)
			#draw_position_with_id_at_location(p, p, e, 10, Color.BLACK)	
			draw_line(p, q, Color.RED, 1.0)
	
func draw_packed_triangle_edges(points: PackedVector2Array, delaunay: Delaunator):
	var packed_points: PackedVector2Array = array_to_packed_vector2(pack.cells["p"])
	var seen : PackedVector2Array
	for e in delaunay.triangles.size():
		var temp_e = delaunay.halfedges[e] # used for DEBUG purposes
		if e > delaunay.halfedges[e]:
			var next_e: int = voronoi.next_half_edge(e)
			# A half-edge e starts at points[delaunay.triangles[e]]
			# delaunay.triangles[e] gets the point id where the half-edge 
			# starts. The point id is used to get the coordinates of the 
			# point as stored in the points[] array
			var p: Vector2 = points[delaunay.triangles[e]]
			# delaunay.triangles[next_half_edge(e)] gets the opposite 
			# half-edge point id in the adjacent triangle or -1 if there is no adjacent
			# triangle. The point id is used to get the coordinates of the 
			# point as stored in the points[] array
			var q: Vector2 = points[delaunay.triangles[voronoi.next_half_edge(e)]]
			# get a different position for display the next shared index
			var mid_point = lerp( p, q, .5) 
			#print("e:", e, " next_half_edge(e):", next_e, " point:", delaunay.triangles[next_e], " point e: ", delaunay.triangles[e])
			#print the edge data being printed
			if _draw_triangle_position_data:
				#print ("Drawing a line for Edge ID: ", e, " from : ", p, " to ", q)
				#print ("Indexes for Edge ID:", " from: ", delaunay.triangles[e], " to: ", delaunay.triangles[voronoi.next_half_edge(e)])
				pass
			# Since a triangle edge point can be shared, this means each time
			# it is shared, its index changes. When you display the index
			# it keeps overwriting and you get a blob. So we make a choice
			# to not overwrite. We lerp the shared index so it shows up in a
			# different position on the line so we can see that value. 
			# Displaying the IDs only works when you have a small diagram.
			# If the diagram gets to big, you just get blobs.
			# You can also look at the data being printed in the output console
			# to see the edge data beig drawn.
			if _draw_triangle_position_data:
				if triangle_position_data == TrianglePositionData.MID_POINTS or triangle_position_data == TrianglePositionData.BOTH:
					draw_position_with_id_at_location(mid_point, p, delaunay.triangles[e], 10, Color.BLUE)
					draw_circle(mid_point, 3, Color.BLUE)
				if seen.find(p) == -1:
				# draw the position id for each triangle point
					if triangle_position_data == TrianglePositionData.CORNERS or triangle_position_data == TrianglePositionData.BOTH:
						draw_position_with_id_at_location(p, p, delaunay.triangles[e], 10, Color.BLACK)
						#draw_position_with_two_ids_at_location(p, p, delaunay.triangles[e], e, 10, Color.BLACK)
					seen.append(p)
				#else:
					#mid_point = lerp (p, q, .8)
					#draw_position_with_id_at_location(mid_point, p, e, 10, Color.RED)
			#draw_position_with_id_at_location(p, p, e, 10, Color.BLACK)	
			draw_line(p, q, Color.RED, 1.0)
			
func draw_triangle_data(points: PackedVector2Array, delaunay: Delaunator):
	var seen : PackedVector2Array
	var font : Font
	font = ThemeDB.fallback_font
	var t_size = delaunay.triangles.size() # Size is 126

	for e in delaunay.triangles.size():
		var p: Vector2 = points[delaunay.triangles[e]]	
		var vn: int = voronoi.next_half_edge(e)
		var dh: int = delaunay.halfedges[e]
		var dt = delaunay.triangles[voronoi.next_half_edge(e)]
		#var q: Vector2 = points[voronoi.next_half_edge(e)]
		var edges = voronoi.edges_around_point(delaunay, e) # oroginal call
		var triangles = []
		var triangle_coords = []
	
		if seen.find(p) == -1:
			seen.append(p)
			draw_circle(p, 5, Color.RED)
			var data_string: String =  str(p, ": ", e, ":", 
			delaunay.triangles[e], ":", voronoi.next_half_edge(e))
			draw_string(font, p, data_string, 0, -1, 10, Color.BLACK)	
			
					
func draw_edges_around_point(e):
	var font : Font
	font = ThemeDB.fallback_font
	var edges = voronoi.edges_around_point(delaunay, e) # oroginal call
	
	for edge in edges:
		var p: Vector2 = points[delaunay.triangles[edge]]
		draw_circle(p, 5, Color.GREEN)
		#draw_string(font, p, str(p, ": ", edge, ":", delaunay.triangles[e], ":", e), 0, -1, 10, Color.BLACK)	

		

	
	



		
		
# This functon does the same thing as "draw_triangle_edges", but instead of 
# create the coordinates on the fly, it uses the dictionary "triangle_edges"
# that was created in voronoi. For now, its just a test of the data structure
# Need to decide at what point if I want to keep both or only one.
func draw_triangle_edges_dictionary(voronoi: Voronoi):
	var count = 0
	var seen : PackedVector2Array
	for key in voronoi.triangle_edges:
			var p: Vector2 =voronoi.triangle_edges[key][0]
			var q: Vector2 =voronoi.triangle_edges[key][1]	
			var mid_point = lerp( p, q, .5)
	
			draw_position_with_id_at_location(mid_point, p, key, 10, Color.BLUE)
			draw_line(p, q, Color.RED, 1.0)
			
			if seen.find(p) == -1:
				# draw the position id for each triangle point
				draw_position_with_id_at_location(p, p, key, 10, Color.BLACK)
				seen.append(p)
			else:
				mid_point = lerp (p, q, .8)
				draw_position_with_id_at_location(mid_point, p, key, 10, Color.RED)
	


# Voronoi cells
#
# A Voronoi diagram is built by connecting the Delaunay triangle circumcenters 
# together using the dual of the Delaunay graph.
	# 1. Calculate the circumcenters of each triangle
	# 2. Construct the Voronoi edges from two circumcenters
	# 3. Connect the edges into Voronoi cells

# Voronoi edges
#
# With the circumcenters we can draw the Voronoi edges without constructing the 
# polygons. Each Delaunay triangle half-edge corresponds to one Voronoi polygon 
# half-edge. The Delaunay half-edge connects two points, delaunay.triangles[e] 
# and delaunay.triangles[nextHalfedge(e)]. The Voronoi half-edge connects the 
# circumcenters of two triangles, triangleOfEdge(e) and triangleOfEdge(delaunay.halfedges[e]). 
# We can iterate over the half-edges and construct the line segments.
# This will look like the diagram called "Drawing Voronoi edges".
#
# The line segments that form the boundaries of Voronoi regions are called
# Voronoi edges.
# The endpoints of these edges are called Voronoi vertices
# Each Voronoi vertex is the common intersection of exactly three Voronoi edges
# A Voronoi region will be unbounded if the Point (Voronoi site) is an
# extreme point, then the poinb (Voronoi site) will be part of the convex hull.
func draw_voronoi_edges(points: PackedVector2Array, delaunay: Delaunator) -> void:
	#test_voronoi_cell_dictionary()
	var seen: Array[Vector2]
	
	
	triangle_coordinates.resize(delaunay.triangles.size())
	for e in delaunay.triangles.size():
		#print("triangles size: ", delaunay.triangles.size())
		if (e < delaunay.halfedges[e]):
			#print ("delaunay.halfedge: ",  delaunay.halfedges[e])
			# A triangle center becomes a point that forms the voronoi polygon
			var from: Vector2 = voronoi.triangle_circumcenter(points, delaunay, voronoi.triangle_of_edge(e));
			var to: Vector2 = voronoi.triangle_circumcenter(points, delaunay, voronoi.triangle_of_edge(delaunay.halfedges[e]));
			#print ("p: ", p, " q: ", q)
			#draw_line(
				#Vector2(p[0], p[1]),
				#Vector2(q[0], q[1]),
				#Color.WHITE, 2.0)
			draw_line(
				from,
				to,
				Color.BLACK, 2.0)
			#draw_position_with_id(from, e)
			#draw_position_with_id(to, e)
			if not seen.has(from) and not seen.has(to) :
				seen.append(from)
				seen.append(to)
				#draw_position_with_id(from, e)
				#draw_position_with_id(to, e)
			pass
			
			#print ("Voronoi Edges: ", e, ": ", "(", from,", ", to,")")
			#if (e == 16 or e == 11 or e == 0 or e == 1 or e == 19 or e ==5 or e == 15):
				#var mid_point = lerp( from, to, .5)
				#draw_position_with_id(mid_point, e)
				#draw_circle(mid_point, 2, Color.BLACK)
			#draw_line(
			#Vector2(p[0], p[1]),
				#mid_point,
				#Color.GREEN, 2.0)
			#draw_line(6
			#mid_point,
				#Vector2(q[0], q[1]),
				#Color.BLUE, 2.0)
	#var center_point = find_grid_center_point()
	#draw_circle(Vector2(center_point[0], center_point[1]), 8, Color.DARK_BLUE)
	pass

				
				
# Drawing Voronoi cells
# 
# To draw the Voronoi cells, we can turn a point’s incoming half-edges into 
# triangles, and then find their circumcenters. We can iterate over half-edges, 
# but since many half-edges lead to a point, we need to keep track of which points 
# have already been visited. 	
# This will draw a diagram like the one called "Drawing Voronoi cells"			
func draw_voronoi_cells(points, delaunay):
	var seen = [] # used to keep track of which half-edges have been seen (i.e., iterated over)
	var count_voronoi = 0
	# iterate over all of the triangles
	#test_voronoi_cell_dictionary()
	for e in delaunay.triangles.size():
		var triangles = []
		var vertices = []
		var p = delaunay.triangles[voronoi.next_half_edge(e)]
		# if we have not yet seen this half-edge, iterate over it and set that
		# it has been seen
		if not seen.has(p):
			seen.append(p)
			var edges = voronoi.edges_around_point(delaunay, e)
			#draw_edges_around_point(e)
			for edge in edges:
				6
			for t in triangles:
				vertices.append(voronoi.triangle_circumcenter(points, delaunay, t))
		
		if triangles.size() > 2:
			var color = Color(randf(), randf(), randf(), 1)
			var voronoi_cell = PackedVector2Array()
			for vertice in vertices:
				voronoi_cell.append(Vector2(vertice[0], vertice[1]))			


#func get_edges_around_point_all_triangles(points, delaunay):
	#for e in delaunay.triangles.size():
		#var p = delaunay.triangles[voronoi.next_half_edge(e)]
		#var edges = voronoi.edges_around_point(delaunay, e)
	
		#print ("For Edge: ", e, " Edges around point are: ", edges)
		#print ("For Edge: ", e, " Edges around point are: ", edges)
		
	
		
func draw_voronoi_cells1(points, delaunay):
	var seen = [] # used to keep track of which half-edges have been seen (i.e., iterated over)
	var count_voronoi = 0
	# iterate over all of the triangles
	#test_voronoi_cell_dictionary()
	for e in delaunay.triangles.size():
	
		#print ("selected cell is " , e)
		#print ("Coordinate is ", points[e])
	
		var triangles = []
		var vertices = []
		# This is the center of the voronoi
		# edges_around_point() will calculate the points around this point
		var p = delaunay.triangles[voronoi.next_half_edge(e)]
		#var coords = points[e]
		# This is the starting point
		#var coords1 = points[delaunay.triangles[e]]
		#print ("coords = ", coords, "coords1 = ", coords1)
		#print ("p = ", p, "p coord = ", points[p])
		# if we have not yet seen this half-edge, iterate over it and set that
		# it has been seen
		if not seen.has(p):
			seen.append(p)
			var edges = voronoi.edges_around_point(delaunay, e)
			#print ("Edges ", edges, "e = ", e)
			for edge in edges:
				triangles.append(voronoi.triangle_of_edge(edge))	
			# Here is where we convert the indexes to the actual coordinates
			# for the polygon that will form te voronoi cell
			for t in triangles:
				vertices.append(voronoi.triangle_circumcenter(points, delaunay, t))
		# You need at least 3 vertices to form a voronoi cell, so if it less
		# than three, you do not tray to draw the voronoi cell
		if triangles.size() > 2:	
			var color = Color(randf(), randf(), randf(), 1)
			var voronoi_cell = PackedVector2Array()
			## The vertices are the coordinates for the polygon that will form the 
			## voronoi cell.
			for vertice in vertices:
				voronoi_cell.append(Vector2(vertice[0], vertice[1]))			
			draw_polygon(voronoi_cell, PackedColorArray([color]))		
			#draw_polygon(vertices, PackedColorArray([color]))	

			
			# This is not part of draw voronoi cell. It is here to help me
			# how the voronoi cell is drawm
			#color = Color(randf(), randf(), randf(), 1)
			#for t in triangles:
				##print ("t = ", t)
				#var t_points = voronoi.points_of_triangle(points, delaunay, t)
				#t_points.append(t_points[0])
				#draw_polyline(t_points, color)
				##print (t_points)
				#pass
				#draw_triangles_around_point(points, delaunay, e)
				#draw_filled_in_triangles_around_point(points, delaunay, t)
				#draw_triangles_around_point(points, delaunay, e)
	
			# The way polylabel is currently written, it uses a GeoJSON like 
			# format (an array of arrays of [x,y] points
			# to calculate the bext position for a label
			# This is not currently how the points for the vertices are stored, 
			# so we have to convert the array of vertices to an array of arrays,
			# For now, this will do, but one option is to convert polylabel so 
			# it uses a single array. 
			# COMMENT OUT CODE FOR NOW TILL WE USE IT. DO NOT DELETE
			var test_vertice = []
			test_vertice.append([])
			for vertice in vertices:
				test_vertice[0].append(Vector2(vertice[0], vertice[1]))
		
			var polylabel = PolyLabel.new()
			var result = polylabel.get_polylabel(test_vertice, 1.0, false)
			#draw_number(test_vertice, )
			#draw_circle(Vector2(result[0], result[1]), 6, Color.DARK_GREEN)

func draw_packed_voronoi_cells1(points, delaunay):
	var packed_points: PackedVector2Array = array_to_packed_vector2(points)
	var seen = [] # used to keep track of which half-edges have been seen (i.e., iterated over)
	var count_voronoi = 0
	# iterate over all of the triangles
	#test_voronoi_cell_dictionary()
	for e in delaunay.triangles.size():
	
		#print ("selected cell is " , e)
		#print ("Coordinate is ", points[e])
	
		var triangles = []
		var vertices = []
		# This is the center of the voronoi
		# edges_around_point() will calculate the points around this point
		var p = delaunay.triangles[voronoi.next_half_edge(e)]
		#var coords = points[e]
		# This is the starting point
		#var coords1 = points[delaunay.triangles[e]]
		#print ("coords = ", coords, "coords1 = ", coords1)
		#print ("p = ", p, "p coord = ", points[p])
		# if we have not yet seen this half-edge, iterate over it and set that
		# it has been seen
		if not seen.has(p):
			seen.append(p)
			var edges = voronoi.edges_around_point(delaunay, e)
			#print ("Edges ", edges, "e = ", e)
			for edge in edges:
				triangles.append(voronoi.triangle_of_edge(edge))	
			# Here is where we convert the indexes to the actual coordinates
			# for the polygon that will form te voronoi cell
			for t in triangles:
				vertices.append(voronoi.triangle_circumcenter(points, delaunay, t))
		# You need at least 3 vertices to form a voronoi cell, so if it less
		# than three, you do not tray to draw the voronoi cell
		if triangles.size() > 2:	
			var color = Color(randf(), randf(), randf(), 1)
			var voronoi_cell = PackedVector2Array()
			## The vertices are the coordinates for the polygon that will form the 
			## voronoi cell.
			for vertice in vertices:
				voronoi_cell.append(Vector2(vertice[0], vertice[1]))			
			draw_polygon(voronoi_cell, PackedColorArray([color]))		
			#draw_polygon(vertices, PackedColorArray([color]))	

			
			# This is not part of draw voronoi cell. It is here to help me
			# how the voronoi cell is drawm
			color = Color(randf(), randf(), randf(), 1)
			for t in triangles:
				#print ("t = ", t)
				var t_points = voronoi.points_of_triangle(points, delaunay, t)
				t_points.append(t_points[0])
				draw_polyline(t_points, color)
				#print (t_points)
				pass
				#draw_triangles_around_point(points, delaunay, e)
				#draw_filled_in_triangles_around_point(points, delaunay, t)
				#draw_triangles_around_point(points, delaunay, e)
	
			# The way polylabel is currently written, it uses a GeoJSON like 
			# format (an array of arrays of [x,y] points
			# to calculate the bext position for a label
			# This is not currently how the points for the vertices are stored, 
			# so we have to convert the array of vertices to an array of arrays,
			# For now, this will do, but one option is to convert polylabel so 
			# it uses a single array. 
			# COMMENT OUT CODE FOR NOW TILL WE USE IT. DO NOT DELETE
			var test_vertice = []
			test_vertice.append([])
			for vertice in vertices:
				test_vertice[0].append(Vector2(vertice[0], vertice[1]))
		
			var polylabel = PolyLabel.new()
			var result = polylabel.get_polylabel(test_vertice, 1.0, false)
			#draw_number(test_vertice, )
			#draw_circle(Vector2(result[0], result[1]), 6, Color.DARK_GREEN)

#func find_grid_center_point():
	#var size = get_viewport().size
	#print ("Viewport Size: ", size.x, ":", size.y)
	#var x = size.x/2
	#var y = size.y/2
	#
	#var nearest_site = find_nearest_site(Vector2(x,y), delaunay) 
	#var nearest_point = points[nearest_site]
	#pass




# This is not quite working. Works for some of the points and not others
# Going to leave it for now.
func draw_triangles_around_point(points, delaunay, e):
	var seen = [] # used to keep track of which half-edges have been seen (i.e., iterated over)
	var font : Font
	font = ThemeDB.fallback_font
	
	var e_old = e
	print ("selected cell is " , e)
	print ("Coordinate is ", points[e])
	e = delaunay.triangles.find(e)
	#for e in delaunay.triangles.size():
	
	#var coords = points[e]
	var coords1 = points[delaunay.triangles[e]]
	#print ("coords = ", coords, "coords1 = ", coords1)
	var triangles = []
	var vertices = []
	var p = delaunay.triangles[voronoi.next_half_edge(e)]
	var pe = delaunay.triangles.find(p)
	var pec = voronoi.tris.find(coords1)
	var pecc =  voronoi.triangle_edges_coordinates[pec]
	e = pec
	
	var prev = delaunay.triangles[voronoi.prev_half_edge(e)]
	var pe1 = delaunay.triangles.find(prev)
	var coords2 = points[delaunay.triangles[pe1]]
	var pec1 = voronoi.tris.find(coords2) 
	draw_circle(coords2, 6, Color.BLACK)
	#var coords2 = points[delaunay.triangles[pec1]]
	e = pec1
	# if we have not yet seen this half-edge, iterate over it and set that
	# it has been seen
	#if not seen.has(p):
	if e != -1:
		seen.append(p)
		var edges = voronoi.edges_around_point(delaunay, e)
		#print ("Edges ", edges, "e = ", e)
		for edge in edges:
			triangles.append(voronoi.triangle_of_edge(edge))
		# Here is where we convert the indexes to the actual coordinates
		# for the polygon that will form te voronoi cell
		for t in triangles:
			vertices.append(voronoi.triangle_circumcenter(points, delaunay, t))
	# You need at least 3 vertices to form a voronoi cell, so if it less
	# than three, you do not tray to draw the voronoi cell
	if triangles.size() > 2:	
		var color = Color(randf(), randf(), randf(), 1)
		var voronoi_cell = PackedVector2Array()
		## The vertices are the coordinates for the polygon that will form the 
		## voronoi cell.
		for vertice in vertices:
			voronoi_cell.append(Vector2(vertice[0], vertice[1]))			
		#draw_polygon(voronoi_cell, PackedColorArray([color]))		
		#draw_polygon(vertices, PackedColorArray([color]))	
		color = Color(randf(), randf(), randf(), 1)
		
		for t in triangles:
			#print ("t = ", t)
			var t_points = voronoi.points_of_triangle(points, delaunay, t)
			# Add the first point back so polyline can draw a closed triangle
			# We could also use draw_polygon, but a polygon this way is filled 
			# and covers up stuff which we do not want.
			t_points.append(t_points[0]) 
			draw_polyline(t_points, Color.BLACK)
			#print (t_points)
			#print ("Edges of triangle ", t, ": ", voronoi.edges_of_triangle(t))
			var test_vertice = []
			test_vertice.append([])
			for vertice in t_points:
				test_vertice[0].append(Vector2(vertice[0], vertice[1]))
			var polylabel = PolyLabel.new()
			var result = polylabel.get_polylabel(test_vertice, 1.0, false)
			draw_string(font, Vector2(result[0], result[1]), str(t), 0, -1, 8, Color.BLACK)
			pass
			

func draw_voronoi_cell_elevation():
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()
	#test_voronoi_cell_dictionary()
	for key in voronoi_cell_dict.keys():
		# Get the elevation for this voronoi cell
		var elevation_value: float = elevation.voronoi_cell_elevation[key]
		#var color: Color = elevation.elevation_color(elevation_value)
		var color: Color = elevation.elevation_color_v2(elevation_value)
		#var color: Color = elevation.assign_basic_colors(elevation_value)
		#print("Key:", key, "Value:", voronoi_cell_dict[key])
		draw_polygon(voronoi_cell_dict[key], PackedColorArray([color]))

func draw_filled_in_triangles_around_point(points: PackedVector2Array, delaunay: Delaunator, t):
	#print("draw_triangles: ", delaunay.triangles.size(), " points: ", points.size())
	var color = Color.LIGHT_CYAN
	draw_polygon(voronoi.points_of_triangle(points, delaunay, t), PackedColorArray([color]))	
			
func draw_voronoi_fantasy_heightmap():
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()	
	var color: Color
	for key in voronoi_cell_dict.keys():
		#var elevation_value: int = 	heightmap_generator.heights[key]
		var elevation_value: int = 	grid.heights[key]

		color = elevation.elevation_color_cpt_city_topo_15lev(elevation_value)
		#color = elevation.elevation_color_cpt_city_columbia(elevation_value)
		draw_polygon(voronoi_cell_dict[key], PackedColorArray([color]))	

# NOTE: This code does not work. FIXME
func draw_voronoi_fantasy_heightmap_from_image():
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()	
	var color: Color
	var heights: PackedInt32Array
	var powered
	heights.resize(grid.points.size())
	
	for h in heights.size():
		var im_data: float = image_data[h]
		var lightness: float = float(image_data[h*4] / 255.0)
		if lightness < 0.2:
			powered = lightness
		else:
			powered = 0.2 + pow(lightness - 0.2, 0.8) 
		#heights[h] = minmax(floor(powered * 100), 0, 100)
		heights[h] = (image_data[h]/255.0) * 100.0
		#heights[h] = image_data[h]/255.0
	#print (heights)
	print (image_data)
	for key in voronoi_cell_dict.keys():
		var elevation_value: int = heights[key]
	
		#olor = elevation.elevation_color_azgaar_colors(elevation_value)
		color = Color8(heights[key], heights[key], heights[key])
		
		#color = elevation.elevation_color_cpt_city_columbia(elevation_value)
		var cell_points = voronoi_cell_dict[key]
		#draw_polygon(voronoi_cell_dict[key], PackedColorArray([color]))	
		#for x in voronoi_cell_dict[key]:
			#draw_circle(x, 1, color)
	var i  = 0
	for p in points:
		color =  Color8(image_data[i],image_data[i], image_data[i])
		draw_circle(p, 1, color)
		i += 1
		
		
func minmax(value, min, max):
	return min(max(value, min), max)

## Draw the Azgaar fantasy elevation map. This map displays a specific color
## for each range of elevation. The elevation ranges are found in the
## [Elevation] class
func draw_voronoi_fantasy_elevations():
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()	
	var color: Color
	var elevation_value: int 
	var font : Font
	font = ThemeDB.fallback_font

	#for key in voronoi_cell_dict.keys():
	for key in grid.points_n:
		# Draw the voronoi cell with the elevation colors
		#elevation_value = heightmap_generator.heights[key]
		elevation_value = grid.heights[key]
		color = elevation.elevation_color_azgaar_colors(elevation_value)
		var temp = voronoi_cell_dict[key]
		draw_polygon(voronoi_cell_dict[key], PackedColorArray([color]))	
		
		
		# Use the polylabel position to display the boundary data on the map
		# Used for debugging purposes. Displays whether the cell is a 
		# border cell "1" or not a border cell "0"
		# gather the vertices for the voronoi cell
		if _draw_border_data:
			#var voronoi_vertice = []
			#voronoi_vertice.append([])
			#for vertice in voronoi_cell_dict[key]:
				#voronoi_vertice[0].append(Vector2(vertice[0], vertice[1]))
			## get the polylabel position
			#var polylabel = PolyLabel.new()
			#var result = polylabel.get_polylabel(voronoi_vertice, 1.0, false)
			## set up to print out the border data
			#draw_string(font, Vector2(result[0], result[1]), str(grid.cells["b"][key]), 0, -1, 8, Color.BLACK)
			for p in points.size():
				if grid.cells["b"][p] == 1:
					draw_string(font, points[p], "1", 0, -1, 8, Color.BLACK)

	
	# Display the interior and exterior boundary points. 
	# Used for debugging purposes
	if _draw_boundary_data:
		for b in grid.exterior_boundary_points:
			draw_string(font, Vector2(b[0], b[1]), str(1), 0, -1, 8, Color.BLACK)
		
		for b in grid.interior_boundary_points:
			draw_string(font, Vector2(b[0], b[1]), str(1), 0, -1, 8, Color.RED)
	
	# Used to mark where the azgaar fantasy map starts the height map
	# generation. Not using a flag for this, uncomment/comment out as needed. 
	var temp = heightmap_generator.starting_point
	#draw_circle(heightmap_generator.starting_point, 6, Color.BLACK)

func draw_az_feature_map():
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()	
	var color: Color
	var feature: int 
	var font : Font
	font = ThemeDB.fallback_font
	#var grid_f_size = grid.f.size()
	var grid_f_size = grid.cells["f"].size()

	
	for p in grid.points_n:
		# Draw the voronoi cell with the feature color
		#feature = grid.f[p]
		feature = grid.cells["f"][p]
		#feature = grid.pack.f[p]
		#var distance_field = grid.t[key]
		#var distance_field = grid.t[p]
		var distance_field = grid.cells["t"][p]
		match feature:
			features.DEEPER_LAND: # 3
				color = Color.DARK_GREEN
			features.LANDLOCKED: # 2
				color = Color.SADDLE_BROWN
			features.LAND_COAST: # 1
				color = Color.LIGHT_GREEN
			features.UNMARKED: # 0
				color = Color.RED
			features.WATER_COAST: # -1
				color = Color.LIGHT_BLUE
			features.DEEP_WATER: # -2
				color = Color.DARK_BLUE
			_:
				color = Color.WHITE # No Value set.
				
		draw_polygon(voronoi_cell_dict[p], PackedColorArray([color]))		
		
		# DEBUG CODE 
		var voronoi_vertice = []
		voronoi_vertice.append([])
		#for vertice in voronoi_cell_dict[key]:
		for vertice in voronoi_cell_dict[p]:
			voronoi_vertice[0].append(Vector2(vertice[0], vertice[1]))
			# get the polylabel position
		var polylabel = PolyLabel.new()
		var result = polylabel.get_polylabel(voronoi_vertice, 1.0, false)
			# set up to print out the border data
		draw_string(font, Vector2(result[0], result[1]), str(feature), 0, -1, 8, Color.BLACK)

## Draw a temperature map for the Azgaar style temperature generation
func draw_az_temperature_map():
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()	
	var color: Color
	var feature: int 
	var font : Font
	font = ThemeDB.fallback_font
	
	for p in grid.points_n:
		# Draw the temperature color. For now, its white for anything less than
		# 0 degrees Centigrade and light green for anything above
		var temperature = grid.cells["temp"][p]

		# Color mapping based on the Universal Thermal Scale:
		# https://en.wikipedia.org/wiki/Trewartha_climate_classification
		if temperature >= 35.0: # Severly Hot - 5 °C  or higher 
			color = Color.DARK_RED
		elif temperature >= 28.0 && temperature < 35.0: # Very Hot - 28 to 34.9 °C
			color = Color.RED
		elif temperature >= 22.2 && temperature < 28.0: # Hot - 22.2 to 27.9 °C
			color = Color.INDIAN_RED
		elif temperature >= 18.0 && temperature < 22.2: # Warm - 18 to 22.1 °C 
			color = Color.GREEN
		elif temperature >= 10.0 && temperature < 18.0: # Mild = 10 to 17.9 °C
			color = Color.GREEN_YELLOW
		elif temperature >= 0.1 && temperature < 10.0: # Cool - 0.1 to 9.9 °C
			color = Color.BISQUE
		elif temperature >= -9.9 && temperature < 0.1: # Cold  - −9.9 to 0 °C
			color = Color.ALICE_BLUE
		elif temperature >= -24.9 && temperature < -10.0: # Very Cold - −24.9 to −10 °C
			color = Color.LIGHT_BLUE
		elif temperature >= -39.9 && temperature < -25.0: # Severely cold - −39.9 to −25 °C 
			color = Color.BLUE
		elif temperature >= -40.0: #  	Excessively cold - −40 °C or below
			color = Color.DARK_BLUE
		else:
			color = Color.BLACK # Should not get here.
				
		draw_polygon(voronoi_cell_dict[p], PackedColorArray([color]))		
		
## Draws a precipitation map for Azgaar style maps. It uses a color scheme to 
## display the colors.
func draw_az_precipitation_map():
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()	
	var color: Color
	var feature: int 
	var font : Font
	font = ThemeDB.fallback_font

	for p in grid.points_n:

		var precipitation = grid.cells["prec"][p]
		
		# Basic color scheme. Will replace with a better if a better is
		# found
		if precipitation == 0.0: # Dry 
			color = Color.WHITE_SMOKE
		elif precipitation <= 10.0: # Low precipitation
			color = Color.YELLOW
		elif precipitation <= 20.0: # Moderate precipitation
			color = Color.ORANGE
		elif precipitation <= 40.0: # Wet
			color = Color.ORANGE_RED
		else:
			color = Color.DARK_RED # Very Wet

		draw_polygon(voronoi_cell_dict[p], PackedColorArray([color]))		
	


func draw_water_land_map():
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()	
	var color: Color

	for p in grid.points_n:
		if grid.isLand(p):
			color = Color.DARK_GREEN
		elif grid.isWater(p):
			color = Color.BLUE
		else:
			color = Color.WHITE
		
		draw_polygon(voronoi_cell_dict[p], PackedColorArray([color]))				
		
		
# Convex hull
#
# There’s a problem with the edges_around_point function. Points on the convex hull 
# won’t be completely surrounded by triangles, and the loop will stop partway through, '
# when it hits -1. There are three approaches to this:
	# 1. Ignore it. Make sure never to circulate around points on the convex hull.
	# 2. Change the code.
		# a. Check for -1 in all code that looks at halfedges.
		# b. Change the edges_around_point loop to start at the “leftmost” half-edge so that 
		#    by the time it reaches -1, it has gone through all the triangles.
	# 3. Change the data. Remove the convex hull by wrapping the mesh around the “back”. 
	#    There will no longer be any -1 halfedges.
		# a. Add “ghost” half-edges that pair up with the ones that point to -1.
		# b. Add a single ghost point at “infinity” that represents the “back side” 
		#    of the triangulation.
		# c. Add ghost triangles to connect these ghost half-edges to the ghost point.

# Here’s an example of how to find the “leftmost” half-edge.
# However, even with these changes, constructing the Voronoi cell along the 
# convex hull requires projecting the edges outwards and clipping them. 
# The Delaunator library doesn’t provide this functionality; 
# consider using d3-delaunay if you need it. 
func draw_voronoi_cells_convex_hull(points: PackedVector2Array, delaunay: Delaunator):
	var index = {}

	for e in delaunay.triangles.size():
		var endpoint = delaunay.triangles[voronoi.next_half_edge(e)]
		if (!index.has(endpoint) or delaunay.halfedges[e] == -1):
			index[endpoint] = e

	for p in points.size():
		var triangles = []
		var vertices = []
		var incoming = index.get(p)

		if incoming == null:
			triangles.append(0)
		else:
			var edges = voronoi.edges_around_point(delaunay, incoming)
			for edge in edges:
				triangles.append(voronoi.triangle_of_edge(edge))

		for triangle_index in triangles:
			vertices.append(voronoi.triangle_circumcenter(points, delaunay, triangle_index))

		if triangles.size() > 2:
			var color = Color(randf(), randf(), randf(), 1)
			var voronoi_cell = PackedVector2Array()
			for vertice in vertices:
				voronoi_cell.append(Vector2(vertice[0], vertice[1]))
			#draw_polygon(voronoi_cell, PackedColorArray([color]))
			draw_polygon(voronoi_cell, PackedColorArray([Color.BLACK]))


# Used to draw the points for a voronoi cell. It will display the location
# of the point and its location in the centroid array.
# Draws both the points and the exterior boundary.
func draw_points():
	for point in points:
		draw_circle(point, 2, Color.RED)
		
	for boundary in grid.exterior_boundary_points:
		draw_circle(boundary, 2, Color.GREEN)
	pass
		
func draw_packed_points():
	for point in pack.cells["p"]:
		draw_circle(Vector2(point[0], point[1]), 2, Color.GREEN)	

func display_triangle_position_data(points: Variant):
	var font : Font
	font = ThemeDB.fallback_font
	#for point in pack.cells["p"]:
	for point in points:
		var position_string: String = str(point[0]).pad_decimals(1) + ":" + str(point[1]).pad_decimals(1) 
		draw_string(font,Vector2(point[0], point[1]),position_string , 0, -1, 8, Color.BLACK)
		pass
				




# Used to draw the centroids for a voronoi cell. It will display the location
# of the centroid and its location in the centroid array	
func draw_centroids():	
	var i = 0
	var number_of_centroids = voronoi.get_centroids()
	for point in number_of_centroids:
		draw_circle(point, 2, Color.WHITE)
		draw_position_with_id(point, i)
		i += 1
		
# This function draws the triangle centers. The triangle corner is the 
# circumcenter for the triangle. 
# The circumcenter is often but not always inside the triangle.
# Draws the triangle circumcenter  at the cicumcenter position of the 
# triangle. Writes out the position coordinates and the Id of the triangle.
func draw_triangle_circumcenters():
	for triangle_index in delaunay.triangles.size() / 3:
		var center_1: float = voronoi.triangle_circumcenter(points, delaunay, triangle_index)[0]
		var center_2: float = voronoi.triangle_circumcenter(points, delaunay, triangle_index)[1]
		draw_circle(
			Vector2(center_1, center_2), 2, Color.BLUE)
		var position_id: Vector2i = Vector2(center_1, center_2)
		var index = delaunay.triangles[triangle_index]
		#draw_position_with_id_long(position_id, triangle_index, index)
		draw_position_with_id(position_id, triangle_index)
		

# Draws the triangle center (or centroid) at the center position of the 
# triangle. Writes out the position coordinates and the Id of the triangle.		
func draw_triangle_centers():
	for triangle_index in delaunay.triangles.size() / 3:
		var center_1: float = voronoi.triangle_center(points, delaunay, triangle_index)[0]
		var center_2: float = voronoi.triangle_center(points, delaunay, triangle_index)[1]
		draw_circle(Vector2(center_1,center_2), 2, Color.BLUE)
		var position_id: Vector2i = Vector2(Vector2(center_1,center_2))
		draw_position_with_id(position_id, triangle_index)
		
		
# Draws the triangle center (or centroid) at the center position of the 
# triangle. Writes out the position coordinates and the Id of the triangle.		
func draw_triangle_incenters():
	for triangle_index in delaunay.triangles.size() / 3:
		var center_1: float = voronoi.triangle_incenter(points, delaunay, triangle_index)[0]
		var center_2: float = voronoi.triangle_incenter(points, delaunay, triangle_index)[1]
		draw_circle(Vector2(center_1,center_2), 2, Color.BLUE)
		var position_id: Vector2i = Vector2(Vector2(center_1, center_2))
		draw_position_with_id(position_id, triangle_index)
	
# Draws the circumcenter circle	
func draw_circumcenter_circle():
	var circumcenter_radius: float
	#var circumcenter_radius2: float
	for triangle_index in delaunay.triangles.size() / 3:
		var vertices: PackedVector2Array = voronoi.points_of_triangle(points, delaunay, triangle_index)
		circumcenter_radius = voronoi.calculate_circumcircle_radius(vertices[0], vertices[1], vertices[2])
		var x: float = voronoi.triangle_circumcenter(points, delaunay, triangle_index)[0]
		var y: float = voronoi.triangle_circumcenter(points, delaunay, triangle_index)[1]
		draw_circle(Vector2(x, y), circumcenter_radius, Color.BLUE, false)
		


func save_image():
	
	await RenderingServer.frame_post_draw
	var viewport = get_viewport() 
	var image = viewport.get_texture().get_image()

	image.save_png("res://TestImage.png") 
	print ("Image height = ", image.get_height(), " Image Width = ", image.get_width())
	print ("Size of image data = ", image.get_data_size())
	
	var image_data = image.get_data()

	pass

	
func load_image(path: String):
	if path.begins_with('res'):
		return load(path)
	else:
		var file = FileAccess.open(path, FileAccess.READ)
		if FileAccess.get_open_error() != OK:
			print(str("Could not load image at: ",path))
			return
		var buffer = file.get_buffer(file.get_length())
		var image = Image.new()
		var error = image.load_png_from_buffer(buffer)
		if error != OK:
			print(str("Could not load image at: ",path," with error: ",error))
			return
		return image


# This function iterates over the edges array, drawing each edge as a line 
# and placing arrows along it by calling draw_arrows_along_edge()e edges
# This function and the draw arrows function was provided via chatgtp
# ChatGTP Prompt: "provide an example using arrows to show direction on voronoi edges"
#
# To show direction on Voronoi edges using arrows in GDScript, you draw each 
# edge as a line and place arrowheads along the edges to indicate direction. 
# The key steps involve calculating the midpoint or placing arrowheads at 
# intervals along each edge, then using vector math to orient the arrowheads correctly.		
func draw_triangle_edges_with_arrows(points: PackedVector2Array, delaunay: Delaunator):
	#print("point size:", points.size(), " Triangles:", delaunay.triangles.size())	
	var edge_color = Color.BLUE  # Blue
	var edge_width = 1
	var seen : PackedVector2Array
	for e in delaunay.triangles.size():
		if e > delaunay.halfedges[e]:
			var next_e: int = voronoi.next_half_edge(e)
			var p: Vector2 = points[delaunay.triangles[e]]
			var q: Vector2 = points[delaunay.triangles[voronoi.next_half_edge(e)]]		
			# Draw the edge
			draw_line(p, q, edge_color, edge_width)		
			# Draw directional arrowheads along the edge
			draw_arrow(p, q, edge_color, 70)
			var mid_point = lerp( p, q, .5)
			print ("Drawing a line for edge: ", e, " from : ", p, " to ", q)
			draw_number(mid_point, e)
			if seen.find(p) == -1:
				draw_position(p, 10, Color.BLACK)
				seen.append(p)
	
# Draws arrows as a polygon.
# Parameters
# start: The starting location of the arrow
# end: The end location of the arrow.
# color: The color of the polygon arrow.
func draw_arrow(start: Vector2, end: Vector2, color: Color, spacing: int  = 50):
	# Caculates the unit vector in the direction of the edge
	var direction = (end - start).normalized()
	var edge_length = start.distance_to(end)
	
	# Arrowhead properties
	# Arrows are placed at intervals defined by arrow_spacing along each edge
	#var arrow_spacing = 50 # Controls the distance between arrows.
	var arrow_spacing = spacing
	var arrow_size = 10     # Sets the size of each arrowheadhead
	
	# Place arrowheads along the edge at regular intervals
	for distance in range(arrow_spacing, int(edge_length), arrow_spacing):
		# Calculate position for the arrowhead
		var arrow_pos = start + direction * distance
		
		# Calculate the two points that form the arrowhead triangle
		# The perpendicular vector (Vector2(-direction.y, direction.x)) is used to create
		# the two side points of the arrowhead triangle
		var perpendicular = Vector2(-direction.y, direction.x) * arrow_size / 2
		var left_point = arrow_pos - direction * arrow_size + perpendicular
		var right_point = arrow_pos - direction * arrow_size - perpendicular
		
		# Draw the arrowhead as a filled triangle
		draw_polygon([arrow_pos, left_point, right_point], [color])		
		

	
###############################################################################
###### Functions to draw position data for the voronoi points, etc ############
###### NOTE: These functions only work with a small number of      ############
###### points on the map. Best used with initial_points or a small ############
###### number of random points, around 25 or less.                 ############
###############################################################################
# Draws the coordinate position for the voronoi points, 
# for example "351.231, 675.461". It does not print out the index value since
# voronoi points can be shared by other voronoi cells.
func draw_voronoi_cell_position_data():	
	var seen: Array[Vector2]
	var font: Font
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()
	font = ThemeDB.fallback_font

	for key in voronoi_cell_dict.keys():
		var position : Vector2
		
		# We store when a position has been drawn so we don't draw over existing
		# positions on the screen.
		for i in voronoi_cell_dict[key].size():
			position = voronoi_cell_dict[key][i]
			if not seen.has(position):
				draw_position(position)
				#6draw_number(position, i)
				draw_circle(position, 2, Color.GREEN)
				seen.append(position)

func draw_point_location_data():
	var i: int = 0
	for point in points:
		#draw_position_with_id(point, i)
		draw_number(point, i)
		i += 1
# Displays the Id of the element at the location of point.
func draw_number(point: Vector2, id: int, size_of_font: int = 10, font_color: Color = Color.BLACK) -> void:
	var font: Font
	font = ThemeDB.fallback_font
	draw_string(font, point, str(id), 0, -1, size_of_font, font_color)
	
# Displays the location of the element concatanated with the ID of the element 
# at the position of the point.
func draw_position_with_id(point : Vector2, i: int, size_of_font: int = 10, font_color: Color = Color.BLACK) -> void:
	var font : Font
	font = ThemeDB.fallback_font
	draw_string(font, point, str(point, ": ", i), 0, -1, size_of_font, font_color)
	
func draw_position_with_id_long(point : Vector2, id_1: int, id_2: int, size_of_font: int = 10, font_color: Color = Color.BLACK) -> void:
	var font : Font
	font = ThemeDB.fallback_font
	draw_string(font, point, str(point, ": ", id_1, " (", id_2, ")"), 0, -1, size_of_font, font_color)

func draw_position_with_id_at_location(location: Vector2, point : Vector2, i: int, size_of_font: int = 10, font_color: Color = Color.BLACK) -> void:
	var font : Font
	font = ThemeDB.fallback_font
	draw_string(font, location, str(point, ": ", i), 0, -1, size_of_font, font_color)	

# Thid is a temporary function to use for testing. TESTING
func draw_position_with_two_ids_at_location(location: Vector2, point : Vector2, i: int, j: int, size_of_font: int = 10, font_color: Color = Color.BLACK) -> void:
	var font : Font
	font = ThemeDB.fallback_font
	draw_string(font, location, str(point, ": ", i, ":", j), 0, -1, size_of_font, font_color)	
	
func draw_position(point : Vector2, size_of_font: int = 10, font_color: Color = Color.BLACK) -> void:
	var font : Font
	font = ThemeDB.fallback_font
	draw_string(font, point, str(point), 0, -1, size_of_font, font_color)		
	
		
#############################################################################	
########### OLD STUFF - MOVE OUT AT SOME POINT IF WE DO NOT USE ############
#############################################################################
func test1_draw_triangle_edges():

	var triangle_points: PackedVector2Array
	var temp_vector: Vector2
	#print (voronoi.vertices["c"].size())
	var arrays:  PackedVector2Array

	for key in 18:
		for index in 2:
			#print(key)	
			#print (voronoi.vertices["c"][key])
			#print (voronoi.vertices["c"][key][index])
			var i1: Vector2 = voronoi.vertices["c"][key][index]
			var i2: Vector2 = voronoi.vertices["c"][key][index+1]
			arrays.append(i1)
			arrays.append(i2)

			print ("from : ", i1, " to: ", i2)
			#draw_circle(i1, 4, Color.RED, false)
			#draw_circle(i2, 4, Color.RED, false)
			#draw_circle(voronoi.vertices["c"][key+1], 6, Color.YELLOW, false)
			#draw_line(i1, i2, Color.BLACK, 2.0)
			#draw_line(i1, i2, Color.BLACK, 2.0)
			#draw_position_with_id(i1, key)
			#draw_position_with_id(i2, key)
	
	for i in arrays.size()-1:
		draw_line(arrays[i], arrays[i+1], Color.BLACK, 2.0)		
	#print ("Size of arrays: ", arrays.size())
	#print ("Array: ", arrays)
	
func draw_voronoi_cells_dict():	
	var font
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()
	font = ThemeDB.fallback_font

	for key in voronoi_cell_dict.keys():
		var color = Color(randf(), randf(), randf(), 1)
		draw_polygon(voronoi_cell_dict[key], PackedColorArray([color]))

func test_voronoi_cell_dictionary():
	var i: int = 0
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()
	print ("Voronoi Cells size is: ", voronoi_cell_dict.size())
	for key in voronoi_cell_dict:
		print ("Looking at Voronoi Cell ID: ", key)
		# value will contain all of the voronoi cell vertex's as a 
		# PackedVector2Array
		var value = voronoi_cell_dict[key]
		# vector_value will be used to hold one voronoi cell vertex
		# and convert the location to a vector which draw_char_requires
		var vector_value : Vector2
		vector_value[0] = voronoi_cell_dict[key][0][0]
		vector_value[1] = voronoi_cell_dict[key][0][1]
		# prints the first value of the first voronoi cell vertex
		print ("1: ", value[0][0])
		# prints the second value of the first voronoi cell vertex
		print ("2: ", value[0][1])
		# this prints out the second cell location pair for the cell vertex
		print ("3: ", voronoi_cell_dict[key][1]) 
		# prints the second value of the first voronoi cell vertex
		print ("4: ", voronoi_cell_dict[key][0][1])
		# prints the first vertex in the voronoi cell
		print ("5: ", vector_value)
		# print the number of vertixes that make up the voronoi cell
		print ("size of voronoi cell vertex's: ", voronoi_cell_dict[key].size())
		#
		vector_value = voronoi_cell_dict[key][0]
		print ("6 :", vector_value)
		var neighbors = PackedInt32Array()
		neighbors = voronoi.adjacent_cells(1, delaunay)
		print ("Neighbors: ", neighbors)
		var neighbors2 = PackedInt32Array()
		neighbors2 = voronoi.adjacent_cells1(1, points, delaunay)
		print ("Neighbors2: ", neighbors2)
		
		var neighbors_3: Array = []
		#neighbors_3 = voronoi.get_surrounding_cells()
		#print ("Neighbors_3: ", neighbors_3)
		
		var voronoi_cell_vertices = PackedVector2Array()
		voronoi_cell_vertices = voronoi.vertices_of_voronoi_cell(16)
		print ("Voronoi Cell Vertices: ", voronoi_cell_vertices)		
		i += 1		
				
func test_draw_triangle_edges(halfedges_coordinates: PackedVector2Array):
	#print("point size:", points.size(), " Triangles:", delaunay.triangles.size())	
	
	for e in halfedges_coordinates.size()-1:	
			draw_circle(halfedges_coordinates[e], 4, Color.RED, false)
			draw_circle(halfedges_coordinates[e+1], 6, Color.YELLOW, false)
			draw_line(halfedges_coordinates[e], halfedges_coordinates[e+1], Color.BLACK, 2.0)

func draw_voronoi_cells_vertex_id():	
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()
	for key in voronoi_cell_dict.keys():
		var pos2 : Vector2
		#print("Key:", key, "Value:", voronoi_cell_dict[key])
		for i in voronoi_cell_dict[key].size():
			pos2 = voronoi_cell_dict[key][i]
			draw_number(pos2, key)
			
########## PRINT FUNCTIONS TO VERIFY cells["v"]
# matches cells["v"] dictionary
# this.cells.v[p] = edges.map(e => this.triangleOfEdge(e));
func print_voronoi_cell_edges(points, delaunay):
	var cells: Dictionary = {"v": []} 
	cells["v"].resize(delaunay.halfedges.size())
	var seen = [] # used to keep track of which half-edges have been seen (i.e., iterated over)
	var count_voronoi = 0
	# iterate over all of the triangles
	#test_voronoi_cell_dictionary()
	for e in delaunay.triangles.size():
		var triangles = []
		var vertices = []
		var p = delaunay.triangles[voronoi.next_half_edge(e)]
		#print ("==> P: ", p)
		# if we have not yet seen this half-edge, iterate over it and set that
		# it has been seen
		if not seen.has(p):
			#print ("Not seen p: ", p)
			seen.append(p)
			var edges = voronoi.edges_around_point(delaunay, e)
			for edge in edges:
				triangles.append(voronoi.triangle_of_edge(edge))
			#print ("Edges: ", edges)
			#print ("Triangles: ", triangles)
			for t in triangles:
				vertices.append(voronoi.triangle_circumcenter(points, delaunay, t))
			#print ("Vertices: ", vertices)
			cells["v"][p] = triangles	
		if triangles.size() > 2:
			var voronoi_cell = PackedVector2Array()
			for vertice in vertices:
				voronoi_cell.append(Vector2(vertice[0], vertice[1]))	
			#print ("Voronoi Cell: ", voronoi_cell)
	print ("VERIFYING cells[v]")
	print ("Cells_v", cells["v"])
	print ("cells[v]: ", voronoi.cells["v"])
	
##### PRINT FUNCTIONS TO VERIFY vertices["p"], vertices["v"], and vertices["c"] ###################
# matches vertices["p"] dictionary
# this.vertices.p[t] = this.triangleCenter(t);   
func print_triangle_circumcenters() -> void:
	var tris: PackedVector2Array
	for t in delaunay.triangles.size()/3:
		var x = voronoi.triangle_of_edge(t)
		#var center_1: float = voronoi.triangle_circumcenter(points, delaunay, x)[0]
		#var center_2: float = voronoi.triangle_circumcenter(points, delaunay, x)[1]
		var center_1: float = voronoi.triangle_circumcenter(points, delaunay, t)[0]
		var center_2: float = voronoi.triangle_circumcenter(points, delaunay, t)[1]
		tris.append(Vector2(center_1, center_2))
	print ("VERIFYING vertices[p]")
	print ("Tris Centers: ", tris)
	print ("vertices[p]: ", voronoi.vertices["p"])
	
# Matches vertices["v"] dictionary.
# this.vertices.v[t] = this.trianglesAdjacentToTriangle(t);
func print_triangles_adjacent_to_triangles() -> void:
	var result: Array = []
	for t in delaunay.triangles.size()/3:
		result.append(voronoi.triangle_adjacent_to_triangle(delaunay, t))
	print ("VERIFYING vertices[v]")
	print ("Adjacent Triangles: ", result)
	print ("vertices[v]: ", voronoi.vertices["v"])


# Print out the data for triangles. The following data is printed out
# ==> The total number of triaqngle vertices
# This represents all of the points of  the triagles. This number will be 3 times the size of the 
# actual triangles since it will have duplicate indexes in it. The reason for this is that 
# triangles will share indexes with other triangles in the delaunay triangulation and as a 
# result the total  will be much larger.
# ==> The total number of triangles
# This is the actual number of triangles in the delaunay triangulation.It will be one third of the 
# total number of triangle vertices.
# ===> The delaunay.triangles indexes
# These are indexes of the delaunay triangle vertices. 
# ==> Coordinates of delaunay.triangles
# These are the coordiantes of the vertices of each triangle index. You get the acutal coordinates 
# of the vertices by using the index into the point array.
# The next data is the same as above, but in a different format. For each triangle we print the 
# id of the tirnagle (not the vertex, but an ID we assign based on its position in the 
# delaunay.trianglulation. 
# We then print the coordinates and the indexes as triplets which define the vertices for 
# each triangle.
#
func print_triangles_data(points: PackedVector2Array, delaunay: Delaunator):
	#var temp_t = delaunay.triangles.size() / 3
	var points_of_triangle: PackedInt32Array
	#var index: int
	print ("Total number of triangle vertices: ", delaunay.triangles.size())
	print ("Total number of triangles: ", delaunay.triangles.size() / 3)
	print ("delaunay.triangles indexes: ", delaunay.triangles)
	var tris: PackedVector2Array
	
	for t in delaunay.triangles:
		tris.append(points[t])
	print ("Coordinates of delaunay.triangles: ", tris)
	# Print out the coordinates of the triangle. Each triandle will be made up of three points
	# They are grouped in bracketed groups of three.
	for t in delaunay.triangles.size() / 3:
		print ("Triangle ID: ", t)
		print ("Coordinates: ", "(", voronoi.points_of_triangle(points, delaunay, t), ")")
		# Print out the indexes of the points that form the triangle.
		for e in voronoi.edges_of_triangle(t):
			points_of_triangle.append(delaunay.triangles[e])
		print ("Indexes: ", "(", points_of_triangle, ")")
		points_of_triangle.clear()
		
		
		
		
# matches vertices["c"] dictionary
# this.vertices.c[t] = this.pointsOfTriangle(t);
func print_points_of_triangle() -> void:
	var result: Array = []
	for t in delaunay.triangles.size()/3:
		result.append(voronoi.points_of_triangle(points, delaunay, t))
	print ("VERIFYING vertices[c]")
	print ("Tris Points: ", result)
	print ("vertices[c]: ", voronoi.vertices["c"])
	
	
	
	
func create_canvas_from_image(image_path: String, cells_x: int, cells_y: int, cell_size: int) -> ImageTexture:
	# Load the image from the file
	var loaded_image = Image.new()
	if loaded_image.load(image_path) != OK:
		push_error("Failed to load image: " + image_path)
		return null

	# Resize the image to match the grid size
	var resized_image = loaded_image.duplicate()
	resized_image.resize(cells_x, cells_y, Image.INTERPOLATE_BILINEAR)
	

	# Create a blank canvas for rendering the grid
	var canvas_width = cells_x * cell_size
	var canvas_height = cells_y * cell_size
	var canvas_image = Image.new()
	canvas_image.create(canvas_width, canvas_height, false, Image.FORMAT_RGB8)
	

	# Map each pixel of the resized image to a corresponding grid cell
	for x in range(cells_x):
		for y in range(cells_y):
			var color = resized_image.get_pixel(x, y)  # Get pixel color from resized image
			# Fill the corresponding grid cell with the color
			for i in range(cell_size):
				for j in range(cell_size):
					canvas_image.set_pixel(x * cell_size + i, y * cell_size + j, color)

	# Convert the canvas image to a texture
	var texture = ImageTexture.new()
	texture.create_from_image(canvas_image)
	return texture	

#region Display Data Overlay Functions 
###############################################################################
###                    Display Data Overlay Functions                       ###
###																			###
### These functions overlay data onto the various maps. Which maps can      ###
### have data overlays depends on the map. Here are some general guidance   ###
### Azgaar Data Overlays have the "az" in their description. This data      ###
### can be overlayed on the Azgaar maps which also have "az" in their       ###
### description. For example, you can overlay precipitation data over the   ###
### the precipitation map of the elevation map.                             ###
### 																		###
### Limitation: The overlays should not be used on maps greater than 3000   ###
### cells. The fonts for the data are not scale, so it can turn into a      ###
### dark smears on the map, making the map unreadable.                      ###
###																			###
###############################################################################	

## Display precipitation data on azgaar style maps.
func display_az_precipitation_data() -> void:
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()	
	var font : Font
	font = ThemeDB.fallback_font

	for p in grid.points_n:
		var precipitation = grid.cells["prec"][p]
	
		# Add the precipitation value as text
		var voronoi_vertice = []
		voronoi_vertice.append([])

		for vertice in voronoi_cell_dict[p]:
			voronoi_vertice[0].append(Vector2(vertice[0], vertice[1]))
		# get the polylabel position
		var polylabel = PolyLabel.new()
		var result = polylabel.get_polylabel(voronoi_vertice, 1.0, false)
		# set up to print out the precipitation value
		draw_string(font, Vector2(result[0], result[1]), str(snapped(precipitation, 0.1)), 0, -1, 8, Color.BLACK)			

## Display temperature data on azgaar style maps.
func display_az_temperature_data() -> void:
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()	
	var font : Font
	font = ThemeDB.fallback_font
	
	for p in grid.points_n:

		var temperature = grid.cells["temp"][p]

		# Add the temperature value as text
		var voronoi_vertice = []
		voronoi_vertice.append([])

		for vertice in voronoi_cell_dict[p]:
			voronoi_vertice[0].append(Vector2(vertice[0], vertice[1]))
		# get the polylabel position
		var polylabel = PolyLabel.new()
		var result = polylabel.get_polylabel(voronoi_vertice, 1.0, false)
		# set up to print out the temperature value
		draw_string(font, Vector2(result[0], result[1]), str(temperature), 0, -1, 8, Color.BLACK)
	
	## Display precipitation data on azgaar style maps.
func display_az_elevation_data() -> void:
	var voronoi_cell_dict: Dictionary = voronoi.get_voronoi_cells()	
	var font : Font
	font = ThemeDB.fallback_font

	for p in grid.points_n:
		var elevation = grid.cells["h"][p]
	
		# Add the value as text
		var voronoi_vertice = []
		voronoi_vertice.append([])

		for vertice in voronoi_cell_dict[p]:
			voronoi_vertice[0].append(Vector2(vertice[0], vertice[1]))
		# get the polylabel position
		var polylabel = PolyLabel.new()
		var result = polylabel.get_polylabel(voronoi_vertice, 1.0, false)
		# set up to print out the precipitation value
		draw_string(font, Vector2(result[0], result[1]), str(snapped(elevation, 0.1)), 0, -1, 8, Color.BLACK)			
	
	
#endregion
