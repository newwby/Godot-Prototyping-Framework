# Godot Prototyping Framework
![Logo](gpf_icon.png?raw=true "GPF Logo")

- **A lightweight modular series of tools to rapidly prototype games in the Godot game engine.**
- **Supports Godot 4.4.1**
- **[MIT License](https://github.com/newwby/godot_prototyping_framework/tree/main?tab=MIT-1-ov-file#readme)** 

---

- **Documentation at https://godotprototypingframework.readthedocs.io/en/latest/**

---

### Installation

- Download the current release and place the addon directory in your root project folder.
- Navigate to your project settings 'plugin' tab and enable the plugin. Relevant singletons will be added or removed with the plugin.
+ _It is not necessary to download the entire repository as it contains additional testing functionality not relevant to the addon. Only clone or download the repository if you seek to modify the plugin._

---

### Current Release

https://github.com/newwby/godot_prototyping_framework/releases/tag/1.1.0

### Current Features

- Godot plugin file for simple installation
- Logging singleton with log classification, permissions, and persistence
- Data singleton for loading and verifying JSON data by schema
- Utility statics for simple operation
  - Data utility for file reading operations
  - Node utility for object management
  - Sort utility for simple sorting behaviour

---

### Future Plans and Design

This plugin is a conversion of the now deprecated [Godot3 DDAT-GPF](https://github.com/newwby/ddat-gpf.core.godot3). Over time I plan to port more features (as soon as they can be converted and adequately tested) to this plugin, and also bring across some of the developer and experimental branch features that never made it into the previous version's release branch.

These tools began as simple additions to help my own workflow, but I hope they can serve to help someone else. The development methodology is to keep the plugin as lightweight as possible (extending future functionality as optional modules) whilst providing a broad and robust groundwork for any game project. Aligned with this philosophy, the plugin will exclusively feature universal tools like modules for configuration or audio implementations, rather than niche additions like a platformer character controller, which are only useful for a subset of games.
