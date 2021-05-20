#ifndef __KAFKAKDB_PRODUCER_H__
#define __KAFKAKDB_PRODUCER_H__

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include "kafkakdb_utility.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//


/**
 * @brief Flush a handle of a producer.
 * @param producer_idx: Index of a client (producer) in `CLIENTS`.
 * @param q_timeout: Timeout (milliseconds) for waiting for flush.
 */
EXP K flush_producer_handle(K producer_idx, K q_timeout);

// Support only if rdkafka version >= 0.11.4
#if (RD_KAFKA_VERSION >= 0x000b04ff)

/**
 * @brief Publish message with custom headers.
 * @param producer_idx: Index of client (producer) in `CLIENTS`.
 * @param topic_idx: Index of topic in `TOPICS`.
 * @param partition: Topic partition.
 * @param payload: Payload to be sent.
 * @param key: Message key.
 * @param headers: Message headers expressed in a map between header keys to header values (symbol -> string).
 *  If a key `encoder` is included, payload is encoded with a pipeline whose name is the value of the `encoder`.
 *  Likewise, if a key `decoder` is included, payload is decoded in q consumer with a pipeline whose name is the value of the `decoder`.
 */
EXP K publish_with_headers(K producer_idx, K topic_idx, K partition, K payload, K key, K headers);

// rdkafka version < 0.11.4
#else

EXP K publish_with_headers(K UNUSED(client_idx), K UNUSED(topic_idx), K UNUSED(partition), K UNUSED(value), K UNUSED(key), K UNUSED(headers));

#endif

/**
 * @brief Send a message with a specified topic to a specified partition.
 * @param topic_idx: Index of topic in `TOPICS`.
 * @param partition: Topic partition.
 * @param payload: Message to send.
 * @key: Message key. `""` for auto-generated key.
 */
EXP K publish(K topic_idx, K partition, K payload, K key);

// Ony support for rdkafka ver. >= 0.11.4
#if (RD_KAFKA_VERSION >= 0x000b04ff)

/**
 * @brief Send messages with a specified topic to single or multiple partitions.
 * @param topic_idx: Index of topic in `TOPICS`.
 * @param partitions: 
 * - int: Partition to use for all message
 * - list of ints: Partition per message 
 * @param payloads: List of messages.
 * @param keys: 
 * - `""`: Use auto-generated key for all messages
 * - list of string: Keys for each message
 * @return 
 * - list of symbol: Error for each published message.
 * @note
 * https://github.com/edenhill/librdkafka/blob/master/src/rdkafka.h (rd_kafka_resp_err_t)
 */
EXP K publish_batch(K topic_idx, K partitions, K payloads, K keys);

// rdkafka version < 0.11.4
#else

EXP K publish_batch(K UNUSED(topic_idx), K UNUSED(partitions), K UNUSED(payloads), K UNUSED(keys));

#endif

// __KAFKAKDB_PRODUCER_H__
#endif
