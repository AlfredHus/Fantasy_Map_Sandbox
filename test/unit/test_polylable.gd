extends GutTest

var polygon_label: PolyLabel

# Test for a position in a sqaure
func test_position_square_polygon():
	var polygon = [[
		Vector2(0, 0),
		Vector2(0, 10),
		Vector2(10, 10),
		Vector2(10, 0),
		Vector2(0, 0)
	]]
	
	polygon_label = PolyLabel.new()
	var expected_result = [5, 5]  # Center of the square
	var result = polygon_label.get_polylabel(polygon)
	
	assert_eq(Vector2(result[0], result[1]), Vector2(expected_result[0], expected_result[1]), "The center of the square polygon should be [5, 5].")

# Test a L Shape
func test_L_shape_polygon():
	var polygon = [[
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 5),
		Vector2(5, 5),
		Vector2(5, 10),
		Vector2(0, 10),
		Vector2(0, 0)
	]]
	
	polygon_label = PolyLabel.new()
	var expected_result = [3.125, 3.125]  # Center of the square
	var result = polygon_label.get_polylabel(polygon)
	
	assert_eq(Vector2(result[0], result[1]), Vector2(expected_result[0], expected_result[1]), "The center of the square polygon should be [5, 5].")



# Test a sqaure
func test_square_polygon():
	var polygon = [[
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(1, 1),
		Vector2(0, 1)
	]]
	
	polygon_label = PolyLabel.new()
	var expected_result = [.5, .5]  # Center of the square
	var result = polygon_label.get_polylabel(polygon)
	assert_eq(Vector2(result[0], result[1]), Vector2(expected_result[0], expected_result[1]), "The center of the square polygon should be [5, 5].")
	
# Test for position in a triangle
func test_triangle_polygon():
	var polygon = [[
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(5, 10),
		Vector2(0, 0)
	]]
	polygon_label = PolyLabel.new()
	var result = polygon_label.get_polylabel(polygon)
	assert_true(result[0] > 0 and result[0] < 10, "X-coordinate of the label point should be within the triangle.")
	assert_true(result[1] > 0 and result[1] < 10, "Y-coordinate of the label point should be within the triangle.")

func test_voronoi_cell_int():
	var polygon = [[
	Vector2(515.8488, 310.5326),
	Vector2(714.7361, 354.1483),
	Vector2(720.3284, 398.0641),
	Vector2(687.569, 434.8077),
	Vector2(595.0575, 513.5287),
	Vector2(460.5673, 586.2435),
	Vector2(410.3178, 470.3085)	
	]]
	var expected_result = [559.48, 418.77]

	polygon_label = PolyLabel.new()
	var result = polygon_label.get_polylabel(polygon)
	# remove excess decimal points to make it easire to test
	var first_value = snapped(result[0], .01)
	var second_value = snapped(result[1], .01)
	assert_eq(Vector2(first_value, second_value), Vector2(expected_result[0], expected_result[1]), "Result does not match.")
	print ("Distance = ", polygon_label.distance)

# Test single point polygon (degenerate case)
func test_rectangle_special():
	var polygon = [[
	Vector2(32.71997, -117.19310),
	Vector2(32.71997, -117.19310),
	Vector2(32.71997, -117.19310),
	Vector2(32.71997, -117.19310)
	]]
	var expected_result = [32.71997, -117.1931]
	
	polygon_label = PolyLabel.new()
	var result = polygon_label.get_polylabel(polygon)
	var first_value = snapped(result[0], .00001)
	var second_value = snapped(result[1], .00001)
	assert_eq(Vector2(first_value, second_value), Vector2(expected_result[0], expected_result[1]), "Result does not match.")
	
# Test precision
func test_high_precision():
	var polygon = [[
		Vector2(0, 0),
		Vector2(0, 10),
		Vector2(10, 10),
		Vector2(10, 0),
		Vector2(0, 0)
	]]
	polygon_label = PolyLabel.new()
	var precision = 0.1
	var result = polygon_label.get_polylabel(polygon, precision)
	var expected_result = [5, 5]
	
	assert_eq(Vector2(result[0], result[1]), Vector2(expected_result[0], expected_result[1]), "Result should match the center of the square with high precision.")

func test_small_polygon():
	var polygon = [[
		Vector2(0, 0),
		Vector2(0, 1),
		Vector2(1, 1),
		Vector2(1, 0),
		Vector2(0, 0)
	]]
	polygon_label = PolyLabel.new()
	var result = polygon_label.get_polylabel(polygon)
	assert_eq(Vector2(result[0], result[1]), Vector2(0.5, 0.5), "The center of the small polygon should be [0.5, 0.5].")

# Test against degenerate polygons
func test_degenerate_polygon():
	var polygon = [[
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(20, 0),
		Vector2(0, 0)
	]]
	polygon_label = PolyLabel.new()
	var result = polygon_label.get_polylabel(polygon)
	assert_eq(Vector2(result[0], result[1]), Vector2(0.0, 0.0), "The result from a degenerate polygon should be [0.0, 0.0].")
	
	var polygon_1 = [[
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(1, 1),
		Vector2(1, 0),
		Vector2(0, 0)
	]]
	assert_eq(Vector2(result[0], result[1]), Vector2(0.0, 0.0), "Second pass. The result from a degenerate polygon should be [0.0, 0.0].")

# Test: Large complex polygon
func test_get_polylabel_large_polygon():
	var polygon = [
		[
			Vector2(0, 0), Vector2(20, 0), Vector2(20, 5), Vector2(10, 5), Vector2(10, 15),
			Vector2(20, 15), Vector2(20, 20), Vector2(0, 20), Vector2(0, 15), Vector2(5, 15),
			Vector2(5, 5), Vector2(0, 5), Vector2(0, 0)
		]  # Large polygon with a hole
	]

	var polylabel = PolyLabel.new()
	var result = polylabel.get_polylabel(polygon)


	assert_eq(Vector2(result[0], result[1]), Vector2(8.125, 3.125), "Values should be 8.125 and 3.125")
