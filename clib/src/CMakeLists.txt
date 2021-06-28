##%% Compilation %%##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

# Default option is Release
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release)
endif()

# OS Specific
if(APPLE)
    set(OSFLAG m)
elseif(WIN32)
    set(OSFLAG w)
else()
    set(OSFLAG l)
endif()

# Check 32bit or 64bit
set(BITNESS 32)
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
  set(BITNESS 64)
endif()

# Download k.h
file(DOWNLOAD "https://github.com/KxSystems/kdb/raw/master/c/c/k.h" "${PROJECT_SOURCE_DIR}/include/k.h" )

# Specify target shared library name
add_library(${MY_LIBRARY_NAME} SHARED
    kafkakdb_client.c
    kafkakdb_configuration.c
    kafkakdb_consumer.c
    kafkakdb_info.c
    kafkakdb_init.c
    kafkakdb_producer.c
    kafkakdb_topic.c
    kafkakdb_utility.c
    osthread.c
    socketpair.c
)

# Specify include directory
if("$ENV{KAFKA_INSTALL_DIR}" STREQUAL "")
    # Default location
    set(ENV{KAFKA_INSTALL_DIR} /usr/local/lib/librdkafka)
endif()
target_include_directories(${MY_LIBRARY_NAME} PRIVATE
    ${PROJECT_SOURCE_DIR}/include
    $ENV{KAFKA_INSTALL_DIR}/include/librdkafka
)

# Find dependency
option(ENABLE_SSL "Enable OpenSSL support" ON)
if(ENABLE_SSL)
    find_library(OPENSSL_LIBRARY
        REQUIRED
        NAMES ssl libssl
        HINTS $ENV{OPENSSL_ROOT_DIR}/lib
    )
endif()

find_library(KAFKA_LIBRARY
    REQUIRED
    NAMES librdkafka rdkafka
    HINTS $ENV{KAFKA_INSTALL_DIR}/lib
)

# Flag -DUSE_TRANSFORMER:BOOL=ON
if(USE_TRANSFORMER)
    message("Hey ${PROJECT_SOURCE_DIR}/transformer/src")
    find_library(TRANSFORMER_LIBRARY
        REQUIRED
        NAMES qtfm.so
        HINTS ${PROJECT_SOURCE_DIR}/transformer/src
    )
else()
    set(TRANSFORMER_LIBRARY "")
endif()

if(MSVC)
    # q library
    file(DOWNLOAD "https://github.com/KxSystems/kdb/raw/master/w64/q.lib" "${CMAKE_BINARY_DIR}/q.lib" )
    set(Q_LIBRARY "${CMAKE_BINARY_DIR}/q.lib")
endif()

# Compile option
target_compile_options(${MY_LIBRARY_NAME} PRIVATE
    # kdb+ version
    -DKXVER=3 -std=c99

    $<$<BOOL:${USE_TRANSFORMER}>: -DUSE_TRANSFORMER=1>

    # Compiler option
    $<$<C_COMPILER_ID:MSVC>:${CMAKE_C_FLAGS} /W3 /D WIN32_LEAN_AND_MEAN>
    $<$<NOT:$<C_COMPILER_ID:MSVC>>:${CMAKE_C_FLAGS} -fPIC -Wno-strict-aliasing>

    # Config option
    $<$<AND:$<CONFIG:Release>,$<NOT:$<C_COMPILER_ID:MSVC>>>:-O3 -DNDEBUG>
    $<$<AND:$<CONFIG:Debug>,$<NOT:$<C_COMPILER_ID:MSVC>>>:-O0 -g>
)

# Shared library prefix and suffix
# ex.) kafkakdb.so for linux
# Suffix must be `.so` for Mac
if(APPLE)
    set(CMAKE_SHARED_LIBRARY_SUFFIX ".so")
endif()

set_target_properties(${MY_LIBRARY_NAME} PROPERTIES SUFFIX ${CMAKE_SHARED_LIBRARY_SUFFIX})
set_target_properties(${MY_LIBRARY_NAME} PROPERTIES PREFIX "")

# Link flag
if(APPLE)
    set_target_properties(${MY_LIBRARY_NAME} PROPERTIES LINK_FLAGS "-undefined dynamic_lookup -mmacosx-version-min=10.12")
endif()

# Link library
target_link_libraries(${MY_LIBRARY_NAME} PRIVATE
    ${Q_LIBRARY}
    ${KAFKA_LIBRARY}
    ${OPENSSL_LIBRARY}
    ${TRANSFORMER_LIBRARY}
)

##%% Installation %%##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

# Copy built shared object after build instead of during installation
add_custom_command(TARGET ${MY_LIBRARY_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:${MY_LIBRARY_NAME}>" ${PROJECT_BINARY_DIR}/${CMAKE_PROJECT_NAME}/lib/${MY_LIBRARY_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}
    DEPENDS ${MY_LIBRARY_NAME}
)

# Install shared object at Release to QHOME and package directory
if("$ENV{DESTDIR}" STREQUAL "")
    install(TARGETS ${MY_LIBRARY_NAME} DESTINATION $ENV{QHOME}/${OSFLAG}${BITNESS}/ CONFIGURATIONS Release)
else()
    install(TARGETS ${MY_LIBRARY_NAME} DESTINATION ${DESTDIR}/ CONFIGURATIONS Release)
endif()
