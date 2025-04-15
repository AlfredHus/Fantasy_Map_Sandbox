# Port to Godot 4.1.3 - Tom Blackwell - 18 Mar 2024
# Source URL: https://github.com/Volts-s/Delaunator-GDScript-4

class_name Delaunator

# Delaunator is used for computing the Deluanay Triangulation using sweep
# algorthims.
#
# The Delaunay triangulation is a triangular mesh formed from a set of points 
# in x and y. No point is insided the circumcircle of any triangle.
# The Delaunay traingulation is the dual of the Voronoi diagram.
# Important methods and properties for Delaunator
#
# deluanay.points -> The coordinates of the points as an
# array [x0, y0, x1, y1, ...]
#
# To create a Delaunay Triangulation, you use the constructor and pass it
# the set of (x,y) point coordinates where points is a flat array of the 
# form (x0, y0, x1, y1, ...).
# delaunay = new Delaunator(points) where each point provides the x,y
# coordinate of the point in the window.
# After constructing a delaunay object, it will have a triangles array and a 
# half-edges array, both indexed by a half-edge id.
#
# A triangle edge may be shared with another triangle. Instead of thinking 
# about each edge A<->B, we will use two half-edges A -> B and B -> A.
# Note: The indexes into the half-edges array are not the same indexes into
# triangles array. In order to go from a half-edge to get the triangle
# index, you use the two helper functions below:
# Triangle ids and half-edge ids are related
#   a, The half-edges of triangle "t" are 3*t, 3*t + 1, and 3*t + 2.
#   b. The triangle of half-edge id "e" is floor(e/3).
# Half-edges "e" are the indices into both of delaunator's outputs:
#	a. delaunay.triangles[e] returns the point id where the half-edge starts
#   b. delaunay.halfedges[e] returns the opposite half-edge in the adjacent 
#      triangle, or -1 if there is no adjacent triangle.
#
# deluanay.triangles ->  is an array that contains the triangle vertix indices (each 
# group of three numbers forms a triangle). Each contiguous triplet of
# indexes, i, j, k forms a couinter-clockwise triangle. All triangles are directed
# counter-clockwise.
# The coordinates of the triangle points can be found by going through the 
# delaunay.points.



const EPSILON = pow(2, -52)

#var edge_stack = []
var edge_stack := PackedFloat32Array()
# coords is an array of input cooridnates in the form of [x0, y0, x1, y1, ...]
var coords := PackedFloat32Array()

# stores all of the half-edges that define the triangles. Each triangle will have its own half-edge 
# that defines its shape instead of sharing a edge with the adjacent triangle.
# The adjacent triangle will have its own half-edge that defines its shape. That means there is 
# normally a opposite or adjacent half-edge for each half-edge.
# Each halfedge value cooresponds to the initial seed points that were used to create the 
# delaunay triangulation.  To get that specific point for a half-edge, you would use the 
# half-edge index into the points array.
# Example: halfedges ID = 20. You would go into into points and the 20th point in the array 
# would be the location of that halfedge. To get the next half-edge, you would use the
# helper function next_half_edge().
var halfedges := PackedInt32Array()

# hull is a array of indices that reference points on the convex hull of the input data counter-clockwise
# var hull := [] # This array should be a PackedInt32Array but we need to use the super.slice() function on it.
var hull := PackedInt32Array()
# triangles array
# The triangles are stored as a integer array of triangle vertex indices (each group of 
# three numbers (triplets) forms a triangle. You can get the coordinate of a triangle vertex
# by using the index of the triangle in the points array which will return the coordiante for that
# triangle vertex.
var triangles: Array = []

var triangles_len := 0
var _cx: float
var _cy: float


# half edges array
# a triangle edge may be shared with another triangle. Instead of linking each edge A <-> B, two
# hald-edges A->B and B -> A are used. 
# Half-edges are stored as a array of triangle half-edge indices that allows you to 
# traverse the triangulation. i-th half-edge in the array cooresponds to vertex triangles[i]
# the half edge is coming from. _halfedges[i] is the index of a tgwin half-edge in an adjacent
# triangle (or -1 for outer half-edges on the convex hull)
#var _halfedges := [] # This array should be a PackedInt32Array but we need to use the super.slice() function on it.
var _halfedges := PackedInt32Array() # packed array of 32-bit integers.

# temporary arrays for tracking the edges of the advancing convex hull
var _hash_size: int
var _hull_hash := PackedInt32Array()
var _hull_next := PackedInt32Array()
var _hull_prev := PackedInt32Array()
var _hull_start: int
var _hull_tri := PackedInt32Array()

# temporary arrays for sorting points
var _ids := [] # PackedInt32Array, but causes errors if not an array

# The distance from the center of the circumcircle to each point.
var _dists := PackedFloat32Array()

#var _triangles := []  # This array should be a PackedInt32Array but we need to use the super.slice() function on it.
var _triangles := PackedInt32Array()

# _init is called first when the constructor is called.
func _init(points: PackedVector2Array) -> void:

	if points.size() < 3:
		push_error(ProjectSettings.get_setting("application/config/name") + " needs at least 3 points.")
		return

	edge_stack.resize(512)

	var n := points.size()
	coords.resize(n * 2)

	for i in n:
		var p := points[i]
		coords[2 * i] = p[0]
		coords[2 * i + 1] = p[1]

	_constructor()

# Constructs a delaunay triangulation object given an array of point coordinates of 
# the form: [x0, y0, x1, y1, ...] 
# Each of these values are the coordinates of the points for each triangle in the 
# delaunay.
func _constructor() -> void:
	var n := coords.size() >> 1

	# Arrays that will store the triangulation graph. 
	var max_triangles := int(max(2 * n - 5, 0))
	_triangles.resize(max_triangles * 3)
	_halfedges.resize(max_triangles * 3)

	# Temporary arrays for tracking the edges of the advancing convex hull.
	_hash_size = int(ceil(sqrt(n)))
	_hull_prev.resize(n) # Edge to prev edge.
	_hull_next.resize(n) # Edge to next edge.
	_hull_tri.resize(n) # Edge to adjacent triangle.

	_hull_hash.resize(_hash_size)
	for i in _hash_size:
		_hull_hash[i] = -1 # angular edge hash

	# Temporary arrays for sorting points.
	_ids.resize(n)
	_dists.resize(n)

	update()
	pass

# Updates the triangulation if you modified delaunay.coords values in place, 
# avoiding expensive memory allocations. Useful for iterative relaxation algorithms such as Lloyd's.
func update() -> void:
	var n := coords.size() >> 1

	# Populate an array of point indices; calculate input data bbox.
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF

	for i in n:
		var x := coords[2 * i]
		var y := coords[2 * i + 1]
		if x < min_x: min_x = x
		if y < min_y: min_y = y
		if x > max_x: max_x = x
		if y > max_y: max_y = y
		_ids[i] = i

	var cx := (min_x + max_x) / 2
	var cy := (min_y + max_y) / 2

	var min_dist := INF
	var i0 := 0
	var i1 := 0
	var i2 := 0

	# Pick a seed point close to the center.
	for i in n:
		var d := dist(cx, cy, coords[2 * i], coords[2 * i + 1])
		if (d < min_dist):
			i0 = i
			min_dist = d
	var i0x := coords[2 * i0]
	var i0y := coords[2 * i0 + 1]

	min_dist = INF

	# Find the point closest to the seed.
	for i in n:
		if i == i0: continue
		var d := dist(i0x, i0y, coords[2 * i], coords[2 * i + 1])
		if (d < min_dist and d > 0):
			i1 = i
			min_dist = d
	var i1x := coords[2 * i1]
	var i1y := coords[2 * i1 + 1]

	var min_radius := INF

	# Find the third point which forms the smallest circumcircle with the first two.
	for i in n:
		if i == i0 or i == i1: continue
		var r := circumradius(i0x, i0y, i1x, i1y, coords[2 * i], coords[2 * i + 1])
		if r < min_radius:
			i2 = i
			min_radius = r
	var i2x := coords[2 * i2]
	var i2y := coords[2 * i2 + 1]

	if min_radius == INF:
		# Order collinear points by dx (or dy if all x are identical)
		# and return the list as a hull.
		for i in n:
			var _dist_temp: float

			if coords[2 * i] - coords[0]:
				_dist_temp = coords[2 * i] - coords[0]
			elif coords[2 * i + 1] - coords[1]:
				_dist_temp = coords[2 * i + 1] - coords[1]
			else:
				_dist_temp = 0.0

			_dists[i] = _dist_temp

		quicksort(_ids, _dists, 0, n - 1)
		hull = []
		hull.resize(n)
		var j := 0
		var d0 := -INF

		for i in n:
			var id = _ids[i]
			if _dists[id] > d0:
				hull[j] = id
				j += 1
				d0 = _dists[id]
		hull = hull.slice(0, j - 1)
		triangles = []
		halfedges = []

		return

	# Swap the order of the seed points for counter-clockwise orientation.
	if orient(i0x, i0y, i1x, i1y, i2x, i2y):
		var i := i1
		var x := i1x
		var y := i1y
		i1 = i2
		i1x = i2x
		i1y = i2y
		i2 = i
		i2x = x
		i2y = y

	var center := circumcenter(i0x, i0y, i1x, i1y, i2x, i2y)
	_cx = center[0]
	_cy = center[1]

	for i in n:
		_dists[i] = dist(coords[2 * i], coords[2 * i + 1], center[0], center[1])

	# Sort the points by distance from the seed triangle circumcenter.
	quicksort(_ids, _dists, 0, n - 1)

	# Set up the seed triangle as the starting hull.
	_hull_start = i0
	var hull_size := 3

	_hull_next[i0] = i1
	_hull_prev[i2] = i1
	_hull_next[i1] = i2
	_hull_prev[i0] = i2
	_hull_next[i2] = i0
	_hull_prev[i1] = i0

	_hull_tri[i0] = 0
	_hull_tri[i1] = 1
	_hull_tri[i2] = 2

	for i in _hull_hash.size():
		_hull_hash[i] = -1
	_hull_hash[_hash_key(i0x, i0y)] = i0
	_hull_hash[_hash_key(i1x, i1y)] = i1
	_hull_hash[_hash_key(i2x, i2y)] = i2

#	triangles_len = 0
	_add_triangle(i0, i1, i2, -1, -1, -1)

	var xp := 0.0
	var yp := 0.0

	for k in _ids.size():
		var i: int = _ids[k]
		var x := coords[2 * i]
		var y := coords[2 * i + 1]

		# Skip near-duplicate points.
		if k > 0 and abs(x - xp) <= EPSILON and abs(y - yp) <= EPSILON: continue

		xp = x
		yp = y

		# Skip seed triangle points.
		if i == i0 or i == i1 or i == i2: continue

		# Find a visible edge on the convex hull using edge hash.
		var start := 0
		var key = _hash_key(x, y)

		for j in _hash_size:
			start = _hull_hash[fmod((key + j), _hash_size)]
			if (start != -1 and start != _hull_next[start]): break

		start = _hull_prev[start]
		var e := start

		while true:
			var q := _hull_next[e]
			if orient(x, y, coords[2 * e], coords[2 * e + 1], coords[2 * q], coords[2 * q + 1]): break
			e = q
			
			if (e == start):
				e = -1
				break

		if (e == -1): continue # Likely a near-duplicate point; Skip it.

		# Add the first triangle from the point.
		var t := _add_triangle(e, i, _hull_next[e], -1, -1, _hull_tri[e])
		# Recursively flip triangles from the point until they satisfy the Delaunay condition.
		_hull_tri[i] = _legalize(t + 2)
		_hull_tri[e] = t # Keep track of boundary triangles on the hull.
		hull_size += 1

		# Walk forward through the hull, adding more triangles and flipping recursively.
		n = _hull_next[e]

		while true:
			var q := _hull_next[n]
			if not orient(x, y, coords[2 * n], coords[2 * n + 1], coords[2 * q], coords[2 * q + 1]): break
			t = _add_triangle(n, i, q, _hull_tri[i], -1, _hull_tri[n])
			_hull_tri[i] = _legalize(t + 2)
			_hull_next[n] = n # Mark as removed.
			hull_size -= 1
			n = q

		# Walk backward from the other side, adding more triangles and flipping.
		if (e == start):
			while true:
				var q := _hull_prev[e]
				if not orient(x, y, coords[2 * q], coords[2 * q + 1], coords[2 * e], coords[2 * e + 1]): break
				t = _add_triangle(q, i, e, -1, _hull_tri[e], _hull_tri[q])
				_legalize(t + 2)
				_hull_tri[q] = t
				_hull_next[e] = e # Mark as removed.
				hull_size -= 1
				e = q

		# Update the hull indices.
		_hull_start = e
		_hull_prev[i] = e
		_hull_next[e] = i
		_hull_prev[n] = i
		_hull_next[i] = n

		# Save the two new edges in the hash table.
		_hull_hash[_hash_key(x, y)] = i
		_hull_hash[_hash_key(coords[2 * e], coords[2 * e + 1])] = e

	hull.resize(hull_size)
	var e := _hull_start
	for i in hull_size:
		hull[i] = e
		e = _hull_next[e]

	# Trim typed triangle mesh arrays.
	# Tom - fencepost error was triangles_len-1
	triangles = _triangles.slice(0, triangles_len)
	halfedges = _halfedges.slice(0, triangles_len)



func _hash_key(x: float, y: float) -> float:
	return fmod(floor(pseudo_angle(x - _cx, y - _cy) * _hash_size), _hash_size)


func _legalize(a: int) -> int:
	var i := 0
	var ar := 0

	# Recursion eliminated with a fixed-size stack.
	while true:
		var b: int = _halfedges[a]

#		If the pair of triangles doesn't satisfy the Delaunay condition
#		(p1 is inside the circumcircle of [p0, pl, pr]), flip them,
#		then do the same check/flip recursively for the new pair of triangles
#
#				   pl                    pl
#				  /||\                  /  \
#			   al/ || \bl            al/    \a
#				/  ||  \              /      \
#			   /  a||b  \    flip    /___ar___\
#			 p0\   ||   /p1   =>   p0\---bl---/p1
#				\  ||  /              \      /
#			   ar\ || /br             b\    /br
#				  \||/                  \  /
#				   pr                    pr

		var a0 := a - a % 3
		ar = a0 + (a + 2) % 3

		if b == -1: # Convex hull edge.
			if i == 0: break
			i -= 1
			a = edge_stack[i]
			continue

		var b0 := b - b % 3
		var al := a0 + (a + 1) % 3
		var bl := b0 + (b + 2) % 3

		var p0: int = _triangles[ar]
		var pr: int = _triangles[a]
		var pl: int = _triangles[al]
		var p1: int = _triangles[bl]

		var illegal := in_circle(
			coords[2 * p0], coords[2 * p0 + 1],
			coords[2 * pr], coords[2 * pr + 1],
			coords[2 * pl], coords[2 * pl + 1],
			coords[2 * p1], coords[2 * p1 + 1]
		)

		if illegal:
			_triangles[a] = p1
			_triangles[b] = p0

			var hbl: int = _halfedges[bl]

			# Edge swapped on the other side of the hull (rare); Fix the halfedge reference.
			if (hbl == -1):
				var e := _hull_start
				while true:
					if _hull_tri[e] == bl:
						_hull_tri[e] = a
						break

					e = _hull_prev[e]
					if e == _hull_start: break

			_link(a, hbl)
			_link(b, _halfedges[ar])
			_link(ar, bl)

			var br := b0 + (b + 1) % 3

			# Don't worry about hitting the cap: it can only happen on extremely degenerate input.
			if i < edge_stack.size():
				edge_stack[i] = br
				i += 1
		else:
			if i == 0: break
			i -= 1
			a = edge_stack[i]

	return ar


func _link(a: int, b: int) -> void:
	_halfedges[a] = b
	if (b != -1):
		_halfedges[b] = a
	pass


# Add a new triangle given vertex indices and adjacent half-edge ids.
func _add_triangle(i0: int, i1: int, i2: int, a: int, b: int, c: int) -> int:
	var t := triangles_len

	_triangles[t] = i0
	_triangles[t + 1] = i1
	_triangles[t + 2] = i2

	_link(t, a)
	_link(t + 1, b)
	_link(t + 2, c)

	triangles_len += 3

	return t


# Monotonically increases with real angle, but doesn't need expensive trigonometry.
func pseudo_angle(dx: float, dy: float) -> float:
	var p : float = dx / (abs(dx) + abs(dy))

	if (dy > 0):
		return (3.0 - p) / 4.0 # [0..1]
	else:
		return (1.0 + p) / 4.0 # [0..1]


func dist(ax: float, ay: float, bx: float, by: float) -> float:
	var dx := ax - bx
	var dy := ay - by
	return dx * dx + dy * dy


# Return 2d orientation sign if we're confident in it through J. Shewchuk's error bound check.
func orient_if_sure(px: float, py: float, rx: float, ry: float, qx: float, qy: float) -> float:
	var l := (ry - py) * (qx - px)
	var r := (rx - px) * (qy - py)

	if (abs(l - r) >= 0.00000000000000033306690738754716 * abs(l + r)):
		return l - r
	else:
		return 0.0


# A more robust orientation test that's stable in a given triangle (to fix robustness issues).
func orient(rx: float, ry: float, qx: float, qy: float, px: float, py: float) -> bool:
	var _sign := 0.0

	if orient_if_sure(px, py, rx, ry, qx, qy):
		_sign = orient_if_sure(px, py, rx, ry, qx, qy)
	elif orient_if_sure(rx, ry, qx, qy, px, py):
		_sign = orient_if_sure(rx, ry, qx, qy, px, py)
	elif orient_if_sure(qx, qy, px, py, rx, ry):
		_sign = orient_if_sure(qx, qy, px, py, rx, ry)

	return _sign < 0.0


func in_circle(ax: float, ay: float, bx: float, by: float, cx: float, cy: float, px: float, py: float) -> bool:
	var dx := ax - px
	var dy := ay - py
	var ex := bx - px
	var ey := by - py
	var fx := cx - px
	var fy := cy - py

	var ap := dx * dx + dy * dy
	var bp := ex * ex + ey * ey
	var cp := fx * fx + fy * fy

	return dx * (ey * cp - bp * fy) -\
		dy * (ex * cp - bp * fx) +\
		ap * (ex * fy - ey * fx) < 0.0


func circumradius(ax: float, ay: float, bx: float, by: float, cx: float, cy: float) -> float:
	var dx := bx - ax
	var dy := by - ay
	var ex := cx - ax
	var ey := cy - ay

	var bl := dx * dx + dy * dy
	var cl := ex * ex + ey * ey

	# When you divide by 0 in Godot you get an error.
	# It should return INF (positive or negative).
	var d: float
	if (dx * ey - dy * ex) == 0:
		d = INF
	elif (dx * ey - dy * ex) == -0:
		d = -INF
	else:
		d = 0.5 / (dx * ey - dy * ex)

	var x := (ey * bl - dy * cl) * d
	var y := (dx * cl - ex * bl) * d

	return x * x + y * y


func circumcenter(ax: float, ay: float, bx: float, by: float, cx: float, cy: float) -> Array:
	var dx := bx - ax
	var dy := by - ay
	var ex := cx - ax
	var ey := cy - ay

	var bl := dx * dx + dy * dy
	var cl := ex * ex + ey * ey

	# When you divide by 0 in Godot you get an error.
	# It should return INF (positive or negative).
	var d: float
	if (dx * ey - dy * ex) == 0:
		d = INF
	elif (dx * ey - dy * ex) == -0:
		d = -INF
	else:
		d = 0.5 / (dx * ey - dy * ex)

	var x := ax + (ey * bl - dy * cl) * d
	var y := ay + (dx * cl - ex * bl) * d

	return [x, y]


func quicksort(ids: Array, dists: Array, left: int, right: int) -> void:
	if right - left <= 20:
		for i in range(left + 1, right + 1):
			var temp: int = ids[i]
			var temp_dist: float = dists[temp]
			var j := i - 1
			while j >= left and dists[ids[j]] > temp_dist:
				ids[j + 1] = ids[j]
				j -= 1
			ids[j + 1] = temp
	else:
		var median := (left + right) >> 1
		var i := left + 1
		var j := right
		swap(ids, median, i)

		if (dists[ids[left]] > dists[ids[right]]):
			swap(ids, left, right)

		if (dists[ids[i]] > dists[ids[right]]):
			swap(ids, i, right)

		if (dists[ids[left]] > dists[ids[i]]):
			swap(ids, left, i)

		var temp: int = ids[i]
		var temp_dist: float = dists[temp]

		while true:
			while true:
				i += 1
				if dists[ids[i]] >= temp_dist: break

			while true:
				j -= 1
				if dists[ids[j]] <= temp_dist: break

			if j < i: break
			swap(ids, i, j)

		ids[left + 1] = ids[j]
		ids[j] = temp

		if right - i + 1 >= j - left:
			quicksort(ids, dists, i, right)
			quicksort(ids, dists, left, j - 1)
		else:
			quicksort(ids, dists, left, j - 1)
			quicksort(ids, dists, i, right)


func swap(arr: Array, i: int, j: int) -> void:
	var tmp: int = arr[i]
	arr[i] = arr[j]
	arr[j] = tmp
	
func get_half_edges() -> PackedInt32Array:
	return halfedges
	
func get_triangles() -> PackedInt32Array:
	return triangles
	

	
