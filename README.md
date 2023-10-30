# TerraBrush [Godot 4] [Plugin] [Alpha]
Texture-based Multimesh scatterer and colorer using brushes.
![preview](https://github.com/dip000/terra-brush-scatterer/assets/58742147/6c951028-6ebe-45d5-a335-1fc86502c220)


## Content
1. [Features And How To Use Them](#1-features-and-how-to-use-them)
	- [Terrain Color](#11-terrain-color)
	- [Terrain Height](#12-terrain-height)
	- [Grass Color](#13-grass-color)
	- [Grass Spawn](#14-grass-spawn)
3. [Performance Concerns](#performance-concerns)
4. [Roadmap To Beta And Asset Library](#roadmap-to-beta-and-asset-library)
5. [Author Notes](#author-notes)


# 1. Features And How To Use Them
Follow the next steps:
1. Download and install this Plugin. See [installing_plugins](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)
2. Open a scene, and instantiate a TerraBrush node in the scene tree. It will create a new terrain
3. Select the TerraBrush node and activate the brush you want from the inspector
4. Hover over your terrain and click and drag to start terra-brushing!


## 1.1 Terrain Color
Select your color then left-click to paint your terrain or right-click to smooth it out!<br />

_Brush settings on TerraBrush inspector:_ <br />
![terrain_color](https://github.com/dip000/terra-brush-scatterer/assets/58742147/289fb511-5a60-4a24-962b-fa6d4ff2154e)<br />

_Coloring terrain:_ <br />
![terrain_color](https://github.com/dip000/terra-brush-scatterer/assets/58742147/74e76b8a-9005-459c-8ef8-89f966e0f02b)




## 1.2 Terrain Height
Set the strength of the height brush then left-click to create mountains, and right-click to create valleys<br />
**Max height** is the relative height of the entire heightmap<br />

_Brush settings on TerraBrush inspector:_ <br />
![terrain_height_brush](https://github.com/dip000/terra-brush-scatterer/assets/58742147/b74e7b96-cede-4343-9354-0914bf42262f)


_Heighting terrain:_ <br />
![terrain_height](https://github.com/dip000/terra-brush-scatterer/assets/58742147/aa45f08c-96e9-4a06-8fc0-53ce52da11a8)



## 1.3 Grass Color
Select your color then left-click to paint your grass or right-click to smooth its color out!<br />
Do note that only the top of the grass is being colored. That's because the bottom half is taking the color of the terrain!<br />

_Brush settings on TerraBrush inspector:_ <br />
![grass_color](https://github.com/dip000/terra-brush-scatterer/assets/58742147/10fb619f-a751-4d0d-b249-71433ffe1065)

_Coloring grass:_ <br />
![grass_color](https://github.com/dip000/terra-brush-scatterer/assets/58742147/60c77a62-44f5-4034-86a8-296c946663f8)




## 1.4 Grass Spawn
Select your color then left-click to spawn your grass or right-click to clear it!<br />
Do note that the bottom half of the grasses are taking the color of the terrain!<br />

_Brush settings on TerraBrush inspector:_ <br />
![grass_spawn_brush](https://github.com/dip000/terra-brush-scatterer/assets/58742147/c65b90ba-e708-469b-ac4d-e99c228ae6be)<br />

_Spawning grass:_ <br />
![grass_spawner](https://github.com/dip000/terra-brush-scatterer/assets/58742147/d0c71618-df0a-4e26-997a-f294d7a48084)<br />

### Grass properties
**Spawn Type:** Action to perform while left-clicking over the terrain. Spawn random grass variants or spawn a specific one while brushing<br />
**Variant:** The variant to spawn with Spawn Type set to "Spawn one specific variant". Variants are set in the "Variants" property under "Grass Settings"<br />
**Density:** How many grass instances are inside the area you have painted with this brush<br />

**Billboard Y:** Grass always looks at the camera<br />
**Cross Billboard:** Not implemented yet<br />
**Enable Details:** Renders the details of your grass variant texture. These are the sharp margin edges in the preview grass shown here<br />
**Detail Color:** Recolor of your details<br />
**Quality:** Subdivisions for each blade of grass. This affects its sway animation and gradient color smoothness (because is vertex colored)<br />
**Size:** Size of the average blade of grass in meters<br />
**Gradient Mask:** The color mix from the grass roots to the top as seen from the front. BLACK=terrain_color and WHITE=grass_color<br />
**Variants:** A list of the grass textures to show. Uses the preview images shown here. Does not create extra materials but is capped at 4<br />


# Performance concerns
* This version does not support GL Compatibility rendering driver. That's because the shader instance variables can render many variants with the same material
* Coloring the grass is optimized by using vertex colors. This means that the shader is only coloring as less as 4 vertex per instance (The vertices of a square)
* You can actually set how many vertex to use per grass in: Grass Spawn Brush > Quality
* You don't have to use the terrain shader in runtime. Just copy the baked images and use them in your own materials (this option will be default later in development)

# Roadmap to Beta and Asset Library
1. [ ] Asset Library friendly
   - [ ] [asset library requirements](https://docs.godotengine.org/en/stable/community/asset_library/submitting_to_assetlib.html)
   - [ ] In-code Documentation following [style guides](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html#doc-gdscript-styleguide)

2. [X] Save and bake textures, shaders, and materials in user folder
	- [X] Keep TerraBrush open for modifications
	- [X] Clear all plugin dependencies and close. Like in [this repository for shader showcases](https://github.com/dip000/my-godotshaders/tree/main/StylizedCartoonGrass)

3. [ ] Add support for cross-billboarding grass like in Minecraft
4. [ ] Add Terrain generator brush
	- [ ] Click over the terrain and create a mesh surface
	- [ ] Meshes are ImmediateMesh that are generated dynamically instead of using a shader

# Author notes
Hi, thanks for passing by!<br />
I'd be glad to hear what you have to say about the grass shader [here](https://godotshaders.com/shader/stylized-cartoon-grass/). Or contact me about this plugin at [ab-cb@hotmail.com](mailto:ab-cb@hotmail.com?subject=[GitHub]%20TerraBrush%20Plugin)<br />
See ya!<br />
