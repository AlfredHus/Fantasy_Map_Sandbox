class_name Polygon
extends Node

	
# Port of d3.polygonArea
# https://github.com/d3/d3-polygon/blob/main/src/area.js
# https://d3js.org/d3-polygon
# License: ISC
# https://github.com/d3/d3-polygon?tab=ISC-1-ov-file#readme
# Returns the signed area of the specified polygon. If the vertices of the 
# polygon are in counterclockwise order (assuming a coordinate system where 
# the origin is in the top-left corner), the returned area is positive; 
# otherwise it is negative, or zero.
func polygon_area(polygon: Array) -> float:
	if polygon.is_empty():
		return 0.0
	var n: int = polygon.size()
	var a
	var b = polygon[n - 1]
	var area: float = 0.0

	for i in range(n):
		a = b
		b = polygon[i]
		area += a[1] * b[0] - a[0] * b[1]
		
	return area / 2.0

# Returns the centroid of the specified polygon.
# Port of D3 polygon.centroid
# https://github.com/d3/d3-polygon/blob/main/src/centroid.js
# https://d3js.org/d3-polygon
# https://en.wikipedia.org/wiki/Centroid
func polygon_centroid(polygon: Array) -> Array:
	var n: int = polygon.size()
	var x: float = 0.0
	var y: float = 0.0
	var a: Array
	var b: Array = polygon[n - 1]
	var c: float
	var k: float = 0.0

	for i in range(n):
		a = b
		b = polygon[i]
		c = a[0] * b[1] - b[0] * a[1]
		k += c
		x += (a[0] + b[0]) * c
		y += (a[1] + b[1]) * c

	k *= 3.0
	return [x / k, y / k]
