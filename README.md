Getting Started
======

Open up `Morphic.xcworkspace` to see all of the related macOS projects.

For debugging, you'll want to run the `Morphic` scheme in XCode.

Project Organization
==========

Morphic for macOS is a native macOS application,

[MorphicMenuBar](MorphicMenuBar):

* Runs as an icon the system menu bar without a Dock presence
* When the user clicks the icon, they see a MorphicBar
* An embedded application, [MorphicConfigurator](MorphicMenuBar/MorphicConfigurator)
  can open to handle first-run setup tasks or other tasks inappropriate for the MorphicBar


A collection of Frameworks support the application:

* [MorphicCore](MorphicCore) contains data models and other common
  foundational elements
* [MorphicService](MorphicService) contains the Swift API for talking
  with the [Morphic Server](../Server) HTTP API using models from
  [MorphicCore](MorphicCore)
* [MorphicSettings](MorphicSettings) contains code that reads and changes macOS settings
