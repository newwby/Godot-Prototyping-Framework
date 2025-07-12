Data.gd – JSON‑Driven Content Loader for Godot 4
===============================================

**Data.gd** is an autoload singleton that

* Recursively discovers and loads JSON files under ``res://<data_path>`` and
  ``user://<data_path>``.
* Validates each file against versioned schemas.
* Indexes the data for fast look‑ups by author, package, id, tag, type, or schema.
* Exposes a clean API for fetching data or applying it to in‑game objects.

:Target engine: Godot 4.1+
:License: MIT

Quick Start
-----------

.. code-block:: text

   1. In Project Settings → Plugins, set **data_path**
      (default value: ``data``).
   2. Put schemas in   ``res://<data_path>/_schema/``
   3. Put JSON content in ``res://<data_path>/…`` (any depth)

Example usage:

.. code-block:: gdscript

   # Get all entries tagged "forest"
   var forest_things: Array = Data.fetch_by_tag("forest")

   # Get specific unique entry by author, package, and id 
   var cure_all_ability: Dictionary = Data.fetch_by_id("spells_developer.magic_mod.cure_all")

   # Apply JSON data to an existing object
   var sword_data: Dictionary = Data.fetch_by_id("core.weapons.broadsword")
   Data.apply_json($Sword, sword_data)

Directory Layout
----------------

.. code-block:: none

   res://data/                 # data path & schema created on plugin install
   │
   ├─ _schema/                 # One .json per schema (each schema may hold many versions)
   │   └─ core.json
   │
   └─ items/
       └─ weapons/
           └─ broadsword.json

   user://data/…               # Same structure, created on first run

Key Concepts
------------

* **Schema** – A JSON file whose top‑level keys are semantic versions;
  each version maps required keys to *typed* default values.
* ``schema_register`` – All loaded schemas are stored here:
  ``schema_register[schema_id][version] → dict``.
* Several *data registers* keep objects accessible by id, author, package,
  tag, type, or schema.

Public API (cheat‑sheet)
------------------------

.. list-table::
   :header-rows: 1
   :widths: 35 15 50

   * - Method
     - Returns
     - Notes
   * - ``fetch_by_id(id)``
     - Dict
     - id format ``author.package.name``
   * - ``fetch_by_author(author)``
     - Array
     - –
   * - ``fetch_by_package(package)``
     - Array
     - –
   * - ``fetch_by_schema(schema_id)``
     - Array
     - –
   * - ``fetch_by_type(type)``
     - Array
     - –
   * - ``fetch_by_tag(tag)``
     - Array
     - –
   * - ``get_available_schema_versions(id)``
     - Array
     - Registered versions
   * - ``get_available_tags()``
     - Array
     - –
   * - ``get_available_types()``
     - Array
     - –
   * - ``reload_data()``
     - –
     - Clears and rescans disk
   * - ``apply_json(obj, json_dict)``
     - –
     - Copies validated ``data`` → ``obj``

Extending the System
--------------------

1. **Write a schema**

   .. code-block:: json

      { "1.0": { "hp": 0, "damage": 0, "sprite": "" } }

2. Save it as ``res://data/_schema/creature.json``.

3. **Author data**

   .. code-block:: json

      {
        "schema_id":    "creature",
        "schema_version": "1.0",
        "id_author":    "core",
        "id_package":   "monsters",
        "id_name":      "slime",
        "type":         "npc",
        "tags":         ["dungeon", "goo"],
        "data":         { "hp": 10, "damage": 2, "sprite": "slime.png" }
      }

4. **Fetch it**

   .. code-block:: gdscript

      var slime = Data.fetch_by_id("core.monsters.slime")

Credits
-------

Created by **DanDoesAThing** - https://github.com/newwby/

