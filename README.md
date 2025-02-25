# Overview
The Fantasy Map Sandbox is a work in progress (WIP) for me to learn Godot and GDscript. This is being done by creating Fantasy Maps using a variety of techniques. There is alot of usage of other Open Source projects which are listed in the Attributions section of the README.

Since it is a learning project, the code is messy and in a constant state of change. I also have alot of inline comments to help me remember things to explaining to my future self why I did something.

# License
Any original code from me uses the MIT license. 
https://github.com/AlfredHus/Fantasy-Map_Sandbox/tree/main?tab=MIT-1-ov-file#readme

For any open source code that is used, their license is applicable.

# Learning Sites
Listed here are the sites that provided the learning opportunities.
1.Red Blob Games - https://www.redblobgames.com
A whole lot of really good infomration on a variety of topics specific to maps, hexes, voronoi, etc.

# Attribution
## Delaunator and Voronoi Code
1. Deluanator: https://github.com/Volts-s/Delaunator-GDScript-4
   The Delaunator code along with the Voronoi support code and drawing code is used with some modifications.
   The code from Volt-s is a fork of hiulit's code at: https://github.com/hiulit/Delaunator-GDScript
   The original Delaunator code written in Javascript is here: https://github.com/mapbox/delaunator
   For additional documentation on the Voronoi code, you can take a look at the Delaunator guide:
   https://mapbox.github.io/delaunator/
   
	2. PossionDiskSampling: https://github.com/stephanbogner/godot-poisson-sampling
		- using the poisson code and some of the demo code.
	3. Added documentation from the Deluanator site to the Demo code: https://mapbox.github.io/delaunator/
	4. Note. Volt-s added a delaulantor document page that is the same as the mapbox
	   version but shows gdscript instead of Javascript. 
	5. tinyqueue code ported from : https://github.com/mourner/tinyqueue/tree/main
		- also used some of the test code as well: https://github.com/mourner/tinyqueue/blob/main/test.js
	6. lineclip: Port of javascript
		- https://github.com/mapbox/lineclip
	7. Polylabel: Port of javascript
		- https://github.com/eqmiller/polylabel-csharp/blob/main/src/Polylabel-CSharp/Polylabel.cs
	8. Port of Azgaars Fantasy Map Code
		- https://github.com/Azgaar/Fantasy-Map-Generator
