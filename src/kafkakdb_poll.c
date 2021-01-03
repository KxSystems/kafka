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
static J MAXIMUM_NUMBER_OF_POLLING = 0;

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
J poll_client(rd_kafka_t *handle, I timeout, J max_poll_cnt){
  if(rd_kafka_type(handle) == RD_KAFKA_PRODUCER){
    // Main poll for producer
    return rd_kafka_poll(handle, timeout);
  }
  else{
    // Polling for consumer
    // Counter of the number of polling
    J n= 0;
    // Holder of message from polling
    rd_kafka_message_t *message;
    // Holder of q message converted from message
    K q_message;

    while((message= rd_kafka_consumer_poll(handle, timeout))){
      // Poll and retrieve message while message is not empty
      q_message= decode_message(handle, message);
      // Call `.kfk.consume_topic_cb` passing client index and message information dictionary
      printr0(k(0, ".kfk.consume_topic_cb", ki(handle_to_index(handle)), q_message, KNULL));
      // Discard message which is not necessary any more
      rd_kafka_message_destroy(message);

      // Increment the poll counter
      ++n;

      // Argument `max_poll_cnt` has priority over MAXIMUM_NUMBER_OF_POLLING
      if ((n == max_poll_cnt) || (n == MAXIMUM_NUMBER_OF_POLLING && max_poll_cnt==0)){
        // The counter of polling reacched specified `max_poll_cnt` or globally set `MAX_MESSAGES_PER_POLL`.
        char data = 'Z';
        send(spair[1], &data, 1, 0);
        // Return the number of mesasges
        return n;
      }
    }
    // Return the number of mesasges
    return n;
  }
  
}

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
EXP K manual_poll(K client_idx, K timeout, K max_poll_cnt){
  
  if(!check_qtype("ijj", client_idx, timeout, max_poll_cnt)){
    // The argument types do not match (int; long; long)
    return krr("cient index, timeout and maximum poll count must be (int; long; long) type.");
  }
  
  rd_kafka_t *handle=index_to_handle(client_idx);
  if(!handle){
    // Null pointer from `krr`. Error happened in `index_to_handle`.
    // Return the error.
    return (K) handle;
  }
    
  // Poll producer or consumer
  J n=poll_client(handle, timeout->j, max_poll_cnt->j);
  // Return the number of messages (poll count)
  return kj(n);
}

/**
 * @brief Set a new number on `MAXIMUM_NUMBER_OF_POLLING`.
 * @param n: The maximum number of polling at execution of `poll_client()` or `manual_poll()`.
 */
EXP K set_maximum_number_of_polling(K n){
  if(!check_qtype("j", n)){
    // Return error for non-long type
    return krr("limit must be long type.");
  }
  // Set new upper limit
  MAXIMUM_NUMBER_OF_POLLING=n->j;
  // Return the new value
  return kj(MAXIMUM_NUMBER_OF_POLLING);
}
