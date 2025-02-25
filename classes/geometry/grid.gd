class_name Grid
extends Node
## Code from Azgaar's Fantasy Map Generator
## [br][br]
## Ported from [url] https://github.com/Azgaar/Fantasy-Map-Generator[url
## [br]
## [url] https://github.com/Azgaar/Fantasy-Map-Generator/blob/5bb33311fba48ed83f797c77779dbb909d6e1958/utils/graphUtils.js[/url]
## [br]
## One function ported from mapgen4 at RedBlobGames
## [br]
## [url] https://github.com/redblobgames/mapgen4/blob/master/dual-mesh/create.ts[/url]
## [br]
## Additional details for Azgaar data model can be found here:
## https://github.com/Azgaar/Fantasy-Map-Generator/wiki/Data-model
## The Grid class handles the generation of points for the voronoi diagrams, 
## etc, as well as stores the various paramters used to generate the points.

# PUBLIC VARiABLES

## Contains the points used to create the Voronoi diagram.
## Coordinates [x, y] based on jittered square grid. Numbers rounded 
## to 2 decimals
## Does not include the boundary points.
var points: PackedVector2Array 
## Contains all of the points, including the boundary points. 
var all_points: PackedVector2Array 
## The interior boundary are on the inside of the grid.
##  Off-canvas points coordinates used to cut the diagram approximately by 
## canvas edges.  Performs a form of pseudo-clipping of the polygons
## (voronoi cells)
## In Azgaars code, it is called boundary.
var interior_boundary_points: PackedVector2Array 
## The exterior boundary points are outside of the grid. Used to
## pseudo-clip the polygons. This is from Amits Mapgen program. 
var exterior_boundary_points: PackedVector2Array 
## The number of cells to generate. Used for jittering and random.
## Not used for the initial point seeding or poisson.
## initial count of cells/points requested for map creation. Used to define 
## spacing and place points on a jittered square grid. 
## Actual number of cells is defined by the number points able to place on a 
## square grid. Default cellsDesired is 10 000, maximum - 100 000, 
## minimal - 1 000
var cells_desired: int
## number of cells in column (considers the spacing)
var cells_x: int
## number of cells in row (considers the spacing)
var cells_y: int
## Width of the display area
var width: int
## Height of the display area
var height: int

# These set of variables are set up by the Features class
## Distance field from water level. 
## 1, 2, .... - land cells  
## -1, -2, ... - water cells
## 0 - unmarked cell
var t: Array[int] = []
# indexes of the features
var f: Array[int] = []
# The indexes for the points (does not include boundary points)
var i: Array[int] = []
## a array of dictionaries for all enclosed entities: islands, lakes and oceans
## i: integer - feature id starting from 1
## land: boolean - true if feature is land (height >= 20)
## border: bool - true if feature touches map border (used to separate lakes
## from oceans
## type: String - name of feature, either ocean, island or lake

# Contains dictionary of features for all enclosed entities of original graph: 
# "islands", "lakes" and "oceans". 
var features = []

# Features represent separate locked areas like islands, lakes and oceans.
var feature: Dictionary = {
	# i: integer -  feature id starting from 1
	# land: bool - true if feature is land (height >= 20)
	# border: bool - true if feature touches map border (used to separate lakes from oceans)
	# type: String - feature type, can be "ocean", "island" or `"lake"
}

var haven = []
var harbor = []

var pack: Dictionary = {
	
	"haven": [],
	"harbor": [],
	"features": [],
	"t": [],
	"f": []
}

# Voronoi cells: v = cell vertices, c = adjacent cells, b = near-border cell
# cells["v"] contains the vertixes that make up the voronoi cell polygon.
# The are stoed in the array within the dictionary using the edge id as the
# index.
var cells: Dictionary = {
	"i": [], # integer[] = cell indexes (depending on cells number)
# indexes of cell vertices
	"v": [],  # integer[][]
# indexes of cells adjacent to each cell (neighboring cells)
	"c": [],  # integer[][]
# indicates if cell borders map edge, 1 = true, 0 = false
	"b": [],  # integer[]
# specific cells data
# cells elevation in [0, 100] range, where 20 is the minimal land elevation
	"h": [],
# indexes of feature
	"f": [],
# distance field. 1, 2, ... - land cells, -1, -2, ... - water cells, 
#  0 - unmarked cell. 
	"t": [],	
# cells temperature in Celsius
	"temp": [],
# cells precipitation in unspecified scale
	"prec": [],
	} 
#cells vertices: p = vertex coordinates, v = neighboring vertices, c = adjacent cells
# vertices["v"] contain the vertices for each triangle in the delaunay 
# triangulation. They are stored in the array as triplets (3 indexes for each 
# triangle and are stored using the triangle ID as their position
# in the array.
var vertices: Dictionary = {
# vertex coordinates, [x,y]
	"p": [], # integer[][]
# neindexes of cells adjacent to each vertiex. Each vertex has 3 adjacent cells
	"v": [],  # integer[][]
# indexes of vertices adjacent to each vertex. Most vertexes have 3 neighboring
# vertices, bordering vertices only have 2, while the third vertice is added 
# with a value of -1
	"c": []  # integer[][]
	}

#var heights: PackedInt32Array
# The heights/elevation of each voronoi cell. Ranges from 0 - 100
# Land is >= 20, water is < 20
var heights: Array[int] = []

var points_n: int

# PRIVATE VARIABLES

enum _InitialPointSize {LARGE, MEDIUM, SMALL}
# The area of the rectangle that the points are displayed in.
var _grid_area: Rect2
# The spacing between the points before jittering.
var _spacing: float
	
## Constructor. Create initial grid. 
## 
## The constructor sets the initial values for the grid, but does not 
## initialize the points. This is done by other functions that set the 
## points depending on the type of point generate (jittered, poisson, etc)
## [br]
## [param cells_desired] - the number of points to generate
## [br]
## [param area] - The boundary area that contains the points
##
# In Azgaars code, the placePoints function does the same thing as the
# _init function here
# The main difference between _init and placePoints is that the _init function
# does not set the boundary points or the jittered points. Those two tasks
# are perfomred by set_jittered_grid_points(). I do this so I can use the grid class 
# for other non-azgaar map tasks. 
func _init(cells_desired: int, area: Rect2):
	self.cells_desired = cells_desired
	_grid_area = area
	width = area.size.x
	height = area.size.y
	# snapped() is used to set the decimal places of the float value to 2
	#_spacing = snappedf(sqrt((width * height) / cells_desired),0.01)
	_spacing = GeneralUtilities.rn(sqrt((width * height) / cells_desired),2)
	cells_x = floor((width + 0.5 * _spacing - 1e-10) / _spacing)
	cells_y = floor((height + 0.5 * _spacing - 1e-10) / _spacing)
	
	
	

## Generates [code]cells_desired[/code] jittered points for the grid[br]
## Jittered points are used to generate azgaar type maps.[br]
## Returns the generated [code]points[/code]
func set_jittered_grid_points() -> PackedVector2Array:
	points =  get_jittered_grid(width, height, _spacing)
	
	# set the indexes of the points. Used in the azgaar code only
	for x in range(points.size()):
		i.append(x)
	points_n = points.size()
	exterior_boundary_points = generate_exterior_boundary_points(_grid_area, _spacing)
	for i in exterior_boundary_points:
			points.append(i)
	
	#interior_boundary_points = generate_interior_boundary_points(_grid_area) 
	#for j in interior_boundary_points:
		#points.append(j)
	print ("Number of Random points (jittered grid): ", points.size())	
	return points
	
	
func place_points():
	# The boundary points on the grid which are outside the voronoi cell grid.
	exterior_boundary_points = generate_exterior_boundary_points(_grid_area, _spacing)
	# The points returned do not contain the boundary points.
	points =  get_jittered_grid(width, height, _spacing)
	points_n = points.size() 
	# Combine points with exterior_boundary_points
	# Set up the cells.i index.
	for index in range(points.size()):
		cells["i"].append(index)

	
## Generates points using poisson distributrion for the grid[br]
## Returns the generated [code]points[/code]
func set_points_by_poisson_distribution(sampling_min_distance, sampling_poisson_max_tries):
	var pds: PoissonDiscSampling = PoissonDiscSampling.new()	
	points = pds.generate_points(sampling_min_distance, _grid_area, sampling_poisson_max_tries, Vector2(INF, INF))
	points_n = points.size()
	exterior_boundary_points = generate_exterior_boundary_points(_grid_area, _spacing)
	for i in exterior_boundary_points:
			points.append(i)
	interior_boundary_points = generate_interior_boundary_points(_grid_area) 
	for j in interior_boundary_points:
		points.append(j)		
		
	return points

## Generates random points of [code]size[/code].
##
## There is no spacing with random points. The values are randomly placed
## which can result in clumping of points or large empty spaces.[br]
## [param size] - the number of points to generate
## [br]
## Returns the generated points
func set_random_points(size: Vector2i) -> PackedVector2Array:
	var points := PackedVector2Array() 
	print ("seed_points: ", cells_desired)
	for i in range(cells_desired):
		var new_point = Vector2(randi() % int(size.x), randi() % int(size.y))
		new_point.x = int(new_point.x)
		new_point.y = int(new_point.y)
		points.append(new_point)	

	exterior_boundary_points = generate_exterior_boundary_points(_grid_area, _spacing)
	for i in exterior_boundary_points:
		points.append(i)
		
	interior_boundary_points = generate_interior_boundary_points(_grid_area) 
	for k in interior_boundary_points:
		points.append(k)			
	print ("Number of Random points: ", points.size())
	
	return points

## Generates a set of defined points. This is used for debugging since the
## number of points to generate are quite small making it easier to see
## problems or how things work.  There are three sizes of points to generate 
## from the default initial size to two smaller sizes depending on need.
## [br]
## [param initial_point_size] determines which initial point set to use
##
## [br] Returns the generated points. Note: If the input is not one of 
## LARGE, MEDIUM, or SMALL, it defaults to LARGE.
func set_initial_points(initial_point_size: int) -> PackedVector2Array:
	# Large point set
	var initial_points_large = PackedVector2Array([
  		Vector2(0, 0), Vector2(1024, 0), Vector2(1024, 600), Vector2(0, 600), Vector2(29, 390), Vector2(859, 300), Vector2(65, 342), Vector2(86, 333), Vector2(962, 212), Vector2(211, 351), Vector2(3, 594), Vector2(421, 278), Vector2(608, 271), Vector2(230, 538), Vector2(870, 454), Vector2(850, 351), Vector2(583, 385), Vector2(907, 480), Vector2(749, 533), Vector2(877, 232), Vector2(720, 546), Vector2(1003, 541), Vector2(696, 594), Vector2(102, 306)]
	)
	# Medium point set
	var initial_points_medium = PackedVector2Array([
  		Vector2(0, 0), Vector2(1024, 0), Vector2(1024, 600), Vector2(0, 600), Vector2(29, 390), Vector2(859, 300), Vector2(65, 342),Vector2(86, 333), Vector2(962, 212), Vector2(211, 351), Vector2(3, 594), Vector2(421, 278)]
	)
	# Small point set
	var initial_points_small = PackedVector2Array([
		Vector2(320, 170), Vector2(400, 270), Vector2(220, 270), Vector2(530, 50), Vector2(100, 80), Vector2(300, 30)
	])
	points_n = initial_points_large.size()
	exterior_boundary_points = generate_exterior_boundary_points(_grid_area, 9.47) # DEBUG:AH
	for i in exterior_boundary_points:
		initial_points_large .append(i)
	
	if initial_point_size == _InitialPointSize.LARGE:
		return initial_points_large
	elif initial_point_size == _InitialPointSize.MEDIUM:
		return initial_points_medium
	elif initial_point_size == _InitialPointSize.SMALL:
		return initial_points_small
	else:
		return initial_points_large # default value
	
## Add points along the outside of the map edge to pseudo-clip voronoi cells[br]
## Ported from Azgaars code. This is the getBoundaryPoints() function. I
## renamed it to keep the naming scheme consistent with the generate_interior..
## function
## [url]https://github.com/Azgaar/Fantasy-Map-Generator/blob/23f36c3210d583c32760ddde3c5e6c65ecc8ab52/utils/graphUtils.js[/url]
func generate_exterior_boundary_points(area: Rect2, spacing: float) -> PackedVector2Array:
	#var offset: int = roundi(-1 * spacing)
	var offset: int = GeneralUtilities.rn(-1 * spacing)
	var b_spacing: float = spacing * 2
	var width: int = area.size.x - offset * 2 # DEBUG:AH  
	var height: int = area.size.y- offset * 2 # DEBUG:AH
	var number_x: int = int(ceil(width / b_spacing)) - 1
	var number_y: int = int(ceil(height / b_spacing)) - 1

	var step: float = 0.5
	while step < number_x:
		#var x: int = int(ceil((width * step) / number_x + offset))
		var x: int = ceil((width * step) / number_x + offset)
		exterior_boundary_points.append(Vector2(x, offset))
		exterior_boundary_points.append(Vector2(x, height + offset))
		step += 1
		
	step = 0.5
	while step < number_y:
		#var y: int = int(ceil((height * step) / number_y + offset))
		var y: int = ceil((height * step) / number_y + offset)
		exterior_boundary_points.append(Vector2(offset, y))
		exterior_boundary_points.append(Vector2(width + offset, y))
		step += 1

	return exterior_boundary_points		

## Add points on the inside edge of the map edge.
## Ported from mapgen4: redblobgames
## [url]https://github.com/redblobgames/mapgen4/blob/785e38c1936f524c9f693fe0fa953901943ab7e5/dual-mesh/create.ts#L132[/url]
func generate_interior_boundary_points(area: Rect2) -> PackedVector2Array:	
	var epsilon: float = 1e-4
	var curvature: float = 1.0
	var width: int = area.size.x
	var height: int = area.size.y
	var left: int = area.position[0]
	var top: int = area.position[1]
	var boundary_spacing: float = _spacing
	var W: float = ceil((width - 2 * curvature) / boundary_spacing)
	var H: float = ceil((height - 2 * curvature) / boundary_spacing)
	
	# Top and bottom
	#for q in range(W):
	var q: float = 0.0
	while q < W:
		var t: float = float(q / W)
		var dx: float = (width - 2 * curvature) * t
		var dy: float = epsilon + curvature * 4 * pow(t - 0.5, 2)
		interior_boundary_points.append(Vector2(left + curvature + dx, top + dy))
		interior_boundary_points.append(Vector2(left + width - curvature - dx, top + height - dy))
		q+= 1.0

	# Left and right
	var r: float = 0.0
	#for r in range(H):
	while r < H:
		var t: float = r / H
		var dy: float = (height - 2 * curvature) * t
		var dx: float = epsilon + curvature * 4 * pow(t - 0.5, 2)
		interior_boundary_points.append(Vector2(left + dx, top + height - curvature - dy))
		interior_boundary_points.append(Vector2(left + width - dx, top + curvature + dy))
		r += 1.0
		
	return interior_boundary_points
	
	
## Gets points on a regular square grid and jitters. Does the same thing as 
## Possion Disk Sampling. The main diference is you can set the points to be 
## put ont the rectangle rather than having the Possion deciding on the number 
## of points.
## [br]
## [param width and height] set the area boundary for the points
## [br]
## The points are spaced apart [param spacing] distance
## [br]
## Returns the generated [code]points[/code]
##
func get_jittered_grid(width, height, spacing) -> PackedVector2Array:
	var radius: float = spacing / 2.0 # square radius
	var jittering: float = radius * 0.9; # max deviation
	var double_jittering: float = jittering * 2.0
	var points: PackedVector2Array
	var jitter = func () -> float: 	# lambda
		return randf() * double_jittering - jittering
		
	# NOTE: The commented out use of range is still in the code to remind
	# me that when using range, it only returns ints. In Javascript, when
	# using a for loop with floatsm the index value will be a float while in 
	# gdscript range it will be a int. This can affect the calculations that
	# are used in azgaars code. Make sure when seeing an example of 
	# "for ((let y = radius; y < height; y+= spacing)" where "radius" and 
	# "spacing" are both float values, you want "y' to be a float and not
	# an int. In these cases, use a while loop and not the "for in range"
	var y: float = radius
	while y < height:
		var x: float = radius
		while x < width:
			# These two lines are what you would have if you did not use a
			# lambda. Leaving it here for now to serve as a reminder.
			# Still not sure of the value of using a lambda, but its in Azgaar's
			# code and presents an opporetunity to learn how to use lambdas.
			#var xj: float = min(GeneralUtilities.rn(x + (randf() * double_jittering - jittering), 2), _grid_area.size.x)
			#var yj: float = min(GeneralUtilities.rn(y + (randf() * double_jittering - jittering), 2), _grid_area.size.y)
			var xj: float = min(GeneralUtilities.rn(x + jitter.call(), 2), _grid_area.size.x)
			var yj: float = min(GeneralUtilities.rn(y + jitter.call(), 2),  _grid_area.size.y)
			points.append(Vector2(xj, yj))
			x += spacing
		y += spacing
	# This for in range code left her to serve as a reminder of the above
	# explanation for now.
	#for y in range(radius, height, spacing):
		#for x in range(int(radius), width, spacing):
			#var xj: float = min(GeneralUtilities.rn(x + (randf() * double_jittering - jittering),2), _grid_area.size.x)
			#var yj: float = min(GeneralUtilities.rn(y + (randf() * double_jittering - jittering),2),_grid_area.size.y)
			#points.append(Vector2(xj, yj))
	return points
	
## Return cell index on the grid at location [param x] and [param y]
func find_grid_cell(x: int, y:int):
	#var temp = floor(min(y / _spacing, cells_y - 1.0)) * cells_x + floor(min(x / _spacing, cells_x - 1.0))
	#var temp1 = floor(min(y / _spacing, cells_y - 1.0))
	#var temp2 = floor(min(x / _spacing, cells_x - 1.0))
	#var temp3 = floor(min(y / _spacing, cells_y - 1.0)) * cells_x + floor(min(x / _spacing, cells_x - 1.0))
	#
	#var temp4 = points.find(Vector2(x, y))
	#var temp5 = find_nearest_site(Vector2(x, y))
	#
	#var temp6 = y / _spacing
	#var temp7 = x / _spacing
	#return temp5
	return floor(min(y / _spacing, cells_y - 1.0)) * cells_x + floor(min(x / _spacing, cells_x - 1.0))
	
# Given a point (Vector2), a cell size, and the grid width (in cells),
# this function returns the grid cell index for that point.
func find_grid_cell_index(x, y) -> int:
	var cell_x: int = int(x / _spacing)
	var cell_y: int = int(y / _spacing)
	return cell_x + cell_y * cells_x
	
func find_grid_center_point():
	var x = width/2
	var y = height/2
	
	var nearest_site = find_nearest_site(Vector2(x,y)) 
	var nearest_point = points[nearest_site]
	return nearest_site
	
func find_nearest_site(position: Vector2) -> int:
	var min_distance = INF
	var nearest_index = -1

	# Find the nearest point to the position
	for i in range(points.size()):
		var distance = position.distance_to(points[i])
		if distance < min_distance:
			min_distance = distance
			nearest_index = i
	#var first_occurance = delaunay.triangle[1]
	return nearest_index

## Prints the min/max values for the cells dictionaries.
## Currently used only for debugging purposes.
func print_min_max_values():
	var mininum: Variant
	var maximum: Variant	
	# min/max values for heights
	print("Min/Max values for heights. Min: ", heights.min(), " Max: ", heights.max())
	# min/max values for grid.cells["c"]
	var t_array = cells_min_max(cells["c"])
	print("Min/Max values for cells[c]. Min: ", t_array[0], " Max: ", t_array[1])
	t_array = cells_min_max(cells["v"])
	print("Min/Max values for cells[v]. Min: ", t_array[0], " Max: ", t_array[1])

## This function finds the nim and max values for the cells dictionaries.
## Currently only used for debugging purposes.
func cells_min_max(dict: Array) -> Array:
	var minimum = dict[0][0]
	var maximum = minimum
	for i in dict.size():
		for j in dict[i].size():
			var value = dict[i][j]
			if value > maximum:
				maximum = value
			elif value < minimum:
				minimum = value
	return [minimum, maximum]
	
## filter land cells
func isLand(i):
	return heights[i] >= 20

## filter water cells
func isWater(i):
	return heights[i] < 20;
	
func dist2(x1, y1, x2, y2):
	return (x1 - x2) ** 2 + (y1 - y2) ** 2

	

			
		
	
	
	
	
