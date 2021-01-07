#ifndef __KAFKAKDB_INIT_H__
#define __KAFKAKDB_INIT_H__

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <fcntl.h>
#include "kafkakdb_utility.h"
#include "kafkakdb_client.h"
#include "kafkakdb_topic.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Indicate if internal state is initial state. Used to protect from being re-intialized at corruption.
 */
static I CLEAN_STATE;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Trigger callback of client.
 * @param socket: Socket to read.
 */
K trigger_callback(I socket);

/**
 * @brief Clean up internal state of interface.
 */
static void detach(void);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Initialize internal state of interface.
 */
EXP K init(K UNUSED(unused));

// __KAFKAKDB_INIT_H__
#endif