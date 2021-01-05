//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file kafka_producer.q
// @fileoverview
// Define kafka producer interfaces.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Private Functions                  //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @private
// @kind function
// @category Producer
// @brief Send messages with a specified topic to single or multiple partitions.
// @param topic_idx {int}: Index of topic in `TOPICS`.
// @param partitions {dynamic}:
// @type 
// - int: Partition to use for all message
// - list of ints: Partition per message 
// @param payloads {compound list}: List of messages.
// @param keys {dynamic}: 
// @type
// - `""`: Use auto-generated key for all messages
// - list of string: Keys for each message
// @return 
// - list of bool: Status for each published message (`1b` for error) 
// @note
// Replacement of `.kfk.BatchPub`.
.kafka.publishBatch_impl:LIBPATH_	(`publish_batch; 4);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Public Interface                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @kind function
// @category Producer
// @brief Flush a handle of a producer.
// @param producer_idx {int}: Index of a client (producer) in `CLIENT`.
// @param q_timeout {dynamic}: Timeout (milliseconds) for waiting for flush.
// @type
// - short
// - int
// - long
// @note
// Replacement of `.kfk.Flush`
.kafka.flushProducerHandle:LIBPATH_ (`flush_producer_handle; 2);

// @kind function
// @category Producer
// @brief Publish message with custom headers.
// @param producer_idx: {int} Index of client (producer) in `CLIENTS`.
// @param topic_idx: int} Index of topic in `TOPICS`.
// @param partition: {int} Topic partition.
// @param payload: {string} Payload to be sent.
// @param key: {string} Message key.
// @param headers {dictionary}: Message headers expressed in a map between header keys to header values.
// - key symbol
// - value string
// @note
// Replacement of `.kfk.PubWithHeaders`.
.kafka.publishWithHeaders:LIBPATH_	(`publish_with_headers; 6);

// @kind function
// @category Producer
// @brief Send a message with a specified topic to a specified partition.
// @param topic_idx {int}: Index of topic in `TOPICS`.
// @param partition {int}: Topic partition.
// @param payload {string}: Message to send.
// @key {string}: Message key.
// @note
// Replacement of `.kfk.Pub`.
.kafka.publish:LIBPATH_ (`publish; 4);

// @kind function
// @category Producer
// @brief Send messages with a specified topic to single or multiple partitions.
// @param topic_idx {int}: Index of topic in `TOPICS`.
// @param partitions {dynamic}: 
// @type
// - int: Partition to use for all message
// - list of ints: Partition per message 
// @param payloads {compound list}: List of messages.
// @param keys: 
// - `""`: Use auto-generated key for all messages
// - list of string: Keys for each message
// @note
// Replacement of `.kfk.BatchPub`.
.kafka.publishBatch:{[topic_idx;partitions;payloads;keys_]
  errors:.kafka.publishBatch_impl[topic_idx; partitions; payloads; keys_];
  if[count err_indices:where ` = errors; '"error in sending messages: ", -3! flip (err_indices; errors err_indices)];
 };
