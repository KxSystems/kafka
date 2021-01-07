#ifndef __KAFKAKDB_CONSUMER_H__
#define __KAFKAKDB_CONSUMER_H__

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include "kafkakdb_utility.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Subscribe to a given topic with its partitions (and offsets).
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic to subscribe.
 * @param partition_to_offset: 
 * - list of int: Topic partitons
 * - dictionary: Map from topic partition to offsets (int -> long).
 */
EXP K subscribe(K consumer_idx, K topic, K partition_to_offset);

/**
 * @brief Make a given consumer unsubscribe.
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 */
EXP K unsubscribe(K consumer_idx);

/**
 * @brief Get current subscription information for a consumer.
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @return A list of topic-partition information dictionary.
 */
EXP K get_current_subscription(K consumer_idx);

/**
 * @brief Get the broker-assigned group member ID of the client (consumer).
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @return 
 * - symbol: Broker-assigned group member ID.
 */
EXP K get_consumer_group_member_id(K consumer_idx);

// __KAFKAKDB_CONSUMER_H__
#endif