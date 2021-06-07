#ifndef __KAFKAKDB_TOPIC_H__
#define __KAFKAKDB_TOPIC_H__

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <rdkafka.h>
#include "k.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Topic names expressed in symbol list
 */
K TOPICS;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Retrieve topic object by topic index
 * @param index: Index of topic
 * @return 
 * - symbol: Topic
 * - error if index is out of range or topic for the index is null
 */
rd_kafka_topic_t *index_to_topic_handle(K topic_idx);

// __KAFKAKDB_TOPIC_H__
#endif
