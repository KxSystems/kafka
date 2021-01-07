//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include "kafkakdb_utility.h"
#include "kafkakdb_configuration.h"

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
K decode_metadata_broker(rd_kafka_metadata_broker_t *broker){
  return build_dictionary("id", ki(broker->id), "host", ks(broker->host), "port", ki(broker->port));
}

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
K decode_metadata_partition(rd_kafka_metadata_partition_t *partition){

  // Container of replicas
  K replicas= ktn(KI, partition->replica_cnt);
  for(J i= 0; i < replicas->n; ++i){
    // Contain replica ID
    kI(replicas)[i] = partition->replicas[i];
  }
    
  // Conatiner of in-sync-replicas
  K in_sync_replicas = ktn(KI, partition->isr_cnt);
  for(J i= 0; i < partition->isr_cnt; ++i){
    // Contain In-symc replica ID 
    kI(in_sync_replicas)[i]= partition->isrs[i];
  }
    
  return build_dictionary(
            "id", ki(partition->id),
            "err", ks((S) rd_kafka_err2str(partition->err)),
            "leader", ki(partition->leader),
            "replicas", replicas,
            "isrs", in_sync_replicas
         );
}

/**
 * @brief Get information of a given topic.
 * @param topic: A topic.
 * @return 
 * - dictionary: Dictionary containing information of topic name, error and partitions.
 *   - topic: symbol | Topic name
 *   - err: symbol | Error message
 *   - partitions: list of dictionary | Information of partitions
 */
K decode_metadata_topic(rd_kafka_metadata_topic_t *topic){
  // Container of topic information
  K partitions= ktn(0, 0);
  for(J i= 0; i < topic->partition_cnt; ++i){
    // Contain information of partitions
    jk(&partitions, decode_metadata_partition(&topic->partitions[i]));
  }
    
  return build_dictionary(
            "topic", ks(topic->topic), 
            "err", ks((S) rd_kafka_err2str(topic->err)),
            "partitions", partitions
         );
}

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
K decode_metadata(const rd_kafka_metadata_t *meta) {
  // Container of broker information
  K brokers= ktn(0, 0);
  for(J i= 0; i < meta->broker_cnt; ++i){
    //Contain information of brokers
    jk(&brokers, decode_metadata_broker(&meta->brokers[i]));
  }
    
  K topics= ktn(0, 0);
  for(J i= 0; i < meta->topic_cnt; ++i){
    // Contain information of topics
    jk(&topics, decode_metadata_topic(&meta->topics[i]));
  }

  return build_dictionary(
            "orig_broker_id", ki(meta->orig_broker_id),
            "orig_broker_name",ks(meta->orig_broker_name),
            "brokers", brokers,
            "topics", topics
         );
}

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
EXP K assign_new_topic_partition(K consumer_idx, K topic_to_partiton){
  
  if(!check_qtype("i", consumer_idx)){
    // consumer_idx is not int.
    return krr("consumer index must be int type.");
  }
  
  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  // Create a new topic-partition map.
  rd_kafka_topic_partition_list_t * new_topic_partitions = rd_kafka_topic_partition_list_new(topic_to_partiton->n);
  // Extend the new map with the given pairs of topics and partitions
  extend_topic_partition_list(topic_to_partiton, new_topic_partitions);

  // Assign the new topic-partiton map. 
  rd_kafka_resp_err_t error=rd_kafka_assign(handle, new_topic_partitions);
  if(error!=KFK_OK){
    // Error happened in assign. Return error.
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Destroy the allocated map no longer necessary
  rd_kafka_topic_partition_list_destroy(new_topic_partitions);

  return KNULL;
}

/**
 * @brief Set new offsets on partitions of a given topic for a given client.
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic of partitions to which assign offsets.
 * @param new_part_to_offset: q dictionary (map) from partition to offsets (int -> long).
 * @note
 * https://github.com/edenhill/librdkafka/wiki/Manually-setting-the-consumer-start-offset
 */
EXP K assign_new_offsets_to_topic_partition(K consumer_idx, K topic, K new_part_to_offset){
  
  if(!check_qtype("is!", consumer_idx, topic, new_part_to_offset)){
    // Argument types do not match required types
    return krr("consumer index, topic and new offset must be (int; symbol; dictionary) type.");
  }

  if(!check_qtype("IJ", kK(new_part_to_offset)[0], kK(new_part_to_offset)[1])){
    // Partitions are not int or offsets are not long
    return krr("partitions, offsets must be (int; long) type.");
  }

  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  // Create a new topic-partition list.
  rd_kafka_topic_partition_list_t *new_topic_partitions = rd_kafka_topic_partition_list_new(new_part_to_offset->n);
  
  // Extend the new topic-partitions with the pair of given topic and partitions for the topic and set offsets to specified partitions.
  extend_topic_partition_list_and_set_offset_for_topic(topic->s, new_part_to_offset, new_topic_partitions);
  
  // Assign the new topic-partitions to the concumer (client)
  rd_kafka_resp_err_t error = rd_kafka_assign(handle, new_topic_partitions);
  if(error!=KFK_OK){
    // Error happened in assign. Return error.
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Discard allocated topic-partition list which is no longer necessary
  rd_kafka_topic_partition_list_destroy(new_topic_partitions);

  return KNULL;
}

/**
 * @brief Commit new offsets on partitions of a given topic for a given client.
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic of partitions to which assign offsets.
 * @param new_part_to_offset: q dictionary (map) from partition to offsets (int -> long).
 * @param is_async: True to process asynchronusly. If `is_async` is false this operation will
 *  block until the broker offset commit is done.
 */
EXP K commit_new_offsets_to_topic_partition(K consumer_idx, K topic, K new_part_to_offset, K is_async){

  if(!check_qtype("is!b", consumer_idx, topic, new_part_to_offset, is_async)){
    // Argument types do not match required types
    return krr("consumer index, topic, new offset and is_async must be (int; symbol; dictionary; bool) type.");
  }
  
  if(!check_qtype("IJ", kK(new_part_to_offset)[0], kK(new_part_to_offset)[1])){
    // Partitions are not int or offsets are not long
    return krr("partitions, offsets must be (int; long) type.");
  }
  
  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  // Create a new topic-partition list.
  rd_kafka_topic_partition_list_t *new_topic_partitions =  rd_kafka_topic_partition_list_new(new_part_to_offset->n);
  
  // Extend the new topic-partitions with the pair of given topic and partitions for the topic and set offsets to specified partitions.
  extend_topic_partition_list_and_set_offset_for_topic(topic->s, new_part_to_offset, new_topic_partitions);
  
  // Commit the new topic-partitions
  rd_kafka_resp_err_t error=rd_kafka_commit(handle, new_topic_partitions, is_async->g);
  if(error!=KFK_OK){
    // Error happened in commit. Return error.
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Discard allocated topic-partition list which is no longer necessary
  rd_kafka_topic_partition_list_destroy(new_topic_partitions);

  return KNULL;
}

/**
 * @brief Get latest commited offset for a given topic and partitions for a client (consumer).
 * @param cousumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic of partitions to which assign offsets.
 * @param partitions: List of partitions.
 * @return 
 * - list of dictionary: List of dictionary of partition and offset
 */
EXP K get_committed_offsets_for_topic_partition(K consumer_idx, K topic, K partitions){
  
  if(!check_qtype("isJ", consumer_idx, topic, partitions)){
    // Argument types do not match required types
    return krr("consumer index, topic and new offset must be (int; symbol; list of long) type.");
  }
  
  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  // The number of partitions
  J n=partitions->n;
  // Create a new topic-partition list.
  rd_kafka_topic_partition_list_t *new_topic_partitions = rd_kafka_topic_partition_list_new(n);

  // Build holder of sffset in form of dictionary
  K topics=ktn(KS, n);
  for(J i=0; i < n; i++){
    kS(topics)[i]=ss(topic->s);
  }
  K topic_to_par=xD(topics, partitions);
  // Extend the new topic-partitions with the pair of given topic and partitions for the topic and set offsets to specified partitions.
  extend_topic_partition_list(topic_to_par, new_topic_partitions);
  // Discard K objects which are no longer necessary
  r0(topics);
  r0(topic_to_par);
  
  // Get committed offset and take them into `new_topic_partitions` with timeout in 5 seconds
  rd_kafka_resp_err_t error = rd_kafka_committed(handle, new_topic_partitions, 5000);
  if(error!=KFK_OK){
    // Error hapened in getting committed offsets. Return error.
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Convert to list of q dictionary
  K committed=decode_topic_partition_list(new_topic_partitions);

  // Discard allocated topic-partition list which is no longer necessary
  rd_kafka_topic_partition_list_destroy(new_topic_partitions);

  return committed;
}

/**
 * @brief Query earliest offsets for given partitions whose timestamps are greater or equal to given offsets (milliseconds from epoch `1970.01.01`).
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic.
 * @param part_to_offset: Map from partition to offset to use as start time.
 * @param timeout: Timeout (milliseconds) for querying.
 * @return 
 * - list of dictionary: List of topic partition information incuding the found offsets.
 */
EXP K get_earliest_offsets_for_times(K consumer_idx, K topic, K part_to_offset, K q_timeout){

  if(!check_qtype("is![hij]", consumer_idx, topic, part_to_offset, q_timeout)){
    // Wrong argument types
    return krr((S) "consumer index, topic, map from partition to offset, and timeout must be (int; symbol; dictionary; short|int|long) type.");
  }

  if(!check_qtype("I", kK(part_to_offset)[0])){
    // Map from partition to offset has wrong key-value types
    // Value is assured to be long by a manipulation on q side
    krr((S) "partition must be int type.");
  }

  rd_kafka_t *handle=index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer `krr`. Error in `index_to_handle()`.
    return (K) handle;
  }
 
  // Retrieve value of timeout (millis)
  int timeout;
  switch(q_timeout->t){
    case -KH:
      timeout=q_timeout->h;
      break;
    case -KI:
      timeout=q_timeout->i;
      break;
    default:
      timeout=q_timeout->j;
  }

  // Convert q dictionary of partition to offset to kafka topic partition list
  rd_kafka_topic_partition_list_t *topic_partitions=rd_kafka_topic_partition_list_new(part_to_offset->n);
  extend_topic_partition_list_and_set_offset_for_topic(topic->s, part_to_offset, topic_partitions);

  // Get earliest offsets for given partitions whose timestamps are greater or equal to a given offsets.
  rd_kafka_resp_err_t error=rd_kafka_offsets_for_times(handle, topic_partitions, timeout);
  if(error!=KFK_OK){
    // Error in querying offsets
    return krr((S) rd_kafka_err2str(error));
  }

  // Convert to q lis of dictionaries
  K result_partiton_offsets=decode_topic_partition_list(topic_partitions);

  // Destroy allocated partition list no longer necessary
  rd_kafka_topic_partition_list_destroy(topic_partitions);

  return result_partiton_offsets;
}

/**
 * @brief Reset offsets for given partitions to last message+1.
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic.
 * @param part_to_offset: Map from partition to offset. Offsets are dummy appended by q function `.kafka.setOffsetsToEnd`.
 * @return 
 * - list of dictionary: List of topic partition information incuding the reset offsets.
 */
EXP K set_offsets_to_end(K consumer_idx, K topic, K part_to_offset){
  
  if(!check_qtype("isI", consumer_idx, topic, kK(part_to_offset)[0])){
    // Wrong argument types
    return krr((S) "consumer index, topic and partitions must be (int; symbol; list of int) type.");
  }
  
  rd_kafka_t *handle=index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer `krr`. Error in `index_to_handle()`.
    return (K) handle;
  }

  // Convert q list of partitions to kafka topic partition list
  rd_kafka_topic_partition_list_t *topic_partitions=rd_kafka_topic_partition_list_new(part_to_offset->n);
  extend_topic_partition_list_and_set_offset_for_topic(topic->s, part_to_offset, topic_partitions); 

  // Reset offsets for given partitions to last message+1
  rd_kafka_resp_err_t error=rd_kafka_position(handle, topic_partitions);
  if(error!=KFK_OK){
    // Error in resetting offsets
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Convert into q list of dictionaries
  K result_topic_partitions=decode_topic_partition_list(topic_partitions);

  // Destroy allocated topic partitions no longer necessary
  rd_kafka_topic_partition_list_destroy(topic_partitions);

  return result_topic_partitions;
}

/** 
 * @brief Return the current consumption assignment for a specified client
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @return 
 * - list of dictionaries: List of information of topic-partitions.
 */
EXP K get_current_assignment(K consumer_idx){

  if(!check_qtype("i", consumer_idx)){
    // consumer_idx is not int.
    return krr("consumer index must be int type.");
  }

  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  // Holder of current topic-partitions
  rd_kafka_topic_partition_list_t *topic_partitions;
  // Get current assignment information into `topic_partitions`
  rd_kafka_resp_err_t error=rd_kafka_assignment(handle, &topic_partitions);
  if(error!=KFK_OK){
    // Error happened in getting information. Return error.
    return krr((S)rd_kafka_err2str(error));
  }
  // Convert into q dictionary
  K current_assignment = decode_topic_partition_list(topic_partitions);

  // Destroy the allocated map no longer necessary
  rd_kafka_topic_partition_list_destroy(topic_partitions);

  return current_assignment;
}

/**
 * @brief Add pairs of topic and partition to the current assignment for a given lient.
 * @param consumer_idx: Index of cient (consumer) in `CLIENTS`.
 * @param topic_to_part: Dictionary mapping from topic to partition to add (symbol -> int).
 */
EXP K add_topic_partition(K consumer_idx, K topic_to_part){

  if(!check_qtype("i!", consumer_idx, topic_to_part)){
    // consumer_idx is not int.
    return krr("consumer index and map from topic to partition must be (int; dictionary) type.");
  }

  if(!check_qtype("SI", kK(topic_to_part)[0], kK(topic_to_part)[1])){
    // Map from topic to partition has wrong types
    return krr((S) "map from topic to partition must have (symbol; int) type.");
  }

  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  // Holder of current topic-partitions
  rd_kafka_topic_partition_list_t *topic_partitions;
  // Get current assignment information into `topic_partitions`
  rd_kafka_resp_err_t error=rd_kafka_assignment(handle, &topic_partitions);
  if(KFK_OK !=error){
    // Error happened in getting information. Return error.
    return krr((S)rd_kafka_err2str(error));
  }

  // Add new pairs of topic and partition to current list
  extend_topic_partition_list(topic_to_part, topic_partitions);

  // Assign the new topic-partiton map. 
  error=rd_kafka_assign(handle, topic_partitions);
  if(error!=KFK_OK){
    // Error happened in assign. Return error.
    return krr((S) rd_kafka_err2str(error));
  }

  // Destroy the allocated map no longer necessary
  rd_kafka_topic_partition_list_destroy(topic_partitions);

  return KNULL;
}

/**
 * @brief Delete pairs of topic and partition from the current assignment for a client.
 * @param consumer_idx: Index of cient (consumer) in `CLIENTS`.
 * @param topic_to_part: Dictionary mapping from topic to partition to delete (s -> i).
 */
EXP K delete_topic_partition(K consumer_idx, K topic_to_part){

  if(!check_qtype("i!", consumer_idx, topic_to_part)){
    // consumer_idx is not int.
    return krr("consumer index and map from topic to partition must be (int; dictionary) type.");
  }

  if(!check_qtype("SI", kK(topic_to_part)[0], kK(topic_to_part)[1])){
    // Map from topic to partition has wrong types
    return krr((S) "map from topic to partition must have (symbol; int) type.");
  }

  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_handle`.
    return (K) handle;
  }

  // Holder of current topic-partitions
  rd_kafka_topic_partition_list_t *topic_partitions;
  // Get current assignment information into `topic_partitions`
  rd_kafka_resp_err_t error=rd_kafka_assignment(handle, &topic_partitions);
  if(KFK_OK !=error){
    // Error happened in getting information. Return error.
    return krr((S)rd_kafka_err2str(error));
  }

  // Delete given pairs of topic and partition from current list
  delete_elems_from_topic_partition_list(topic_to_part, topic_partitions);

  // Assign the new topic-partiton map. 
  error=rd_kafka_assign(handle, topic_partitions);
  if(error!=KFK_OK){
    // Error happened in assign. Return error.
    return krr((S) rd_kafka_err2str(error));
  }

  // Destroy the allocated map no longer necessary
  rd_kafka_topic_partition_list_destroy(topic_partitions);

  return KNULL;
}

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
EXP K get_broker_topic_config(K client_idx){
  
  if(!check_qtype("i", client_idx)){
    // index must be int
    return krr((S) "client index must be int type.");
  }
    
  rd_kafka_t *handle=index_to_handle(client_idx);
  if(!handle){
    // Null pointer `krr`. Error in `index_to_handle()`.
    return (K) handle;
  }

  // Holder of configuration
  const struct rd_kafka_metadata *meta;  
  rd_kafka_resp_err_t error= rd_kafka_metadata(handle, 1, NULL, &meta, 5000);
  if(error!=KFK_OK){
    // Error in getting metadata
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Store configuration
  K config= decode_metadata(meta);
  // Destroy metadata pointer no longer necessary
  rd_kafka_metadata_destroy(meta);
  return config;
}
