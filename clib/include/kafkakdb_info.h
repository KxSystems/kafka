#ifndef __KAFKAKDB_INFO_H__
#define __KAFKAKDB_INFO_H__

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include "kafkakdb_utility.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Returns the number of threads currently being used by librdkafka.
 * @return The number of thread used by rdkafka.
 */
EXP K get_kafka_thread_count(K UNUSED(unused));

/**
 * @brief Get librdkafka version.
 * @return Version of librdkafka.
 */
EXP K version(K UNUSED(x));

/**
 * @brief Returns the human readable librdkafka version.
 * @return String version of librdkafka.
 */
EXP K version_string(K UNUSED(x));

/**
 * @brief Display error description for each error code.
 * @return Error description table of librdkafka.
 */
EXP K kafka_error_description_table(K UNUSED(unused));

// __KAFKAKDB_INFO_H__
#endif
