Welcome to the GPF Docs!
===================================

The **Godot Prototyping Framework** is a plugin for Godot 4.3.x that provides universal utilities to aid with rapid prototyping and game jams.

The aim of the framework is to provide modular tools to cover as many use cases as possible, without getting bogged down by genre-specific features such as platformer controllers. If it can't feasibly be used within any game, it probably shouldn't be a part of this framework.

you can use the ``lumache.get_random_ingredients()`` function:
you can use the ``global_log.critical()`` function:

Autodoc Test
----------------
should be below here

.. autofunction:: lumache.get_random_ingredients

.. autofunction:: lumache.get_random_ingredients
.. autofunction:: global_log.critical

   Creating recipes
----------------

To retrieve a list of random ingredients,
you can use the ``lumache.get_random_ingredients()`` function:

.. py:function:: lumache.get_random_ingredients(kind=None)

   Return a list of random ingredients as strings.

   :param kind: Optional "kind" of ingredients.
   :type kind: list[str] or None
   :return: The ingredients list.
   :rtype: list[str]

Contents
--------

.. toctree::
   :maxdepth: 2

   api
   global_log
   utilities
