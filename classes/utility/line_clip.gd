class_name LineClip
extends Node
# Port of MapBox lineclip.js
# https://github.com/mapbox/lineclip/blob/main/index.js
# License: ISC
# https://github.com/mapbox/lineclip/tree/main?tab=ISC-1-ov-file#readme
#
# A very fast JavaScript library for clipping polylines and polygons by a bounding box.
# - uses Cohen-Sutherland algorithm for line clipping
# - uses Sutherland-Hodgman algorithm for polygon clipping
#ds
# Has unit tests: res:\\test\unit\test_line_clip.gd
#


func _init():
	pass

# Cohen-Sutherland based polyline clipping.
# https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
# Params
# points - aqn array of [x, y] points
# bbox - a bounding box as [xmin, ymin, xmax, ymax]
# result - an array to append the results to
# Returns an array of clipped lines
# Clips a line from P0 = (x0, y0) to P1 - (x1, y1) against a rectangle (bbox)
# with diagonal from *xmin, ymin) to (xmax, ymax)
func line_clip(points: Array, bbox: Array, result: Array= []) -> Array:
	var len_points = points.size()
	var codeA = bit_code(points[0], bbox)
	var part = []
	
	#if result == null:
		#result = []
	
	# compute outcodes for P0, p1 and whatever point lines outside the clip
	# rectangle
	for i in range(1, len_points):
		var a = points[i - 1]
		var b = points[i]
		var codeB = bit_code(b, bbox)
		var lastCode = codeB
		
		while true:
			# bitwise OR is 0: both points inside window, trivially accept
			# and exit loop
			if (!(codeA | codeB)): # Accept
				part.append(a)
				
				if codeB != lastCode: # Segment went outside
					part.append(b)
			
					if i < len_points - 1: # start a new line
						result.append(part)
						part = []
				
				elif i == len_points - 1:
					part.append(b)
				break
			# bitwise AND is not 0: both points share an outside zone (left, 
			# right, top or bottom), so both must be outside window. Accept is 
			# false. Exit loop
			elif (codeA & codeB): # Trivial reject
				break
			# Now find the intersection point.
			elif codeA != 0: # a outside, intersect with clip edge
				a = intersect(a, b, codeA, bbox)
				codeA = bit_code(a, bbox)
				pass

			else: # b outside
				b = intersect(a, b, codeB, bbox)
				codeB = bit_code(b, bbox)
		# Prepare for the next segment.
		codeA = lastCode
	
	if part.size() > 0:
		result.append(part)
	return result

# Sutherland-Hodgeman polygon clipping.
# https://en.wikipedia.org/wiki/Sutherland%E2%80%93Hodgman_algorithm
# Params
# points - aqn array of [x, y] points
# bbox - a bounding box as [xmin, ymin, xmax, ymax]
# Returns a clipped polygon
func polygon_clip(points: Array, bbox: Array) -> Array:
	
	points = Array(points)
	# clip against each side of the clip rectangle
	for edge in [1, 2, 4, 8]:
		var result = []
		var prev = points[points.size() - 1]

		print ("Type of", typeof(prev))
		var prev_inside = !(bit_code(prev, bbox) & edge)
		
		for p in points:
			var inside = !(bit_code(p, bbox) & edge)
			
			# If segment goes through the clip window, add an intersection
			if inside != prev_inside:
				result.append(intersect(prev, p, edge, bbox))
			
			# Add a point if it's inside	
			if inside:
				result.append(p)
				
			prev = p
			prev_inside = inside
			
		points = result
		
		if points.is_empty():
			break
			
	return points
	
# Bit code reflects the point position relative to the bbox:
# Used by the Cohen-Sutherland based polyline clipping.
#     	 left  mid  right
#  top	 1001  1000 1010
#  mid 	 0001  0000 0010
# bottom 0101  0100 0110
# Compute the bit code for a point (x, y) using the clip rectangle, i.e., 
# the bounding box (bbox) bounded diagonally by (xmin, ymin) and *xmax, ymax)
func bit_code(p: Array, bbox: Array) -> int:
	var code = 0
	if p[0] < bbox[0]: 
		code |= 1  #  to the left of the clip window (0b0001)
	elif p[0] > bbox[2]:
		code |= 2  # to the right of the clip window (0b0010)
		
	if p[1] < bbox[1]:
		code |= 4  # bottom, below the clip window (0b0100)
	elif p[1] > bbox[3]:
		code |= 8  # top, above the clip window (0b1000)
	
	return code	
		

# Intersect a segment against one of the 4 lines that make up the bbox by edge.
# Used by the Sutherland-Hodgeman polygon clipping.
func intersect(a: Array, b: Array, edge: int, bbox: Array) -> Array:
	if edge & 8:
		# top edge: y = bbox[3]
		return [a[0] + (b[0] - a[0]) * (bbox[3] - a[1]) / (b[1] - a[1]), bbox[3]]
	elif edge & 4:
		# bottom edge: y = bbox[1]
		return [a[0] + (b[0] - a[0]) * (bbox[1] - a[1]) / (b[1] - a[1]), bbox[1]]
	elif edge & 2:
		# right edge: x = bbox[2]
		return [bbox[2], a[1] + (b[1] - a[1]) * (bbox[2] - a[0]) / (b[0] - a[0])]
	elif edge & 1:
		# left edge: x = bbox[0]
		return [bbox[0], a[1] + (b[1] - a[1]) * (bbox[0] - a[0]) / (b[0] - a[0])]
	
	return [] # Should not get here
