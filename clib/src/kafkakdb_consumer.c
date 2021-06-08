//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <kafkakdb_utility.h>
#include <kafkakdb_client.h>

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Subscribe to a given topic with its partitions (and offsets).
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic to subscribe.
 */
EXP K subscribe(K consumer_idx, K topic){
  
  if(!check_qtype("is", consumer_idx, topic)){
    // Wrong argument types
    return krr((S) "consumer index and topic must be (int; symbol) type");
  }

  rd_kafka_t *handle=index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error in `index_to_handle()`.
    return (K) handle;
  }

  // Holder of current subscribed topic partitions
  rd_kafka_topic_partition_list_t *topic_partitions;
  // Get current subscribed topics and their partitions
  rd_kafka_resp_err_t error=rd_kafka_subscription(handle, &topic_partitions);
  if(error!=KFK_OK){
    // Fail to get subscription
    return krr((S)rd_kafka_err2str(error));
  }
  
  // Add topic partitions to existing list. Only topic makes an effect to subscribe.
  rd_kafka_topic_partition_list_add(topic_partitions, topic->s, 0);

  // Subscribe with new topics and partitions
  error= rd_kafka_subscribe(handle, topic_partitions);
  if(error!=KFK_OK){
    // Error in subscription
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Destroy current topic-partition list no longer necessary
  rd_kafka_topic_partition_list_destroy(topic_partitions);

  return KNULL;
}

/**
 * @brief Make a given consumer unsubscribe.
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 */
EXP K unsubscribe(K consumer_idx){
  
  if(!check_qtype("i", consumer_idx)){
    // Consumer index is not int
    krr((S) "consumer index must be int type.");
  }

  rd_kafka_t *handle=index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error in `index_to_handle()`.
    return (K) handle;
  }

  // Consumer unsubscribes
  rd_kafka_resp_err_t error= rd_kafka_unsubscribe(handle);
  if(error!=KFK_OK){
    // Error in unsubscribing
    return krr((S) rd_kafka_err2str(error));
  }
    
  return KNULL;
}


/**
 * @brief Get current subscription information for a consumer.
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @return A list of topic-partition information dictionary.
 */
EXP K get_current_subscription(K consumer_idx){

  if (!check_qtype("i", consumer_idx)){
    // Consumer index is not int
    krr((S) "consumer index must be int type.");
  }

  rd_kafka_t *handle=index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error in `index_to_handle()`.
    return (K) handle;
  }

  // Holder of topic-partition list.
  rd_kafka_topic_partition_list_t *topic_partitions;
  // Get current subscription of the consumer
  rd_kafka_resp_err_t error=rd_kafka_subscription(handle, &topic_partitions);
  if (error!=KFK_OK){
    // Error in getting current subscription.
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Convert topic-partition list to q object
  K q_topic_partitions = decode_topic_partition_list(topic_partitions);

  // Destroy topic-partition list no longer necessary
  rd_kafka_topic_partition_list_destroy(topic_partitions);

  return q_topic_partitions;
}

/**
 * @brief Get the broker-assigned group member ID of the client (consumer).
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @return 
 * - symbol: Broker-assigned group member ID.
 */
EXP K get_consumer_group_member_id(K consumer_idx){
  
  if(!check_qtype("i", consumer_idx)){
    // client_index is not int
    return krr("client index must be int type.");
  }

  rd_kafka_t *handle=index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error in `index_to_client()`.
    return (K) handle;
  }
  
  if(rd_kafka_type(handle) == RD_KAFKA_CONSUMER){
    // Return the consumer's broker-assigned group member ID.
    return ks(rd_kafka_memberid(handle));
  }
  else{
    // Producer is not supported. Return error.
    return krr("nyi - producer memberID is not feasible.");
  }
}

