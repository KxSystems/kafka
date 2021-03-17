//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file kafka_consumer.q
// @fileoverview
// Define kafka consumer interfaces.

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
// @note
// Replacement of `.kfk.Sub`.
.kafka.subscribe:LIBPATH_ (`subscribe; 2);

// @kind function
// @category Consumer
// @brief Make a given consumer unsubscribe.
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @note
// Replacement of `.kfk.Unsub`.
.kafka.unsubscribe:LIBPATH_ (`unsubscribe; 1);
