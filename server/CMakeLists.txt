cmake_minimum_required (VERSION 3.5)
project (realtimebuses)
set (CMAKE_CXX_STANDARD 11)

set(CMAKE_CXX_FLAGS "-Wall -Wextra -g")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PROJECT_SOURCE_DIR}/Modules)

find_package (Protobuf REQUIRED)
include_directories (${PROTOBUF_INCLUDE_DIRS})

find_package (SQLite3 REQUIRED)
include_directories (${SQLITE3_INCLUDE_DIR})

# include_directories(${ProtobufIncludePath})
add_subdirectory (proto)

add_executable (main main.cpp ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries (main
    ${PROTOBUF_LIBRARIES}
    ${SQLITE3_LIBRARY}
    proto
)
