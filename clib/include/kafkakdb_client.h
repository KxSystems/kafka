#ifndef __KAFKAKDB_CLIENT_H__
#define __KAFKAKDB_CLIENT_H__

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <rdkafka.h>
#include "socketpair.h"
#include "k.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                        Macros                         //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#ifdef _WIN32
#define EXP __declspec(dllexport)
#else
#define EXP
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                    //
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#ifdef _WIN32
static SOCKET spair[2];
#else
#define SOCKET_ERROR -1
static I spair[2];
#endif

/**
 * @brief Thread pool for polling client.
 */
static K ALL_THREADS;

/**
 * @brief Client handles expressed in symbol list
 */
static K CLIENTS;

/**
 * @brief Pipeline name used by a client.
 */
static K CLIENT_PIPELINES;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Index Conversion %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Retrieve client handle from a given index.
 * @param client_idx: Index of client.
 * @return 
 * - symbol: client handle if index is valid
 * - null: error message if index is not valid
 */
rd_kafka_t *index_to_handle(K client_idx);

/**
 * @brief Retrieve index from a given client handle.
 * @param handle: Client handle.
 * @return 
 * - int: Index of the given client in `CLIENTS`.
 * - null int: if the client handle is not a registered one.
 */
I handle_to_index(const rd_kafka_t *handle);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Create/Delete %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Destroy client handle and remove from `CLIENTS`.
 * @param client_idx: Index of client in `CLIENTS`.
 */
EXP K delete_client(K client_idx);

// __KAFKAKDB_CIENT_H__
#endif
