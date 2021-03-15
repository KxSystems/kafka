//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file kafka_consumer.q
// @fileoverview
// Define kafka consumer interfaces.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Private Interface                  //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Consumer %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// @private
// @kind function
// @category Consumer
// @brief Subscribe to a given topic with its partitions (and offsets).
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @param topic {symbol}: Topic to subscribe.
// @param partition_to_offset {dynamic}: Topic partitons (and corresponding offsets).
// @type
// - list of int: List of partitions.
// - dictionary: Map from partition to offset 
// @note
// Replacement of `.kfk.Sub`.
.kafka.subscribe_impl:LIBPATH_ (`subscribe; 3);

// @private
// @kind function
// @category Consumer
// @brief Make a given consumer unsubscribe.
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @note
// Replacement of `.kfk.Unsub`.
.kafka.unsubscribe_impl:LIBPATH_ (`unsubscribe; 1);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Public Interface                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Configuration %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// @kind function
// @category Consumer
// @brief Get the broker-assigned group member ID of the client (consumer).
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @return
// - symbol: Broker-assigned group member ID of the consumer.
// @note
// Replacement of `.kfk.ClientMemberId`
.kafka.getConsumerGroupMemberID:LIBPATH_ 	(`get_consumer_group_member_id; 1);

// @kind function
// @category Consumer
// @brief Get current subscription information for a consumer.
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @return
// - list of dictionary: A list of topic-partition information dictionary.
// @note
// Replacement of `.kfk.Subscription`.
.kafka.getCurrentSubscription:LIBPATH_ (`get_current_subscription; 1);

//%% Consumer %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// @kind function
// @category Consumer
// @brief Subscribe to a given topic with its partitions (and offsets).
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @param topic {symbol}: Topic to subscribe.
// @param partition_to_offset {dynamic}: Topic partitons (and corresponding offsets).
// @type
// - list of int: List of partitions.
// - dictionary: Map from partition to offset 
// @note
// Replacement of `.kfk.Sub`.
.kafka.subscribe:{[consumer_idx;topic;partition_to_offset]
  // Add the topic to a client-topic map
  .kafka.CLIENT_TOPIC_MAP[consumer_idx],: topic;
  .kafka.subscribe_impl[consumer_idx;topic;partition_to_offset];
 }

// @kind function
// @category Consumer
// @brief Make a given consumer unsubscribe.
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @note
// Replacement of `.kfk.Unsub`.
.kafka.unsubscribe:{[consumer_idx]
  // Delete the consumer from client-topic map
  .kafka.CLIENT_TOPIC_MAP:consumer_idx _ .kafka.CLIENT_TOPIC_MAP;
  .kafka.unsubscribe_impl[consumer_idx];
 }
