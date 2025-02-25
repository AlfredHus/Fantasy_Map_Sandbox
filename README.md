# Overview
The Fantasy Map Sandbox is a work in progress (WIP) for me to learn Godot and GDscript. This is being done by creating Fantasy Maps using a variety of techniques. There is alot of usage of other Open Source projects which are listed in the Attributions section of the README.

Since it is a learning project, the code is messy, has alot of code I stopped using and haven't removed yet, code that may raise an eyebrow or tow and the whole thing in a constant state of change. I also have alot of inline comments to help me remember things I did and to explain to my future self why I did something.

# License
Any original code from me uses the MIT license: https://github.com/AlfredHus/Fantasy-Map_Sandbox/tree/main?tab=MIT-1-ov-file#readme

For any open source code that is used, their license is applicable.

# Learning Sites
Listed here are the sites that provided the learning opportunities. <br/>
## Red Blob Games
https://www.redblobgames.com - A whole lot of really good information on a variety of topics specific to maps, hexes, voronoi, etc with good external references.
## Azgaar Fantasy Map Generator Blog
https://azgaar.wordpress.com - Really good information on how Azgaar built his Fanasty Map Generator and various tecniques with good external references.

# Attribution
For source code used, either I used the project in its entirety, or I used parts of the code. In the code itself I document the exact file or snippet I used so you can take a look at the exact code rather than searching the original source code repository.
## Delaunator and Voronoi (License: MIT)
Deluanator: https://github.com/Volts-s/Delaunator-GDScript-4
   The Delaunator code along with the Voronoi support code and drawing code is used with some modifications.
   The code from Volt-s is a fork of hiulit's code at: https://github.com/hiulit/Delaunator-GDScript
   The original Delaunator code written in Javascript is here: https://github.com/mapbox/delaunator
   For additional documentation on the Voronoi code, you can take a look at the Delaunator guide:
   https://mapbox.github.io/delaunator/
## Poisson Disk Sampling (License MIT)
PossionDiskSampling: https://github.com/stephanbogner/godot-poisson-sampling
   The poisson disk sampling code and some of the demo code.
## TinyQueue (License: ISC)
tinyqueue code ported from : https://github.com/mourner/tinyqueue/tree/main
   Port of the code to gdscript. Used some of the test code as well.
## lineclip (License: ISC)
lineclip: Port of javascript: https://github.com/mapbox/lineclip
   Port of the code to gdscript. Used some of the test code as well
## Polylabel (License: ICS)
Polylabel: Code ported from: https://github.com/mapbox/polylabel
   Port of the code to gdscript. Used some of the test code as well
## Azgaar Fantasy Map Generator (License MIT)
Port of some of Azgaars Fantasy Map Code: https://github.com/Azgaar/Fantasy-Map-Generator
## RedBlobGames Mapgen4 (License: Apache-2.0)
Port of some of the Mapgen code: https://github.com/redblobgames/mapgen4/blob/master/dual-mesh/create.ts
## D3.Polygon  (License: ICS)
Port of some of the D3 Polygon code: https://d3js.org/d3-polygon, specifically area and centroid.
