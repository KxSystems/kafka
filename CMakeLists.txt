##%% General Settings %%##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#

cmake_minimum_required(VERSION 3.1)

# Set project name
# Declaration for installing files.
project(kafkakdb C)

# Add src directry
add_subdirectory(clib)

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
file(COPY README.md LICENSE ${INSTALL_SCRIPT} DESTINATION clib/${CMAKE_PROJECT_NAME})
file(COPY examples/ DESTINATION clib/${CMAKE_PROJECT_NAME}/examples/)
file(COPY q/ DESTINATION clib/${CMAKE_PROJECT_NAME}/q/)

# Copy q files to QHOME
install(DIRECTORY q/ DESTINATION $ENV{QHOME}/ CONFIGURATIONS Release)
