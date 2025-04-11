class_name Debug
extends Node
## Used to support debugging the application. 
## Provides functions that can print out the various data structures to the
## console.
# FIXME: The debug functions only work with random points, initial points and 
# Poisson disk sampling. They break when using jittered. Jittered points
# are stored in all_points and points, so we need to consider both. For the 
# others, its just points.

var _grid: Grid
var _pack: Pack
var _jittered_grid: bool

# The jittered_grid boolean is used to check when using a jittered_grid
# which handles points differently than the other point generators.
func _init(grid: Grid, pack: Pack, jittered_grid: bool):
	_grid = grid
	_pack = pack
	_jittered_grid = jittered_grid
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
	
	
	
## Print out the data for points.
func print_points_data():
	print("Summary points data")
	print ("Total points: ", _grid.points.size())
	print ("Total all points: ", _grid.all_points.size())
	
	
	
# Print out the data for triangles. The following data is printed out
# ==> The total number of triaqngle vertices
# This represents all of the points of  the triangles. This number will be 3 times the size of the 
# actual triangles since it will have duplicate indexes in it. The reason for this is that 
# triangles will share indexes with other triangles in the delaunay triangulation and as a 
# result the total  will be much larger
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
func print_triangles_data(points: PackedVector2Array, delaunay: Delaunator, voronoi: Voronoi):
	var points_of_triangle: PackedInt32Array
	
	

	#=== Print summary data
	print ("Summary Triangle Data")
	# delaunay.triangles.size(): This represents all of the points of  
	# the triangles. This number will be 3 times the size of the actual 
	# triangles since it will have duplicate indexes in it. The reason for 
	# this is that triangles will share indexes with other triangles in the 
	# delaunay triangulation and as a result the total will be much larger
	# Note: No index in delaunay.triangle should be larger than the 
	# the total number of points.
	print(" The size of the delaunay.triangles should be 3 times the size of vertices[c] amd number of triangles")
	print ("Total number of triangle vertices: ", delaunay.triangles.size())
	print ("Total number of vertices[c]: ", _grid.vertices["c"].size())
	print ("Total number of triangles: ", delaunay.triangles.size() / 3)
	print()
	# Create an array that contains all of the unique indexes of the triangles
	# This array should contain the same number of elements as the points
	# used to create the delaunay triangles
	var unique_triangle_indexes: Array[int] = []
	# iterate over all of the triangles
	for e in delaunay.triangles.size():
		if not unique_triangle_indexes.has(delaunay.triangles[e]):
			unique_triangle_indexes.append(delaunay.triangles[e])
			
	#=== Print validation results
	print ("Validation Steps")
	# The total number of "grid.points" used to generate the delaunay triangles
	# should be equal to the total number of unique triangle points (vertices)
	# in delaunay.triangles
	# 
	# Exception: When generating an Azgaar style map with _jittered_grid
	# "grid.points" is not equal to the number of unqique triangle vertices.
	# "grid.points" in this case are the points without the boundary points.
	# What is passed to Delaunator are the points + the boundary points 
	# and are stored grid.all_points. 
	if _jittered_grid == false:
		if validate_points_against_triangles(points, delaunay) == true:
			print ("Points (%s) are equal to the total number of unique triangle points (%s)" % [points.size(), unique_triangle_indexes.size()])
		else:
			print ("ERROR: Points (%s) are not equal to the total number of unique triangle points (%s)" % [points.size(), unique_triangle_indexes.size()])		
	else:
		if validate_points_against_triangles(_grid.all_points, delaunay) == true:
			print ("All Points (%s) are equal to the total number of unique triangle points (%s)" % [_grid.all_points.size(), unique_triangle_indexes.size()])
		else:
			print ("ERROR: All Points (%s) are not equal to the total number of unique triangle points (%s)" % [_grid.all_points.size(), unique_triangle_indexes.size()])
		
	# There should be no index in delaunay.triangles that is greater than
	# the total number of points
	if _jittered_grid == false:
		if validate_triangle_indexes(points, delaunay) == false:
			print ("The triangle indexes have at least one value that is greater than the total number of points")
			print ("Out of bounds index found: ", delaunay.triangles.max())
		else:
			print ("Validation of triangle index values being less than the total points succeeded")
	else:
		if validate_triangle_indexes(_grid.all_points, delaunay) == false:
			print ("The triangle indexes have at least one value that is greater than the total number of all points")
			print ("Out of bounds index found: ", delaunay.triangles.max())
		else:
			print ("Validation of triangle index values being less than the total of all points succeeded")
	print()
	
	print("Detailed Triangle Data")
	# grid.vertices["c"] has the triangle vertices as triplets. Each entry 
	# contains the three points that form the triangle.
	# Example, ([12, 14, 17), [27, 16, 40], ....)
	# This is the same as if you were to iterate through delauany.tringles and
	# use voronoi.index_of_triangle() to form a triangle
	print ("grid.vertices[c]. Stores the triplets of indexes for the delaunay.triangles: ", _grid.vertices["c"])
	print()
	print("Delaunay triangles. Equivalent to grid.vertices[c]")
	var triangles: Array
	for t in delaunay.triangles.size() / 3:
		triangles.append(voronoi.index_of_triangle(delaunay, t))
	print(triangles)
	
	print()
	# Validate they are the same
	if triangles == _grid.vertices["c"]:
		print("Delaunay triangles and _grid.vertices[c] are equal")
	else:
		print("ERROR: Delaunay triangles and _grid.vertices[c] are not equal")
		
	print()
	
	print ("Delaunay.triangles indexes> Not in triplet form: ", delaunay.triangles)
	print()
	
	# Print the coordinates of each triangle. These will be triplets
	var triangles_points: Array
	if _jittered_grid == false:
		for t in delaunay.triangles.size() / 3:
			triangles_points.append(voronoi.points_of_triangle(points, delaunay, t))
	else:
		for t in delaunay.triangles.size() / 3:
			triangles_points.append(voronoi.points_of_triangle(_grid.all_points, delaunay, t))
	print("Triangle points that form each triangle: ", triangles_points)
	print()
	
	var tris: PackedVector2Array
	var points_data
	if _jittered_grid == false:
		points_data = points
	else:
		points_data = _grid.all_points
	for triangle_index in delaunay.triangles:
		tris.append(points_data[triangle_index])
	print ("Triangle points not in triplet format: Size(", tris.size(), ") Coordinatess: ", tris)
	print()
	
	# Print out the coordinates of the triangle. Each triangle will be made up of three points
	# They are grouped as a triplet. This is tghe same as the above, but prints
	# them in a different view.
	print ("Print the order of the triangle, the indexes of the points that form the triangle and the coordinates of the triangles.")
	for triangle_index in delaunay.triangles.size() / 3:
		print ("Triangle ID: ", triangle_index)
		if _jittered_grid == false:
			print ("Coordinates: ", "(", voronoi.points_of_triangle(points, delaunay, triangle_index), ")")
		else:
			print ("Coordinates: ", "(", voronoi.points_of_triangle(_grid.all_points, delaunay, triangle_index), ")")
		# Print out the indexes of the points that form the triangle.
		for e in voronoi.edges_of_triangle(triangle_index):
			points_of_triangle.append(delaunay.triangles[e])
		print ("Indexes: ", "(", points_of_triangle, ")")
		points_of_triangle.clear()
	print()
	#
	#print ("Triangle Coordinates: ", "Size(", voronoi.triangle_edges_coordinates.size(), ") Vertices: ", voronoi.triangle_edges_coordinates)
#
	#print()
	#print ("Points on the convex hull: ", delaunay.hull)6
	#print()
	#print ("Coordinates on the convex hull: ", voronoi.hull_coordinates)
	#print()
	#print ("_halfedges: ", delaunay._halfedges)	
	
	print ("grid.vertices[v]: Size =  ",_grid.vertices["v"].size(), " : ",  _grid.vertices["v"])
	print()
	print ("grid.vertices[p]: saize = ", _grid.vertices["p"].size(), " : ",  _grid.vertices["p"])
	


		
# Print the data related to voronoi cells. 
# ==> The total number of voronoi cells
# ==> The flat array of the voronoi cell vertices (corners)
# ==> The voronoice cells with the ID and their details
# ====> Cell ID. The index of the voronoi cell in the dictionary. This index is also an index in the 
# ====> points array.
# ====> Cell Site: The site coordinates for the voronoi cell.
# ====> Cell vertices: the polygon vertices (points, corners) that form the polygon (the voronoi cell)
#
func print_voronoi_cell_data(points: PackedVector2Array, delaunay: Delaunator, voronoi: Voronoi):
	
	print ("Total number of voronoi cells: ", voronoi.voronoi_cell_dict.size())
	print()
	#print ("Voronoi cell site indexes: ",  voronoi.voronoi_cell_sites, "\n")
	print ("Voronoi Points: ", points)
	print()
	print ("grid.cells[c]: Size = ",  _grid.cells["c"].size(), " : ", _grid.cells["c"])
	print()
	print ("grid.cells[v]: Size= ", _grid.cells["v"].size(), " : ", _grid.cells["v"])
	print()
	#print ("Voronoi Cell Indexes: ", voronoi.voronoi_site_indexes)
	print("Printing Voronoi Cells Dictionary: Key (ID) and Vertices (Corners) for the Voronoi Cell")
	print ("Size = ", voronoi.voronoi_cell_dict_indexes.size())
	#for key in voronoi.voronoi_cell_dict:
		#print ("Cell ID: (", key, ") ", "Cell Site: ", voronoi.voronoi_cell_sites[key], " Cell Vertices: ", voronoi.voronoi_cell_dict[key])

	for key in voronoi.voronoi_cell_dict:
		print ("Cell ID: (", key, ") ", "Cell Site: ", " Cell Vertices: ", voronoi.voronoi_cell_dict[key])
		print ("Cell Idexes: ", voronoi.voronoi_cell_dict_indexes[key])
		print ("Voronoi Cell Vertices: ", voronoi.vertices_of_voronoi_cell(key))

	
	# var temp1 = voronoi.voronoi_cell_dict # REMOVE WHEN DONE
	# temp1.sort()
	# for key in temp1:
	# 	print ("Cell ID TEMP1: (", key, ") ", "Cell Site: ", " Cell Vertices: ", temp1[key])

func print_triangle_edges_data(voronoi: Voronoi):
	print ("Total number of edges: ", voronoi.triangle_edge_coordinates.size())
	print ("Printing edge coordinates, from:to");
	for key in voronoi.triangle_edge_coordinates:
		#print ("Edge ID: (", key, ") ", "Edges: ", voronoi.triangle_edges[key])
		print ("Edge ID: (", key, ") ", "From: ", voronoi.triangle_edge_coordinates[key][0], " To: ", voronoi.triangle_edge_coordinates[key][1])
		print ("Edge ID: (", key, ") ", "From: ", voronoi.triangle_edge_indexes[key][0], " To: ", voronoi.triangle_edge_indexes[key][1])
# Matches vertices["v"] dictionary.
# this.vertices.v[t] = this.trianglesAdjacentToTriangle(t);
# ATTENTION
# TODO: LOoks like I do not need the dictionary Vertices[v]. The adjacent_triangle_edges array 
# FIXME:  This is not working. Need to redo this.
# has the same data. At some point, we can get rid of vertices[v].
# 
func print_triangles_adjacent_to_triangles(delaunay: Delaunator, voronoi: Voronoi) -> void:
	#var result: Array[int]
	var result: Array
	var t_size = delaunay.triangles.size()-1
	
	
	for t in delaunay.triangles.size()/3:
	#for t in t_size:
		result.append(voronoi.triangle_adjacent_to_triangle(delaunay, t))
	print ("VERIFYING vertices[v]")

	print ("Adjacent Triangles: ", "Size: ", result.size(), " Indexes: ", result)
	
	print ("vertices[v]: ", "Size: ", _grid.vertices["v"].size(), " Indexes: ", _grid.vertices["v"])
	print ("Adjacent Triangle Edges: ", "Size: ", voronoi.adjacent_triangle_edges.size(), " Indexes: ", voronoi.adjacent_triangle_edges)
	
	print ("Adjacent Triangle Edges Coordinates: ", "Size: ", voronoi.adjacent_triangle_edges_coordinates.size(), " Coordinates: ", voronoi.adjacent_triangle_edges_coordinates)
	
## Print out the grid feature data
func print_grid_feature_data():
	print ("=== Grid Features===")
	print ("Grid Feature Data Size: ", _grid.features.size())
	for index in _grid.features.size():
		print ("Grid Feature: ", _grid.features[index])

## Print out the packed feature data	
func print_packed_feature_data():
	print ("=== Packed Features===")
	print ("Packed Feature Data Size: ", _pack.features.size())
	for index in _pack.features.size():
		print ("Packed Feature: ", _pack.features[index])
		
		

# The total points should equal the total number of unique triangle vertices.
# since it is the points that are used to create the delaunay triangles
func validate_points_against_triangles(points: PackedVector2Array, delaunay: Delaunator) -> bool:
	var seen = [] # used to keep track of which half-edges have been seen (i.e., iterated over)
	# iterate over all of the triangles
	for e in delaunay.triangles.size():
		if not seen.has(delaunay.triangles[e]):
			seen.append(delaunay.triangles[e])
			
	if (points.size() == seen.size()):
		return true
	else: 
		return false
		
func validate_triangle_indexes(points: PackedVector2Array, delaunay: Delaunator) -> bool:
	var max = delaunay.triangles.min()
	if max > points.size():
		return false
	else:
		return true
	
