extends Node
class_name KoppenClassification

const koppen_color: Dictionary = {
	"Af": Color(0.043, 0.141, 0.980), # Tropical Rainforest
	"As": Color(0.298, 0.671, 0.969), # Tropical Savanna , Dry summer
	"Aw": Color(0.298, 0.671, 0.969), # Tropical Savanna , Dry winter`
	"Am": Color(0.082, 0.482, 0.984), # Tropical Monsoon
	"Cfa": Color(0.780, 0.992, 0.361), # Temperate,  No dry season, Hot summer
	"Csa": Color(1.0, 0.992, 0.220), # Temperate, Dry summer, Hot summer
	"Cwa": Color(0.600, 0.992, 0.604), # Temperate, Dry winter, Hot summer
	"Cfb": Color(0.427, 0.992, 0.275), # Temperate, No dry season, Warm summer	
	"Csb": Color(0.776, 0.773, 0.161), # Temperate, Dry summer, Warm summer
	"Cwb": Color(0.404, 0.773, 0.408), # Temperate, Dry winter, Warm summer
	"Cfc": Color(0.235, 0.773, 0.137), # Temperate, No dry season, Cold summer
	"Csc": Color(0.776, 0.773, 0.161), # Temperate, Dry summer, Cold summer
	"Cwc": Color(0.404, 0.773, 0.408), # Temperate, Dry winter, Cold summer	
	"Dfa": Color(0.176, 1.0, 0.996), # Continental, No dry season, Hot summer
	"Dsa": Color(0.988, 0.157, 0.984), # Continental, Dry summer, Hot summer
	"Dwa": Color(0.675, 0.702, 0.992), # Continental, Dry winter, Hot summer
	"Dfb": Color(0.259, 0.784, 0.988), # Continental, No dry season, Warm summer
	"Dsb": Color(0.769, 0.114, 0.773), # Continental, Dry summer, Warm summer
	"Dwb": Color(0.361, 0.478, 0.847), # Continental, Dry winter, Warm summer
	"Dfc": Color(0.063, 0.494, 0.486), # Continental, No dry season, Cold summer
	"Dwc": Color(0.302, 0.329, 0.698), # Continental, Dry summer, Cold summer
	"Dfd": Color(0.024, 0.271, 0.365), # Continental, No dry season, Very Cold winter
	"Dsd": Color(0.584, 0.396, 0.580), # Continental, Dry summer, Very Cold winter
	"Dwd": Color(0.196, 0.055, 0.522), # Continental, Dry winter, Very Cold winter
	"ET": Color(0.698, 0.698, 0.698), # Polar, Tundra
	"EF": Color(0.408, 0.408, 0.408), # Polar, Ice Cap
	"BSh": Color(0.953, 0.635, 0.153), # Dry, Semi-arid steppe, Hot
	"BSk": Color(0.996, 0.855, 0.424), # Dry, Semi-arid, Cold
	"BWh": Color(0.984, 0.051, 0.106), # Dry, Arid desert, Hot
	"BWk": Color(0.988, 0.592, 0.592) # Dry, Arid desert, Cold
}
