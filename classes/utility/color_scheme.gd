extends Node2D
class_name ColorScheme

# Land is greater than 20 which is the default set by Azgaars code
# so for now we will just used that value.
func azgaar_map_colors(elevation_value: int) -> Color:
	# First color is a Dark Blue, then following colors are Blue
	# from darkest to lightest
	if elevation_value < 6: return Color (0.42,0.55,0.74) 
	if elevation_value < 8: return Color (0.47,0.64,0.79) # Blue
	if elevation_value < 10: return Color (0.54,0.69,0.83) # Blue
	if elevation_value < 20: return Color (0.6, .69, .83)  # Blue
	if elevation_value < 23: return Color (0.3686,0.8784,0.4549) # Green
	if elevation_value < 26: return Color (0.6353,0.9216,0.5098) # Green
	if elevation_value < 31: return Color (0.8745,0.9725,0.5725) # Green
	if elevation_value < 37: return Color (0.9647,0.8980,0.5843) # Yellow
	if elevation_value < 43: return Color (0.7843,0.6980,0.4627) # Yellow Brown
	if elevation_value < 50: return Color (0.6353,0.4941,0.3686) # Brown
	if elevation_value < 56: return Color (0.5608,0.3804,0.3294)
	if elevation_value < 62: return Color (0.6353,0.4902,0.4549)
	if elevation_value < 68: return Color (0.6980,0.5882,0.5451) # Brown
	if elevation_value < 75: return Color (0.7804,0.6902,0.6667) # Reddish brown
	if elevation_value < 81: return Color (0.8588,0.8039,0.7922) # Brown
	if elevation_value < 87: return Color (0.9255,0.8941,0.8863) # Light Grey
	if elevation_value < 93: return Color (1.0000,1.0000,1.0000)
	if elevation_value <= 100: return Color (1.0000,1.0000,1.0000)
	return Color.RED # we should not get here

# http://seaviewsensing.com/pub/cpt-city/wkp/shadowxfox/index.html
# License; https://creativecommons.org/licenses/by-sa/3.0/deed.en
# Wikipedia scheme for Columbia
func elevation_color_cpt_city_columbia(elevation_value: int) -> Color:
	if elevation_value == 0: return Color (0.0000,0.1176,0.3137)  # Blue
	if elevation_value < 11: return Color (0.0000,0.2000,0.4000)  # Blue
	if elevation_value < 22: return Color (0.0000,0.4000,0.6000)  # Blue
	if elevation_value < 33: return Color (0.0000,0.6000,0.8039)  # Blue
	if elevation_value < 38: return Color (0.3922,0.7843,1.0000)  # Blue
	if elevation_value < 42: return Color (0.7765,0.9255,1.0000)  # Blue
	if elevation_value < 44: return Color (0.5804,0.6706,0.5176)  # Green
	if elevation_value < 45: return Color (0.6745,0.7490,0.5451)
	if elevation_value < 46: return Color (0.7412,0.8000,0.5882)
	if elevation_value < 50: return Color (0.8941,0.8745,0.6863)
	if elevation_value < 55: return Color (0.9020,0.7922,0.5804)
	if elevation_value < 66: return Color (0.8039,0.6706,0.5137)
	if elevation_value < 77: return Color (0.8039,0.6706,0.5137)
	if elevation_value < 88: return Color (0.7098,0.5961,0.5020)
	if elevation_value <= 100: return Color (0.6078,0.4824,0.3843)
	return Color.RED # we should not get here
	

	
