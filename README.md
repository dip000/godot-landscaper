# TerraBrush [Godot 4] [Plugin] [Alpha]
Grass scatterer, grass colorer, terrain builder, terrain texturer, and terrain colorer. Based on textures and brushes
![preview](https://github.com/dip000/terra-brush-scatterer/assets/58742147/6c951028-6ebe-45d5-a335-1fc86502c220)


## Content
1. [Features And How To Use Them](#1-features-and-how-to-use-them)
	- [Terrain Builder](#11-terrain-builder)
	- [Terrain Color](#12-terrain-color)
	- [Terrain Height](#13-terrain-height)
	- [Grass Color](#14-grass-color)
	- [Grass Spawn](#15-grass-spawn)
3. [Performance Concerns](#performance-concerns)
4. [Roadmap To Beta And Asset Library](#roadmap-to-beta-and-asset-library)
5. [Author Notes](#author-notes)



# 1. Features And How To Use Them
Follow the next steps:
1. Download and install this Plugin. See [installing_plugins](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)
2. Open a scene, and instantiate a 'SceneLandscaper' node in the scene tree. It will create a new terrain template
3. Select the 'SceneLandscaper' node and go to the "Landscaper" tab over the right dock.
4. Select your brush and click and drag over your terrain to start terra-brushing!

## 1.1 Terrain Builder
Brush that generates new mesh when you paint over the terrain. Paints colors over the "_texture" depending if it is built or not.

## 1.2 Terrain Color
Select your color then left-click to paint your terrain or right-click to smooth it out!<br />

_Brush settings on TerraBrush inspector:_ <br />
<br />

_Coloring terrain:_ <br />
<br />


## 1.3 Terrain Height
Set the strength of the height brush then left-click to create mountains, and right-click to create valleys<br />
**Max height** is the relative height of the entire heightmap<br />

_Brush settings on TerraBrush inspector:_ <br />



_Heighting terrain:_ <br />




## 1.4 Grass Color
Select your color then left-click to paint your grass or right-click to smooth its color out!<br />
Do note that only the top of the grass is being colored. That's because the bottom half is taking the color of the terrain!<br />

_Brush settings on TerraBrush inspector:_ <br />


_Coloring grass:_ <br />



## 1.5 Grass Spawn
Select your color then left-click to spawn your grass or right-click to clear it!<br />
Do note that the bottom half of the grasses are taking the color of the terrain!<br />

_Brush settings on TerraBrush inspector:_ <br />
<br />

_Spawning grass:_ <br />
<br />

### Grass Color Properties
* **Density:** How many grass instances are inside the area you have painted with this brush
* **Billboard:** Tipes of billboarding. BillboardY (grass always looks at the camera), CrossBillboard (for each grass, spawns another 90 degrees in the same position), and Scatter (Scatters the grass with random rotations)
* **Enable Details:** Renders the details of your grass variant texture. These are the sharp margin edges in the preview grass shown here
* **Detail Color:** Recolor of your details
* **Quality:** Subdivisions for each blade of grass. This affects its sway animation and gradient color smoothness (because is vertex colored)
* **Size:** Size of the average blade of grass in meters
* **Gradient Value:** The color mix from the grass roots to the top as seen from the front. BLACK=terrain_color and WHITE=grass_color
* **Variants:** A list of the grass textures to show. Uses the preview images shown here. Does not create extra materials but is capped at 4


# Performance concerns
* This version now supports GL Compatibility rendering! But it is limited to one grass variant due to the lack of shader instance variables in Compatibility
* Coloring the grass is optimized by using vertex colors. This means that the shader is only coloring as less as 4 vertex per instance (The vertices of a square)
* You can actually set how many vertex to use per grass in: Grass Spawn Brush > Quality


# Roadmap to Beta and Asset Library
1. [X] Save and bake textures, shaders, and materials in the user folder
	- [X] Keep TerraBrush open for modifications
	- [X] Clear all plugin dependencies. Like in [this repository for shaders](https://github.com/dip000/my-godotshaders/tree/main/StylizedCartoonGrass)

2. [X] Add support for multiple grass billboarding options
	- [X] Cross billboard
	- [X] Billboard Y
 	- [X] Scatter
3. [X] Add Terrain generator brush
	- [X Click over the terrain and create a mesh surface
	- [X] Meshes are ImmediateMesh that are generated dynamically instead of using a shader
4. [ ] Asset Library friendly
   - [ ] [asset library requirements](https://docs.godotengine.org/en/stable/community/asset_library/submitting_to_assetlib.html)
   - [ ] In-code Documentation following [style guides](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html#doc-gdscript-styleguide)


# Author notes
Hi, thanks for passing by!<br />
I'd be glad to hear what you have to say about the grass shader [here](https://godotshaders.com/shader/stylized-cartoon-grass/). Or contact me about this plugin at [ab-cb@hotmail.com](mailto:ab-cb@hotmail.com?subject=[GitHub]%20TerraBrush%20Plugin)<br />
See ya!<br />
