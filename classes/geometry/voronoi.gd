class_name Voronoi
extends Node

#var voronoi_cells:= PackedVector2Array()

# A dictionary that contains a key which is the ID of the Voronoi cell and
# an array for each Voronoi Cell that contains the coordinates(vertices) for 
# each point of the Voronoi cell, i.e., the polygon points.	
var voronoi_cell_dict: Dictionary  = {}

# An array that contains all of the unique voronoi vertices (coordinates 
# or corners) of each Voronoi cell. This is different than voronoi_cell_dict
# which contains the vertices for each voronoiu cell that form the cell. In
# that structure there will be duplicates of the vertices since a Voronoi
# Cell can sahre a vertices with anpother Voronoi cell.
var voronoi_vertices:= PackedVector2Array()

# This array contains the voronoi sites (the points) for each Voronoi
# cell. The position in the array is the key (id) for that voronoi cell
# that contains the point.
# This can be used with voronoi_cell_dict to access the vertices for
# the voronoi cell.
# Example:
# voronoi_cell_site[key],. where key is a jey from voronoi_cell_dict and gives
# you the voronoi cell site for that key in the dictionary.
# For a concrete example of this. look at the print_voronoi_cell_data() 
# function.
# NOTE: Another way this could be done is to have another value in the 
# voronopi_cell_dict that holds the voronpoi cell. 
# TODO Consider whether to add the voronoi cell site to the voronoi cell 
# dictionary.
var voronoi_cell_sites:= PackedVector2Array()

# An array of the centroids for the Voronoi cells. NOTE: This is not being used
# currently for anything, so it may be redundant.
var centroids := PackedVector2Array()

var centroids1 := PackedVector2Array()

# The boundary of the voronoi diagram (a Rect2)
var boundary: Rect2

var triangle_centers: PackedVector2Array = PackedVector2Array()

var triangle_edges_coordinates := PackedVector2Array()

# Holds the  coordinates and the indexs for adjacent triangles
var adjacent_triangle_edges_coordinates := PackedVector2Array()
var adjacent_triangle_edges: Array = []

var halfedge_coordinates := PackedVector2Array()
var hull_coordinates := PackedVector2Array()

# Voronoi cells: v = cell vertices, c = adjacent cells, b = near-border cell
# cells["v"] contains the vertixes that make up the voronoi cell polygon.
# The are stoed in the array within the dictionary using the edge id as the
# index.
var cells: Dictionary = {"v": [], "c": [], "b": []} 
#cells vertices: p = vertex coordinates, v = neighboring vertices, c = adjacent cells
# vertices["v"] contain the vertices for each triangle in the delaunay 
# triangulation. They are stored in the array as triplets (3 indexes for each 
# triangle and are stored using the triangle ID as their position
# in the array.

var vertices: Dictionary = {"p": [], "v": [], "c": [] }

var triangle_vertices: Dictionary = {}

func _init(points: PackedVector2Array, delaunay: Delaunator, boundary: Rect2) -> void:
	self.boundary = boundary

	cells["v"] = []
	cells["c"] = []
	cells["b"] = []
	
	cells["v"].resize(delaunay.halfedges.size())
	cells["c"].resize(delaunay.halfedges.size())
	cells["b"].resize(delaunay.halfedges.size())
	
	vertices["p"].resize(delaunay.halfedges.size())
	vertices["v"].resize(delaunay.halfedges.size())
	vertices["c"].resize(delaunay.halfedges.size())
	var seen = []
	
	# for every triangle vertiex
	for e in delaunay.triangles.size():
		var p: int = delaunay.triangles[next_half_edge(e)]
		if p < points.size() and not seen.has(p):
			seen.append(p)
			var edges = edges_around_point_array(delaunay, e)
			# for each element in edges, call triangle_of_edge for each of the 
			# elements and return the triangle id for that edge. This
			# will create a new array and assign it a array element in the 
			# dictionary at element index "p"
			#cells["v"][p] =  edges.map(func(e): return triangle_of_edge(e)) # cell: adjacent vertex
			
			#===>  load up cells["v"]
			var result = []  # Initialize an empty array
			for edge in edges:
				result.append(triangle_of_edge(edge))
				cells["v"][p] = result  # Assign the result to cells["v"][p]

				
			# ===> load up cells["c"]
			cells["c"][p] =  edges.map(func(e): return delaunay.triangles[e]) # cell: adjacent valid cells
			
			# ===> load up cells["b"
			if edges.size() > cells["c"][p].size(): # Cell: is border
				cells["b"][p] = 1
			else:
				cells["b"][p] = 0
				
		var t = triangle_of_edge(e)
		#if not vertices.p.has(t):  # Check if `vertices.p[t]` exists
			# vertex: coordinates
		vertices["p"][t] = triangle_circumcenter_array(points, delaunay, t)           
		vertices["v"][t] = triangle_adjacent_to_triangle(delaunay, t) # vertex: adjacent vertices
		vertices["c"][t] = points_of_triangle(points, delaunay, t)             # vertex: adjacent cellsr 


	setup_voronoi_cells(points, delaunay)
	associate_sites_with_voronoi_cell(points)
	setup_triangle_centers(points, delaunay)
	setup_triangle_edges(points, delaunay)
	#load_triangle_edges(points, delaunay)
	#vertices = add_voronoi_vertices(points, delaunay)
	print ("cells[c]: ", cells["c"])
	

func _ready() -> void:

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
# This function creates the fopllopwing data structures:
# ===> voronoi_cell_dict
#   A dictionrary that contains a key which is the ID of the Voronoi cell and
#   an array for each Voronoi Cell that contains the coordinates(vertices for each 
#   point of the Voronoi cell, i.e., the polygon points.	
# 
# ===> voronoi_vertices
#  An array that contains all of the unique voronoi vertices (coordinates 
#  or corners) of each Voronoi cell. This is different than voronoi_cell_dict
#  which contains the vertices for each voronoiu cell that form the cell. In
#  that structure there will be duplicates of the vertices since a Voronoi
#  Cell can sahre a vertices with anpother Voronoi cell.
# 
# ===> centroids
#  An array that contains all of the centroids for the Voronoi Cells.
#  This is done indirectly through the calculate_centroids functions which 
#  does all of the real work. The setup_voronoi_cells function just calls this
#  function, NOTE: Centroids are not currently used for anything. If this 
#  persists, remove this array in the future.
#
#func setup_voronoi_cells(points: PackedVector2Array, delaunay) -> PackedVector2Array:
func setup_voronoi_cells(points: PackedVector2Array, delaunay):
	var result_dict: Dictionary = {}
	var cell_count : int = 0
	#var result :  PackedVector2Array
	var seen: PackedInt32Array = []
	centroids.clear()
	# Get the number of triangles in the delaunay triangulaton
	for e in delaunay.triangles.size():
		var triangles : PackedInt32Array = []
		# Stores the triangles center. The triangle centers are the circumcenters
		# which are the polygon points used to draw the polygon (i.e. the 
		# voronoi cell)
		var vertices : PackedVector2Array = [] 
		var p = delaunay.triangles[next_half_edge(e)]
		if not seen.has(p):
			seen.append(p)
			var edges = edges_around_point(delaunay, e)
			for edge in edges:
				triangles.append(triangle_of_edge(edge))
			# for each triangle, calculate its center
			for t in triangles:
				var tri_center: Vector2
				tri_center = triangle_circumcenter(points, delaunay, t)
				vertices.append(tri_center) # These are the polygon points
		# go through the triangle vertices and store each one which will make 
		# up the voronoi cell (i.e., the coordinates of the voronoi cell points
		if triangles.size() > 2: 
			var voronoi_cell = PackedVector2Array()
			for vertice in vertices:
				voronoi_cell.append(Vector2(vertice[0], vertice[1]))
				if !voronoi_vertices.has(vertice):
					voronoi_vertices.append(Vector2(vertice[0], vertice[1]))
			var centroid: Vector2
			# Calculate the centroid for the voronoi cell.
			centroid = calculate_centroid(voronoi_cell)
			#centroid = calculate_centroid_1(voronoi_cell)
			#centroids.append(centroid)
			#result.append_array(voronoi_cell)
			# Store the vertices of each Voronoi and use the cell_count
			# increment as its id.
			voronoi_cell_dict[cell_count] = voronoi_cell
			cell_count += 1
	#return result			

func setup_centroids():
	var centroid: Vector2
	print ("Number cells: ",voronoi_cell_dict.size() )
	centroids1.resize(voronoi_cell_dict.size())
	for key in voronoi_cell_dict.keys():
		#print ("Processing centroids: ", voronoi_cell_dict[key])
		centroid = calculate_centroid2(voronoi_cell_dict[key])
		centroids1[key] = centroid
	

# This function creates the fopllopwing data structures:
# 
# ===> triangle_centers: The triangle centers are coordinates fpr each
#  circumcenter.
func setup_triangle_centers(points: PackedVector2Array, delaunay: Delaunator):

	for t in delaunay.triangles.size() / 3:
		var center_1
		var center_2
		center_1 = triangle_circumcenter(points, delaunay, t)[0]
		center_2 = triangle_circumcenter(points, delaunay, t)[1]
		#print ("center_1: ", center_1, " center_2", center_2)
		var temp_triangle_center =  Vector2(triangle_circumcenter(points, delaunay, t)[0],
										  triangle_circumcenter(points, delaunay, t)[1])
		triangle_centers.append(Vector2(triangle_circumcenter(points, delaunay, t)[0],
										  triangle_circumcenter(points, delaunay, t)[1]))

# This function creates the fopllopwing data structures:
#

		
		
# Moves to the next half-edge of a triangle, given the current
# half-edges index
func next_half_edge(e : int) -> int:
	return e - 2 if e % 3 == 2 else e + 1

# Moves to the previous half-edge of a triangle, given the current
# half-edges index	
func prev_half_edge(e : int) -> int:
	return e + 2 if e % 3 == 0 else e - 1
	
# Gets all of the half-edges for a specific triangle.
# Triangle IDs and half-edge IDs are related and can be found 
# using the helper functions edges_of_triangles and triangle_of_edge
# Returns the edge "e" of a triangle
func edges_of_triangle(triangle):
	# function edgesOfTriangle(t) { return [3 * t, 3 * t + 1, 3 * t + 2]; }
	return [3 * triangle, 3 * triangle + 1, 3 * triangle + 2]

# Enables lookup of a triangle, given one of the half-edges of that triangle.
# Give it the edge and you get the triangle index (the ID of the trangle)
# Parameters
# e: the index of the edge
# Returns the index of the triangle for edge "e".
func triangle_of_edge(e) -> int:
	return floor(e / 3)

# Returns the center of the triangle located at the given index.
# Parameters
# p: the starting point
# d: the delaunay triangulation
# t: the index of the triangle
#c: Optional. Defaults to the circumcenter, but can also get the centroid and 
# incenter of the triangle
#func triangle_center(p: PackedVector2Array , d: Delaunator, t: int, c = "circumcenter") -> Vector2:
	#var vertices = points_of_triangle(p, d, t)
	#match c:
		#"circumcenter":
			#return circumcenter(vertices[0], vertices[1], vertices[2])
		#"centroid":
			#return centroid(vertices[0], vertices[1], vertices[2])
		#"incenter":
			#return incenter(vertices[0], vertices[1], vertices[2])
	# will never get here. To stop the annoying error about return paths
	# That error only occurs if you explicitly type the return value in the
	# function signature
	#return circumcenter(vertices[0], vertices[1], vertices[2])	

func triangle_center(triangle_points: PackedVector2Array , delaunay: Delaunator, triangle_index: int) -> Vector2:
	var vertices: PackedVector2Array = points_of_triangle(triangle_points, delaunay, triangle_index)
	return centroid(vertices[0], vertices[1], vertices[2])
	
func triangle_incenter(triangle_points: PackedVector2Array , delaunay: Delaunator, triangle_index: int) -> Vector2:
	var vertices: PackedVector2Array = points_of_triangle(triangle_points, delaunay, triangle_index)
	return incenter(vertices[0], vertices[1], vertices[2])
	
func triangle_circumcenter(triangle_points: PackedVector2Array , delaunay: Delaunator, triangle_index: int) -> Vector2:
	var vertices: PackedVector2Array = points_of_triangle(triangle_points, delaunay, triangle_index)
	var circumcenter_radius: int
	return circumcenter(vertices[0], vertices[1], vertices[2])

func triangle_circumcenter_array(triangle_points: PackedVector2Array , delaunay: Delaunator, triangle_index: int) -> Array:
	var vertices: PackedVector2Array = points_of_triangle(triangle_points, delaunay, triangle_index)
	var circumcenter_radius: int
	var vector_result: Vector2 = circumcenter(vertices[0], vertices[1], vertices[2])
	var result : Array
	result.resize(2)
	result[0] = vector_result[0]
	result[1] = vector_result[1]
	return result
	#return circumcenter(vertices[0], vertices[1], vertices[2])

# Finds the circumcenter of the triangle identifed by points aq, b, and c.
# The formula for circumcenters can be found on 
# Wikipedia: https://en.wikipedia.org/wiki/Circumscribed_circle#Circumcenter_coordinates
# The circumcenter is often but not always inside the triangle. 
# Given a triangle with vertices ABC, the perpendencular bisector of each 
# triangle edge will intersect at a common point called the Circumcenter.
# The circumcenter is equi-distant from points A,B, C and these points all lie
# on a circle with the circumcenter as its center. This circle is called the 
# circumcenter for triangle ABC.
# Connecting the  circumcenters produces the Voronoi diagram
#
# Parameters:
# a: The coordinates of the first point of the triangle
# b: The coordinates of the second point of the triangle
# c: The coordinates of the third point of the triangle
# Returns
# result: the coordinates of the circumcenter of the triangle
func circumcenter(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	var result: Vector2
	var ad: float = a[0] * a[0] + a[1] * a[1]
	var bd: float = b[0] * b[0] + b[1] * b[1]
	var cd: float = c[0] * c[0] + c[1] * c[1]
	var D: float = 2 * (a[0] * (b[1] - c[1]) + b[0] * (c[1] - a[1]) + c[0] * (a[1] - b[1]))
	var inter_value_1: float = 1 / D * (ad * (b[1] - c[1]) + bd * (c[1] - a[1]) + cd * (a[1] - b[1]))
	var inter_value_2: float = 1 / D * (ad * (c[0] - b[0]) + bd * (a[0] - c[0]) + cd * (b[0] - a[0]))

	#result = PackedVector2Array([Vector2(inter_value_1, inter_value_2)])
	#return result
	result = Vector2(inter_value_1, inter_value_2)
	return result
	#return [
		#1 / D * (ad * (b[1] - c[1]) + bd * (c[1] - a[1]) + cd * (a[1] - b[1])),
		#1 / D * (ad * (c[0] - b[0]) + bd * (a[0] - c[0]) + cd * (b[0] - a[0]))
	#]

# Calculates the ccentroid (the center) of a triangle.
func centroid(a, b, c) -> Vector2:
	var c_x: float = (a[0] + b[0] + c[0]) / 3
	var c_y: float = (a[1] + b[1] + c[1]) / 3
	
	var result: Vector2
	result = Vector2(c_x, c_y)
	#return [c_x, c_y]
	return result
	
# Calculates the centroid of a triangle. Note: This does the same thing
# as the centroid() function, instead it takes a Packe3dVector2Array as its 
# parameter
func calculate_center_of_triangle(triangle_coordinates: PackedVector2Array) -> Vector2:
	var x_value = (triangle_coordinates[0].x + triangle_coordinates[1].x + triangle_coordinates[2].x)/3
	var y_value = (triangle_coordinates[0].y + triangle_coordinates[1].y + triangle_coordinates[2].y)/3
	
	return Vector2 (x_value, y_value)	

func incenter(a, b, c) -> Vector2:
	var ab = sqrt(pow(a[0] - b[0], 2) + pow(b[1] - a[1], 2))
	var bc = sqrt(pow(b[0] - c[0], 2) + pow(c[1] - b[1], 2))
	var ac = sqrt(pow(a[0] - c[0], 2) + pow(c[1] - a[1], 2))
	var c_x = (ab * a[0] + bc * b[0] + ac * c[0]) / (ab + bc + ac)
	var c_y = (ab * a[1] + bc * b[1] + ac * c[1]) / (ab + bc + ac)

	var result: Vector2
	result = Vector2(c_x, c_y)
	#return [c_x, c_y]
	return result
	
# The calculate_area and calculate_centroid code is based on the StackExchange
# code: https://gamedev.stackexchange.com/questions/211636/how-to-calculate-the-center-of-mass-of-a-irregular-polygon-in-godot		
func calculate_area(points: PackedVector2Array) -> float:
	var result: float = 0.0
	var num_vertices: int = points.size()
	
	for q in range(num_vertices):
		var p: int = (q - 1 + num_vertices) % num_vertices
		result += points[q].cross(points[p])
	
	return result * 0.5

# This function calculates the centroid for a voronoi cell. It also stores 
# each of the centroids in an array.
# Daata structures created by this function:
# ===> centroids
# An array of the centroids for the Voronoi cells. NOTE: This is not being used
# currently for anything, so it may be redundant.
# TODO: Remove the centroids array if it provides no use
func calculate_centroid(points: PackedVector2Array) -> Vector2:
	var centroid: Vector2 = Vector2()
	var area: float = calculate_area(points)
	var num_vertices: int = points.size()
	var factor: float = 0.0
	#print ("In centroids: ", points)

	for q in range(num_vertices):
		var p: int = (q - 1 + num_vertices) % num_vertices
		factor = points[q].cross(points[p])
		centroid += (points[q] + points[p]) * factor

	centroid /= (6.0 * area)
	centroids.append(centroid)
	return centroid.abs()		
	
func calculate_centroid2(points: PackedVector2Array) -> Vector2:
	var centroid: Vector2 = Vector2()
	var area: float = calculate_area(points)
	var num_vertices: int = points.size()
	var factor: float = 0.0
	#print ("In centroids: ", points)

	for q in range(num_vertices):
		var p: int = (q - 1 + num_vertices) % num_vertices
		factor = points[q].cross(points[p])
		centroid += (points[q] + points[p]) * factor

	centroid /= (6.0 * area)
	return centroid		
		
func calculate_centroid_1(points: PackedVector2Array) -> Vector2:
	var centroid : Vector2 = Vector2.ZERO
	for point : Vector2 in points:
		centroid += point
	return centroid / points.size()
	
# Returns the radius of the circumcircle that any 3 2D points lie on.
# Returns null if degenerate case.
# a, b, and c: The points that lie on the circumcircle.
# Reused from https://github.com/tniyer2/delaunay-voronoi/blob/master/scripts/voronoi.gd
const FLOAT_EPSILON = 0.00001
func calculate_circumcircle_radius(a: Vector2, b: Vector2, c: Vector2):
	var angle = abs((b - a).angle_to(c - a))
	
	var numerator = (b - c).length()
	var denominator = 2 * sin(angle)
	if abs(numerator) <= FLOAT_EPSILON or abs(denominator) <= FLOAT_EPSILON:
		return null
		
	var r = numerator / denominator
	if abs(r) <= FLOAT_EPSILON:
		return null
		
	return r
# 
# Gets the indices of all the incoming and outgoing half-edges that touch a 
# a given point.
# To build the polygons, we need to find the triangles touching a point. 
# The half-edge structures can give us what we need. Let’s assume we have a 
# starting half-edge that leads into the point. We can alternate two steps to loop around:
   # 1. Use nextHalfedge(e) to go to the next outgoing half-edge in the current triangle
   # 2. Use halfedges[e] to go to the incoming half-edge in the adjacent triangle
# Parameters
# delaunay: the delaunay triangulation
# start: the index of an incoming half-edge that leads to the desired point
# Returns
# the indices of all half-edges (incoming or outgoing that touch the point.
func edges_around_point(delaunay: Delaunator, start: int) -> PackedInt32Array:
	var result: PackedInt32Array = []
	var incoming: int = start
	while true:
		result.append(incoming);
		var outgoing: int = next_half_edge(incoming)
		incoming = delaunay.halfedges[outgoing];
		if not (incoming != -1 and incoming != start): break
	return result
	
func edges_around_point_array(delaunay: Delaunator, start: int) -> Array[int]:
	var result: Array[int]
	var incoming: int = start
	while true:
		result.append(incoming);
		var outgoing: int = next_half_edge(incoming)
		incoming = delaunay.halfedges[outgoing];
		if not (incoming != -1 and incoming != start): break
	return result
	
# A triangle is formed from three consecutive half-edges. Each half-edge
# "e" starts at ponts[e], so we can connect those three points into a 
# triangle.
# Parameters
# points: the seed points
# delaunay: The Delaunay Triangulation
# t: The index to the triangle
# Returnws
# points_of_triangle: the IDs of the points comprising the given triangle 't'. 
# the return value is a array comprising of a triplet that has the 
# coordinates of the triangle.
func points_of_triangle(points: PackedVector2Array, delaunay: Delaunator, t: int) -> PackedVector2Array:
	var points_of_triangle := PackedVector2Array() 
	var temp_points : Vector2
	var index : int
	for e in edges_of_triangle(t):
		index = delaunay.triangles[e]
		temp_points = points[delaunay.triangles[e]]
		#points_of_triangle.append(points[delaunay.triangles[e]])
		points_of_triangle.append(temp_points)
		#print ("POINTS OF TRIANGLE: ", points_of_triangle)
	return points_of_triangle

# Return the vertices for a specific Voronoi Cell
func vertices_of_voronoi_cell(voronoi_cell: int) -> PackedVector2Array:
	var voronoi_cell_size : int = voronoi_cell_dict[voronoi_cell].size()
	var result = PackedVector2Array()
	for v in voronoi_cell_size:	
		result.append(voronoi_cell_dict[voronoi_cell][v])
	return result	
	
# Returns the total number of Voronoi Cells in the Voronoi Diagram 
func voronoi_cell_count() -> int:
	return voronoi_cell_dict.size()	

# This function is used to find the point associated with the Voronoi cell.
# We iterate through each voronoi cell and then search to see which point
# is in  the cell (polygon) using Geometry2D.is_point_in_polygon. 	
func associate_sites_with_voronoi_cell(points: PackedVector2Array) -> void:
	voronoi_cell_sites.resize(voronoi_cell_dict.size())
	for key in voronoi_cell_dict:	
		#print("Voronoi ID :", key)
	# for each voronoi, go through the points to see which ones are in the
	# polygon
		var point_index: int = 0
		for p in points:
			var bool_result : bool = Geometry2D.is_point_in_polygon(p, voronoi_cell_dict[key])
			if bool_result == true: 
				#print ("-------> Point : ", p, " FOUND in : ", voronoi_cell_dict[key], "Cell ID : ", key)
				voronoi_cell_sites[key] = p
				point_index += 1
		#print ("Voronoi sites for key: ", key, "point is: ", voronoi_cell_sites[key])
		
# Identifies which triangles are adjacent to a given triangle "t".
# The half-edges of a triangle are used to find the adjacent triangles. 
# Each half-edge's opposite will be in an adjacent triangle, and the 
# triangleOfEdge(e) function will tell us which triangle a half-edge
# is in.
# Parameters
# delaunay: The delauny triangulation
# t: The index of the triangle
# Returns
# asjacent_triangles: The vertices of the triangles that share half-edges 
# with triangle "t"
func triangle_adjacent_to_triangle(delaunay: Delaunator, t: int):
	var adjacent_triangles = []
	for e in edges_of_triangle(t):
		var opposite: int = delaunay.halfedges[e]
		if opposite >= 0:
			adjacent_triangles.append(triangle_of_edge(opposite))
	return adjacent_triangles;		
	
func triangles_around_point(delaunay: Delaunator, start: int) -> PackedInt32Array:
	var edges
	var result: PackedInt32Array = PackedInt32Array()
	
	edges = edges_around_point(delaunay, start)
	result.resize(edges.size())
	
	for idx in edges.size():
		result[idx] = triangle_of_edge(edges[idx])
	#
	return result
	
func add_voronoi_vertices (points: PackedVector2Array, delaunay: Delaunator) -> PackedVector2Array:
	var vertices: PackedVector2Array = PackedVector2Array()
	#print ("Triangle Size: ", delaunay.triangles.size())
	for t in delaunay.triangles.size()/3:
		#print ("Index t: ", t, " triangle center: ", triangle_circumcenter(points, delaunay, t))
		vertices.append(triangle_circumcenter(points, delaunay, t))
	return vertices
			

# Tries to return a vertex from the top left corner
func _top_left_corner(centers: PackedVector2Array, area: Rect2) -> int:
	var idx = 0
	var minimal = centers[0]
	for point in centers.size():
		if centers[point].x <= minimal.x + area.size.x / 10 && centers[point].y <= minimal.y + area.size.y / 10:
			minimal = centers[point]
			idx = point
	return idx	
	
# 
func setup_triangle_edges(points: PackedVector2Array, delaunay: Delaunator):
	#print("point size:", points.size(), " Triangles:", delaunay.triangles.size())	
	
	for e in delaunay.triangles.size():
			if e > delaunay.halfedges[e]:
				var p: Vector2 = points[delaunay.triangles[e]]
				triangle_edges_coordinates.append(p)
			
				var q: Vector2 = points[delaunay.triangles[next_half_edge(e)]]
				adjacent_triangle_edges_coordinates.append(q)
				
				#halfedge_coordinates.append (p)
				#halfedge_coordinates.append (q)
			
	for h in delaunay.hull:
		hull_coordinates.append(points[h])
		
	for t in delaunay.triangles.size()/3:
		adjacent_triangle_edges.append(triangle_adjacent_to_triangle(delaunay, t))	
		
# Returns the indexes of the Voronoi cell sites that are negbors to the 
# specified Voronoi Cell
# In the Delaunay triangulation, each triangle is formed by three neighboring
# points, the Voronoi sites)
#
# Returns an array of the Voronoi site indexes, not the coordinates.
# TODO: It looks like it is also setting the convex hull as neighbors. Not sure 
# that is what I want,  so I need to check this out and deal with it if
# necessary
func get_voronoi_neighbors(point_index: int, delaunay: Delaunator) -> Array:
	var neighbors = []
	var triangles = delaunay.triangles
	var halfedges = delaunay.halfedges

	# Iterate over the triangles to find those containing the point_index 
	# (the target point)
	for edge in range(triangles.size()):
		# Check if this edge belongs to the target point
		if triangles[edge] == point_index:
			# Identify the neighboring point from the current triangle
			#var next_edge1 = (edge + 1) % 3 + (edge / 3) * 3
			var next_edge = next_half_edge(edge)
			var neighbor_point_index = triangles[next_edge]
			if not neighbors.has(neighbor_point_index):
				neighbors.append(neighbor_point_index)
	
			# Follow the half-edge to find the opposite triangle
			#var opposite_edge = halfedges[edge]
			#if opposite_edge != -1:  # Ensure there is a neighboring triangle
				#var opposite_point1 = triangles[(opposite_edge + 1) % 3 + (opposite_edge / 3) * 3]
				#var opposite_point = triangles[next_half_edge(opposite_edge)]
				#print ("Opposite Point: ", opposite_point)
				#if not neighbors.has(opposite_point):
					#neighbors.append(opposite_point)

	return neighbors

	
# Get the voronoi cell dictionary		
func get_voronoi_cells () -> Dictionary:
	return voronoi_cell_dict
	
func get_centroids() -> PackedVector2Array:
	return centroids1
	

func get_voronoi_cell_sites() -> PackedVector2Array:
	return voronoi_cell_sites

# Returns the number of voronoi cells in the voronoi diagram	
func get_number_of_voronoi_cells() -> int:
	return voronoi_cell_sites.size()
	
# Returns the number of verteices in the voronoi diagram. This will be the total number of triangle
# points (i.e., the number of points that make up the voronoi cells. We only return the unique
# number
func get_number_of_voronoi_vertices() -> int:
	return voronoi_vertices.size()
	
# Returns a given vertex by index
func get_vertex(index: int) -> Vector2:
	return triangle_centers[index]
	
# Returns the voronoi diagram boundary (the Rect2)
func get_boundary() -> Rect2:
	return boundary
	
func get_triangle_centers() -> PackedVector2Array:
	return triangle_centers

	
