# Used to support debugging the application.
class_name debug
extends Node

func _init():
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
	
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
func print_triangles_data(points: PackedVector2Array, delaunay: Delaunator, voronoi: Voronoi):
	#var temp_t = delaunay.triangles.size() / 3
	var points_of_triangle: PackedInt32Array
	#var index: int
	print ("Total number of triangle vertices: ", delaunay.triangles.size())
	print ("Total number of triangles: ", delaunay.triangles.size() / 3)
	print ("delaunay.triangles indexes: Size(", delaunay.triangles.size(), ") Indexes: ", delaunay.triangles)
	#print ("vertices[c]: ", voronoi.vertices["c"])
	#print ("Triangle Coordinates: ", "Size(", voronoi.triangle_edges_coordinates.size(), ") Vertices: ", voronoi.triangle_edges_coordinates)
	var tris: PackedVector2Array
	for triangle_index in delaunay.triangles:
		tris.append(points[triangle_index])
	print ("Coordinates of delaunay.triangles: Size(", tris.size(), ") Coords: ", tris)
	print ("Points on the convex hull: ", delaunay.hull)
	print ("Coordinates on the convex hull: ", voronoi.hull_coordinates)

	# Print out the coordinates of the triangle. Each triangle will be made up of three points
	# They are grouped in bracketed groups of three.
	print ("== Print the ID, the indexes of the points that form the triangle and the coordinates of the triangles ==")
	for triangle_index in delaunay.triangles.size() / 3:
		print ("Triangle ID: ", triangle_index)
		print ("Coordinates: ", "(", voronoi.points_of_triangle(points, delaunay, triangle_index), ")")
		# Print out the indexes of the points that form the triangle.
		for e in voronoi.edges_of_triangle(triangle_index):
			points_of_triangle.append(delaunay.triangles[e])
		print ("Indexes: ", "(", points_of_triangle, ")")
		points_of_triangle.clear()

		
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
	
	print ("Total number of voronoi cells: ", voronoi.voronoi_cell_sites.size())
	print ("Voronoi cell site indexes: ",  voronoi.voronoi_cell_sites, "\n")
	print ("Voronoi cell sites in Voronoi.cells[c]")
	print("Printing Voronoi Cells Dictionary: Key (ID) and Vertices (Corners) for the Voronoi Cell")
	for key in voronoi.voronoi_cell_dict:
		print ("Cell ID: (", key, ") ", "Cell Site: ", voronoi.voronoi_cell_sites[key], " Cell Vertices: ", voronoi.voronoi_cell_dict[key])

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
	
	print ("vertices[v]: ", "Size: ", voronoi.vertices["v"].size(), " Indexes: ", voronoi.vertices["v"])
	print ("Adjacent Triangle Edges: ", "Size: ", voronoi.adjacent_triangle_edges.size(), " Indexes: ", voronoi.adjacent_triangle_edges)
	
	print ("Adjacent Triangle Edges Coordinates: ", "Size: ", voronoi.adjacent_triangle_edges_coordinates.size(), " Coordinates: ", voronoi.adjacent_triangle_edges_coordinates)
	
