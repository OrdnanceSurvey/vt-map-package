# Mapbox Vector Tiles Map Package Generation #

This repository serves to demonstrate the generation of offline mobile map packages with the [Mapbox GL native](https://github.com/mapbox/mapbox-gl-native/) SDK.

In summary, a series of actions are available from the Makefile (just type `make`):
* create - makes a new project based on a template docker environment
* build - executes a project's `build.sh` script, which must create a `www` directory
* start - serves the www directory, for preview or download
* download - initiates a project's `download.sh`, which should place files in the output directory.

This is sufficient to get results.

Improvements:
* Makefile could be replaced with a program, possibly with a [fancy dashboard](https://github.com/yaronn/blessed-contrib).
* Parallel execution could be used to package data (map and reduce behaviour)
* Maputnik integration could be included to allow the development of styles
  * or `mbgl-offline` functionality could be added to Maputnik

_immediate thoughts only!_
