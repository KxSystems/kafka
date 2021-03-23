##%% General Settings %%##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#

cmake_minimum_required(VERSION 3.1)

# Set project name
# Don't move this declaration. `PROJECT_SOURCE_DIR` must be this directorty.
project(kafkakdb C)

# Set library name
set(MY_LIBRARY_NAME kafkakdb)

# Add src directry
add_subdirectory(src)

# Default option is Release
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release)
endif()
