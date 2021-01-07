#ifndef __KAFKAKDB_CONFIGURATION_H__
#define __KAFKAKDB_CONFIGURATION_H__

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include "kafkakdb_utility.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Metadata %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Get broker's information from kafka broker object.
 * @param broker: A pointer pointing to kafka broker.
 * @return 
 * - dictionary: Dictionary containing broker information of ID, host and port.
 *   - id: symbol | Broker ID
 *   - host symbol | Broker host
 *   - port: int | Broker port
 */
K decode_metadata_broker(rd_kafka_metadata_broker_t* broker);

/**
 * @brief Get information of a given partition.
 * @param partition: A pointer to a kafka partition.
 * @return 
 * - dictionary: Dictionary containing partiotion information of ID, error code, leader, replicas and in-sync-replicas. 
 *   - id: int | Partition ID
 *   - err: symbol | Error message
 *   - leader: int | leader
 *   - replicas: list of int | Replicas
 *   - isrs: list of int | In-sync-replicas
 */
K decode_metadata_partition(rd_kafka_metadata_partition_t* partition);

/**
 * @brief Get information of a given topic.
 * @param topic: A topic.
 * @return 
 * - dictionary: Dictionary containing information of topic name, error and partitions.
 *   - topic: symbol | Topic name
 *   - err: symbol | Error message
 *   - partitions: list of dictionary | Information of partitions
 */
K decode_metadata_topic(rd_kafka_metadata_topic_t* topic);

/**
 * @brief Get information of broker and topic.
 * @param meta: A pointer to a kafka meta data.
 * @return 
 * - dictionary: Information of original broker, brokers and topics.
 *   - orig_broker_id: int | Broker originating this meta data
 *   - orig_broker_name | symbol | Name of originating broker
 *   - brokers: list of dictionary | Information of brokers
 *   - topics: list of dictionary | Infomation of topics
 */
K decode_metadata(const rd_kafka_metadata_t* meta);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/* 
 * The following set of functions define interactions with the assign functionality with Kafka.
 * This provides more control to the user over where data can be consumed from.
 * Note the differences between Kafka Assign vs Subscribe functionality, summarised in part
 * https://github.com/confluentinc/confluent-kafka-dotnet/issues/278#issuecomment-318858243
 */

/**
 * @brief Assign a new map from topic to partition for consumption of message to a client.
 *  Client will consume from the specified partition for the specified topic.
 * @param consumer_idx: Index of client in `CLIENTS`.
 * @param topic_to_partiton: Dictionary mapping from topic to partition.
 * @note
 * This function will replace existing mapping.
 */
EXP K assign_new_topic_partition(K consumer_idx, K topic_to_partiton);

/**
 * @brief Set new offsets on partitions of a given topic for a given client.
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic of partitions to which assign offsets.
 * @param new_part_to_offset: q dictionary (map) from partition to offsets (int -> long).
 * @note
 * https://github.com/edenhill/librdkafka/wiki/Manually-setting-the-consumer-start-offset
 */
EXP K assign_new_offsets_to_topic_partition(K consumer_idx, K topic, K new_part_to_offset);

/**
 * @brief Commit new offsets on partitions of a given topic for a given client.
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic of partitions to which assign offsets.
 * @param new_part_to_offset: q dictionary (map) from partition to offsets (int -> long).
 * @param is_async: True to process asynchronusly. If `is_async` is false this operation will
 *  block until the broker offset commit is done.
 */
EXP K commit_new_offsets_to_topic_partition(K consumer_idx, K topic, K new_part_to_offset, K is_async);

/**
 * @brief Get latest commited offset for a given topic and partitions for a client (consumer).
 * @param cousumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic of partitions to which assign offsets.
 * @param partitions: List of partitions.
 * @return 
 * - list of dictionary: List of dictionary of partition and offset
 */
EXP K get_committed_offsets_for_topic_partition(K consumer_idx, K topic, K partitions);

/**
 * @brief Query earliest offsets for given partitions whose timestamps are greater or equal to given offsets (milliseconds from epoch `1970.01.01`).
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic.
 * @param part_to_offset: Map from partition to offset to use as start time.
 * @param timeout: Timeout (milliseconds) for querying.
 * @return 
 * - list of dictionary: List of topic partition information incuding the found offsets.
 */
EXP K get_earliest_offsets_for_times(K consumer_idx, K topic, K part_to_offset, K q_timeout);

/**
 * @brief Reset offsets for given partitions to last message+1.
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic.
 * @param part_to_offset: Map from partition to offset. Offsets are dummy appended by q function `.kafka.setOffsetsToEnd`.
 * @return 
 * - list of dictionary: List of topic partition information incuding the reset offsets.
 */
EXP K set_offsets_to_end(K consumer_idx, K topic, K part_to_offset);

/** 
 * @brief Return the current consumption assignment for a specified client
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @return 
 * - list of dictionaries: List of information of topic-partitions.
 */
EXP K get_current_assignment(K consumer_idx);

/**
 * @brief Add pairs of topic and partition to the current assignment for a given lient.
 * @param consumer_idx: Index of cient (consumer) in `CLIENTS`.
 * @param topic_to_part: Dictionary mapping from topic to partition to add (symbol -> int).
 */
EXP K add_topic_partition(K consumer_idx, K topic_to_part);

/**
 * @brief Delete pairs of topic and partition from the current assignment for a client.
 * @param consumer_idx: Index of cient (consumer) in `CLIENTS`.
 * @param topic_to_part: Dictionary mapping from topic to partition to delete (s -> i).
 */
EXP K delete_topic_partition(K consumer_idx, K topic_to_part);

/**
 * @brief Get configuration of topic and broker for a given client index.
 * @param client_idx: Index of client in `CLIENTS`.
 * @return 
 * - dictionary: Informaition of originating broker, brokers and topics.
 *   - orig_broker_id: int | Broker originating this meta data
 *   - orig_broker_name | symbol | Name of originating broker
 *   - brokers: list of dictionary | Information of brokers
 *   - topics: list of dictionary | Infomation of topics
 */
EXP K get_broker_topic_config(K client_idx);

// __KAFKAKDB_CONFIGURATION_H__
#endif