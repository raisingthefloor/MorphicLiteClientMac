Getting Started
======

Open up `Morphic.xcworkspace` to see all of the related macOS projects.

For debugging, you'll want to run the `MorphicMenuBar` scheme in XCode.

Project Organization
==========

The Morphic macOS client consists of a native mac application,
[MorphicMenuBar](MorphicMenuBar):

* Runs as an icon the system menu bar without a Dock presence
* When the user clicks the icon, they see a Quick Strip
* An embedded application, [MorphicConfigurator](MorphicMenuBar/MorphicConfigurator)
  can open to handle first-time-setup tasks or other taks inappropriate for the Quick Strip


A collection of Frameworks support the application:

* [MorphicCore](MorphicCore) contains data models and other common
  foundational elements
* [MorphicService](MorphicService) contains the Swift API for talking
  with the [Morphic Server](../Server) HTTP API using models from
  [MorphicCore](MorphicCore)
* [MorphicSettings](MorphicSettings) contains code that reads and changes macOS settings
