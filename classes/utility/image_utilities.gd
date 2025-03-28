extends Node


func remap_noise_to_grayscale(value: float) -> float:
	# Clamp the input to the -1 to 1 range to avoid out-of-bound values
	value = clamp(value, -1.0, 1.0)
	# Remap the value from the range -1 to 1 to the range 0 to 255
	return lerp(0, 255, (value + 1) / 2.0)
	
	
func remap_grayscale_to_noise(value: float) -> float:
	# Clamp the input to the 0 to 255 range to avoid out-of-bound values
	value = clamp(value, 0, 255)
	# Remap the value from the range 0 to 255 to the range -1 to 1 by 
	# first converting the value to 0 to 1 (value / 255.0) and then converting
	# the 0 to 1 to the range -1 to 1
	return (value / 255.0) * 2.0 - 1.0
	
func load_grayscale_image(path: String) -> Array:
	# Load the image from the specified path
	var img = Image.new()
	if img.load(path) != OK:
		push_error("Failed to load image at: " + path)
		return []
	
	# Convert the image to grayscale if not already
	img.convert(Image.FORMAT_L8)  # FORMAT_L8 ensures it's a single-channel grayscale image
	
	# resize image
	img.resize(67,67)

	# Initialize an array to store the normalized values
	var normalized_values: Array[float]
	var row: Array[float]
	var count = 0
	# Loop through each pixel in the image
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			# Get the grayscale value (0-255) at the current pixel
			var grayscale_value = img.get_pixel(x, y).r * 255.0  # The red channel holds the grayscale value
			
			# Normalize the grayscale value to the range -1 to 1
			var normalized_value = (grayscale_value / 255.0) * 2.0 - 1.0
			count += 1
			# Store the normalized value
			row.append(normalized_value)
		#normalized_values.append(row)
	

	
	#return normalized_values  # Returns a 2D array of normalized values
	print ("Size of resized image = ", row.size(), "count = ", count)
	return row
