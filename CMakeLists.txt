##%% General Settings %%##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#

cmake_minimum_required(VERSION 3.1)
project(kafkakdb C)

# Set library name
set(MY_LIBRARY_NAME kafkakdb)

# Add src directry
add_subdirectory(src)

# Default option is Release
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release)
endif()

##%% Installation %%##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#

# Install script
if(WIN32)
	set(INSTALL_SCRIPT "install.bat")
else()
	set(INSTALL_SCRIPT "install.sh")
endif()

# Build package always
file(COPY README.md LICENSE ${INSTALL_SCRIPT} DESTINATION ${PROJECT_BINARY_DIR}/${CMAKE_PROJECT_NAME})
file(COPY examples/ DESTINATION ${PROJECT_BINARY_DIR}/${CMAKE_PROJECT_NAME}/examples/)
file(COPY q/ DESTINATION ${PROJECT_BINARY_DIR}/${CMAKE_PROJECT_NAME}/q/)

# Copy q files to QHOME
install(DIRECTORY q/ DESTINATION $ENV{QHOME}/ CONFIGURATIONS Release)