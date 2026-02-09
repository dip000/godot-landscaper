# 😮‍💨 What Is Godot Landscaper?
Godot Landscaper is a plug-and-play editor add-on for several terrain, foliage, and instancer tools based on brush strokes, non-destructive effects, and runtime performance-centric.

Some key features that you may be insterested beforehand:
`Web exports, Chunkifyers, optimized meshes, MultiMeshInstance foliage, save-load, undo-redo, level of detail, and many, many more.`

Only available for Godot 4.6

---

# 📘 Quick Use Guide
## 1. Download And Install This Plugin
See how in Godot's [installing_plugins](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html) page. Coming soon for the assets store, but for now, [here's the repository](https://github.com/dip000/godot-landscaper)

## 2. Add A Controller To The Scene
A controller is an editor node that acts as a control panel for landscaping. **ControllerTerrain** for terrains, **ControllerGrass** for foliage, and **ControllerPackedScene** for custom PackedScenes.

![add_node_in_scene](https://github.com/user-attachments/assets/7d55cb84-84db-43d1-aee3-e1fb6d13bb87)

## 3. Select A Brush
Different controllers have different brushes. Try with **ControllerTerrain**, which has *Build*, *Height*, and *Paint* brushes.

![Controllers](https://github.com/user-attachments/assets/38dc442c-f26c-447c-bac0-3d2500fe7e1d)

## 4. Start Landscaping!
Drag the brush over a surface. **ControllerTerrain** with the *Build* brush can create a terrain mesh when brushing over it.

![building_stuff](https://github.com/user-attachments/assets/32dd080a-e94e-4b68-9783-b940317e4a47)

Note that every controller comes with templates. Just brush over something in the scene to see it for yourself

# The Effects System
This system allows you to automate the development-to-production process. For example, from building terrain to `Change colliders -> Round corners -> format texture -> Level Of Detail -> chunkify`. All of this and more with the press of a button.

You can also make programmatic ***quick fixes***, like repositioning the foliage if the terrain changed.

---

# ⭐Features Index ⭐
1. [**Base Features**](https://github.com/dip000/godot-landscaper/wiki/Base-Features). These features are shared among all landscaper controllers.
	- [x] Save / Load From Build Data
	- [x] Effects Stack
	- [x] Unlimited Instances And Per-Instance Customization
	- [x] Rendering Targets / Compatibility / WebGL / Forward / Mobile
	- [x] Surface Scanner For Mesh / Material / Textures / Colors
	- [ ] Undo / Redo

2. [**Terrain Controller**](https://github.com/dip000/godot-landscaper/wiki/Terrain-Controller). A hand-paintable vertex terrain builder with height mapping and brush coloring.
	- [x] Build Brush
	- [x] Height Brush
	- [x] Paint Brush
	- [x] Vertex Indexing
	- [x] Mesh LoD
	- [x] Effects

3. [**Grass Controller**](https://github.com/dip000/godot-landscaper/wiki/Grass-Controller). A hand-paintable color-baked grass instancer for textured and non-textured 3D MultiMeshes.
	- [x] Spawn Brush
 	- [x] Paint Brush
	- [x] Effects

4. [**PackedScene Controller**](https://github.com/dip000/godot-landscaper/wiki/Packed-Scene-Controller). A hand-paintable vertex terrain builder with height mapping and brush coloring.
	- [x] Instancer Brush
	- [x] Effects

---

# Author notes
Hi, nickname's DIP. Thanks for passing by!<br />

I'd be glad to hear what you have to say about this addon. Contact me at [ab-cb@hotmail.com](mailto:ab-cb@hotmail.com?subject=[GitHub]%20Godot%20Landscaper%20Plugin). See ya!

### Self Promotions Here
If you like my work, consider looking at my other works..
[Chroma Alchemy, by DIP](https://dip000.itch.io/chromalchemy)

### And Also Maybe Buying Me A Coffee?
<a href='https://ko-fi.com/O4O61JATV3' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
