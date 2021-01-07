#ifndef __KAFKAKDB_POLL_H__
#define __KAFKAKDB_POLL_H__

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include "kafkakdb_utility.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Interface %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Maximum number of polling at execution of `poll_client`. Set `0` by default.
 * @note
 * In order to make this parameter effective, pass `0` for `max_poll_cnt` in `poll_client`.
 */
static J MAXIMUM_NUMBER_OF_POLLING;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Poll %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Poll producer or consumer with timeout (and a limitation of the number of polling for consumer).
 * @param handle: Client handle.
 * @param timeout: The maximum amount of time (in milliseconds) that the call will block waiting for events.
 * - 0: non-blocking
 * - -1: wait indefinitely
 * - others: wait for this period
 * @param max_poll_cnt: The maximum number of polls, in turn the number of messages to get.
 * @return 
 * - int: The number of messages retrieved (poll count).
 */
J poll_client(rd_kafka_t* handle, I timeout, J max_poll_cnt);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Poll %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Poll client manually.
 * @param client_idx: Client index in `CLIENTS`.
 * @param timeout: The maximum amount of time (in milliseconds) that the call will block waiting for events.
 * - 0: non-blocking
 * - -1: wait indefinitely
 * - others: wait for this period
 * @param max_poll_cnt: The maximum number of polls, in turn the number of messages to get.
 * @return 
 * - long: The number of messages retrieved (poll count).
 */
EXP K manual_poll(K client_idx, K timeout, K max_poll_cnt);

/**
 * @brief Set a new number on `MAXIMUM_NUMBER_OF_POLLING`.
 * @param n: The maximum number of polling at execution of `poll_client()` or `manual_poll()`.
 */
EXP K set_maximum_number_of_polling(K n);

// __KAFKAKDB_POLL_H__
#endif
