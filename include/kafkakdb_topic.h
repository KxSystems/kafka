#ifndef __KAFKAKDB_TOPIC_H__
#define __KAFKAKDB_TOPIC_H__

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include "kafkakdb_utility.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Set topic configuration in q dictionary on kafka topic configuration object.
 * @param tpc_conf: Destination kafka topic configuration object
 * @param q_tpc_config: Source q topic configuration dictionary (symbol -> symbol).
 * @return 
 * - error (nullptr): Failure
 * - empty list: Success
 */
static K load_topic_config(rd_kafka_topic_conf_t* tpc_conf, K q_tpc_config);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Create a new topic.
 * @param client_idx: index of client in `CLIENTS`.
 * @param topic: New topic to create.
 * @param q_config: q dictionary storing configuration of the new topic (symbol -> symbol).
 * @return 
 * - int: Topic handle assigned by kafka.
 */
EXP K new_topic(K client_idx, K topic, K q_config);

/**
 * @brief Delete the given topic from kafka broker.
 * @param topic_idx: Index of topic in `TOPICS`.
 */
EXP K delete_topic(K topic_idx);

/**
 * @brief Get a name of topic from topic index.
 * @param topic_idx: Index of topic in `TOPICS`.
 * @return 
 * - symbol: Topic name.
 */
EXP K get_topic_name(K topic_idx);

// __KAFKAKDB_TOPIC_H__
#endif
