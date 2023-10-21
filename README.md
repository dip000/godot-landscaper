# TerraBrush [Godot 4 Plugin] [Alpha]
**NOT ACTUALLY BEEN TESTED. WAIT A FEW DAYS. SORRY!**
Texture-based multimesh scatterer and texturer using brushes.

How To:
1. Download and install this Plugin. See [installing_plugins](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)
2. Open a scene, instantiate a TerraBrush node in the scene tree, and select it
3. Activate the brush you want from the inspector
4. Hover over your terrain and left-click-and-drag to start terra-brushing!


# Terrain Color
Select your color then left-click to paint your terrain or right-click to smooth it out!<br />

_Brush settings on TerraBrush inspector:_ <br />
![terrain_color](https://github.com/dip000/terra-brush-scatterer/assets/58742147/289fb511-5a60-4a24-962b-fa6d4ff2154e)<br />

_Coloring terrain showcase:_ <br />
![terrain_color](https://github.com/dip000/terra-brush-scatterer/assets/58742147/74e76b8a-9005-459c-8ef8-89f966e0f02b)




# Terrain Height
Set the strength of the height brush then left-click to create mountains, and right-click to create valleys<br />

_Brush settings on TerraBrush inspector:_ <br />
![terrain_height](https://github.com/dip000/terra-brush-scatterer/assets/58742147/88baec80-da87-437d-afd5-eaacf31b6ce4)<br />

_Heighting terrain showcase:_ <br />
![terrain_height](https://github.com/dip000/terra-brush-scatterer/assets/58742147/aa45f08c-96e9-4a06-8fc0-53ce52da11a8)



# Grass Color
Select your color then left-click to paint your grass or right-click to smooth its color out!<br />
Do note that only the top of the grass is being colored. That's because the bottom half is taking the color of the terrain!<br />

_Brush settings on TerraBrush inspector:_ <br />
![grass_color](https://github.com/dip000/terra-brush-scatterer/assets/58742147/10fb619f-a751-4d0d-b249-71433ffe1065)

_Coloring grass showcase:_ <br />
![grass_color](https://github.com/dip000/terra-brush-scatterer/assets/58742147/60c77a62-44f5-4034-86a8-296c946663f8)




# Grass Spawn
Select your color then left-click to spawn your grass or right-click to clear it!<br />
Do note that the bottom half of the grasses are taking the color of the terrain!<br />

_Brush settings on TerraBrush inspector:_ <br />
![grass_spawner](https://github.com/dip000/terra-brush-scatterer/assets/58742147/afab1557-103c-44af-a1eb-62f23f2d62c6)<br />

_Spawning grass showcase:_ <br />
![grass_spawner](https://github.com/dip000/terra-brush-scatterer/assets/58742147/d0c71618-df0a-4e26-997a-f294d7a48084)<br />

## Grass properties
**Spawn Type:** Action to perform while left-clicking over the terrain. Spawn random variants or spawn a specific variant while brushing<br />
**Density:** How many grass instances per spawn area. No spawn area (not brushed) means no density at all<br />
**Variants:** A list of the grass graphics to show. Uses the showcase images shown here. Does not take much performance hit placing a few of these since the shader is using the same material over all instances and variants<br />
**Billboard Y:** Grass always looks at the camera (cross-billboarding not implemented yet)<br />
**Margin Enable:** Renders the edge of your grass variant graphics (This might take a performance hit since it is the only thing rendering on fragment) <br />
**Margin Color:** Color of your margin<br />

_Effect of margin property showcase:_ <br />
![margin](https://github.com/dip000/terra-brush-scatterer/assets/58742147/58ef8e07-0bd9-431e-9ef2-03f579fd2619)<br />

_Effect of density property showcase:_ <br />
![density](https://github.com/dip000/terra-brush-scatterer/assets/58742147/078c3622-1e4c-4996-8f27-fd66bf480198)


# Performance concerns
* This version does not support Compatibility renderer because of the use of shader instance variables (to increase performance)
* Coloring the grass is optimized by using vertex colors. This means that the shader is only coloring as less as 4 vertex per instance (The vertices of a square)
* You can actually set how many vertex to use per grass in the grass mesh resource. Of course, fewer subdivisions, worse color quality, and worse sway animation quality
* You don't have to use the terrain shader in runtime. Just copy the baked images and use them in your own materials

# Author notes
Hi, thanks for passing by!
I'm not quite sure if I missed any important detail that completely breaks this whole plugin so I'd be glad to hear what you have to say!
See ya!
