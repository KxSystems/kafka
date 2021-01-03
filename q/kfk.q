//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @file
* kfk.q
* @overview
* Define kafka client interfaces.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      DO NOT EDIT                      //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Enter to `.kfk` name space
// !! WARNING !! //
// Do not load any q file inside this scope; or namespace contamination will happen.
\d .kafka

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

LIBPATH_:`:kafkakdb 2:;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Utility %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Offset between UNIX epoch (1970.01.01) and kdb+ epoch (2000.01.01) in day.
\
KDB_DAY_OFFSET:10957D;

/
* @brief One day in milliseconds.
\
ONE_DAY_MILLIS:86400000;

// Unassigned partition.
// The unassigned partition is used by the producer API for messages
// that should be partitioned using the configured or default partitioner.
PARTITION_UA:-1i;

// taken from librdkafka.h
OFFSET.BEGINNING:		-2  /**< Start consuming from beginning of kafka partition queue: oldest msg */
OFFSET.END:     		-1  /**< Start consuming from end of kafka partition queue: next msg */
OFFSET.STORED:	 -1000  /**< Start consuming from offset retrieved from offset store */
OFFSET.INVALID:	 -1001  /**< Invalid offset */

/
* @brief Mapping between client and the topics
\
CLIENT_TOPIC_MAP:(`int$())!();

/
* @brief Mapping between client and the type of handle created i.e. producer/consumer
\
CLIENT_TYPE_MAP:(`int$())!`symbol$();

/
* @brief Dictionary of error callback functions per client index.
* @key
* int: Client index in `CLIENTS`.
* @value
* function: Callback function called in `error_cb`.
\
ERROR_CALLBACK_PER_CLIENT:enlist[0Ni]!enlist (::);

/
* @brief Dictionary of throttle callback functions per client index.
* @key
* int: Client index in `CLIENTS`.
* @value
* function: Callback function called in `throttle_cb`.
\
THROTTLE_CALLBACK_PER_CLIENT:enlist[0Ni]!enlist (::);


/
* @brief Dictionary of consume_callback functions for each topic per client index.
* @key
* int: Client (consumer) index in `CLIENTS`.
* @value
* dictionary: Dictionary of callback function for each topic.
* - key: symbol: topic.
* - value: function: callback function called inside `.kfk.consume_callback`.
\
CONSUME_TOPIC_CALLBACK_PER_CONSUMER:enlist[0Ni]!enlist ()!();

PRODUCER:"p";
CONSUMER:"c";

// table with kafka statistics
STATISTICS:();


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Private Functions                  //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Utility %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// Utility function to check current assignment against proposed additions/deletions,
// return unique toppar pairs as a dictionary to avoid segfaults from duplicate 
/* client_idx: Index of client in `CLIENTS`.
/* toppar = Symbol!Long dictionary mapping the name of a topic to an associated partition
/* addDel = Boolean denoting addition/deletion functionality
assignCheck:{[client_idx;topic_to_partition;add_or_delete]
  // Generate the partition provided used to compare to current assignment
  topic_partition_list:distinct flip (key; value) @\: topic_to_partition;
  // Mark locations where user is attempting to delete from an non existent assignment
  location:topic_partition_list where $[`add ~ add_or_delete; ::; not] topic_partition_list in .kafka.getCurrentAssignment[client_idx][::; `topic`partition];
  if[count location;
    show location;
    $[`add ~ add_or_delete;
      '"the above topic-partition pairs already exist";
      '"the above topic-partition pairs do not exist"
    ]
  ];
  .[!] flip topic_partition_list
 };

//%% Callback %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// https://docs.confluent.io/current/clients/librdkafka/rdkafka_8h.html

/
* @brief Callback function for statistics set by `rd_kafka_conf_set_stats_cb`. Deligated by C function `stats_cb`.
* @param statistics: Statistics in JSON format.
* @type
* - string
* @note
* This function is triggered from `rd_kafka_poll()` every `statistics.interval.ms`.
\
stats_cb:{[statistics]
  statistics:.j.k statistics;

  if[all `ts`time in key statistics;
    // Convert data to timestamp
    statistics[`ts]:(`timestamp$statistics[`ts]*1000) - KDB_DAY_OFFSET;
    statistics[`time]:(`timestamp$1e9*statistics[`time]) - KDB_DAY_OFFSET;
  ];
  if[not `cgrp in key statistics; statistics[`cgrp]:()];

  // Insert the new record
  .kafka.STATISTICS,:enlist statistics;
  // Keep only 100 records
  delete from `.kafka.STATISTICS where i < count[.kafka.STATISTICS]-100;
 };

/
* @brief Callback function to print log set by `rd_kafka_conf_set_log_cb`.
*  Deligated by C function `log_cb`.
* @param level: log level.
* @type
* - int
* @param fac: WHAT IS THIS??
* @type
- string
* @param buf: WHAT IS THIS??
* @type
- string
* @todo
* Change output destination by `level`
\
log_cb:{[level;fac;buf] show -3!(level; fac; buf);};

/
* @brief Callback function set by `rd_kafka_conf_set_offset_commit_cb` and triggered by `rd_kafka_consumer_poll()`
*  for use with consumer groups. Deligated by C function `offset_commit_cb`.
* @param cid: client (consumer) index
* @type
* - int
* @param err: error message
* @type
* - string
* @param offsets: A list of topic-partition information dictionaries
* @type
* - list of dictionaries
\
offset_commit_cb:{[cid;err;offsets]
  // Nothing to do
 };

// PRODUCER: delivery callback (rd_kafka_conf_set_dr_msg_cb )
/
* @brief Callback function for delivery report set by `rd_kafka_conf_set_dr_msg_cb`.
* @param cid: Index of client (consumer).
* @type
* - int
* @param msg: Information conatined in delivery report.
* @type
* - dictionary
\
dr_msg_cb:{[cid;msg]
  // Nothing to do
 };

/
* @brief Default callback function for error or warning called inside `.kfk.error_cb`
* @param cid: Index of client.
* @type
* - int
* @param error_code: Error code.
* @type
* - int
* @param reason: Reason for the error.
* @type
* - string
\
default_error_cb:{[cid;error_code;reason]
  // Nothing to do
 };

/
* @brief Callback function for error or warning. Deligated by C function `error_cb`.
* @param cid: Index of client.
* @type
* - int
* @param error_code: Error code.
* @type
* - int
* @param reason: Reason for the error.
* @type
* - string
\
error_cb:{[cid;error_code;reason]
  // Call registered callback function if any; otherwise call default callback function
  $[null registered_error_cb:ERROR_CALLBACK_PER_CLIENT cid; default_error_cb; registered_error_cb] . (cid; error_code; reason)
 };

/
* @brief Default callback function for throttle events to request producing and consuming. Called inside `.kfk.throttle_cb`.
* @param handle: Index of client.
* @type
* - int
* @param brokername: Name of broker.
* @type
* - string
* @param brokerid: ID of broker.
* @type
* - int
* @param throttle_time_ms: Broker throttle time in milliseconds.
* @type
* - int
\
default_throttle_cb:{[client_id;broker_name;broker_id;throttle_time]
  // Nothing to do
 };

/
* @brief Callback function for throttle events to request producing and consuming. Deligated by C function `throttle_cb`.
* @param handle: Index of client.
* @type
* - int
* @param brokername: Name of broker.
* @type
* - string
* @param brokerid: ID of broker.
* @type
* - int
* @param throttle_time_ms: Broker throttle time in milliseconds.
* @type
* - int
\
throttle_cb:{[client_id;broker_name;broker_id;throttle_time]
  // Call registered callback function if any; otherwise call default callback function
  $[null registered_throttle_cb:THROTTLE_CALLBACK_PER_CLIENT client_id; default_throttle_cb; registered_throttle_cb] . (client_id; broker_name; broker_id; throttle_time)
 };

/
* @brief Default callback for consuming messages called inside `.kfk.consume_cb`.
* @param message: Dictionary containing a message returned by `rd_kafka_consumer_poll()`.
\
default_consume_topic_cb:{[msg]}

/
* @brief Callback function for consuming messages triggered by `rd_kafka_consumer_poll()`. Deligated by C function `poll_client`.
* @param consumer_idx: Index of client (consumer) in `CLIENTS`.
* @type
* - int
* @param message: Dictionary containing a message returned by `rd_kafka_consumer_poll()`.
* @type
* - dictionary
\
consume_topic_cb:{[consumer_idx; message]
  // Call registered callback function for the topic in the message if any; otherwise call default callback function.
  $[null registered_consume_topic_cb:CONSUME_TOPIC_CALLBACK_PER_CONSUMER[consumer_idx; message `topic]; default_consume_topic_cb; registered_consume_topic_cb] message
 };

//%% Client %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Create a client based on a given client type (producer or consumer) and a given configuration.
* @param client_type {char}:
* - "p": Producer
* - "c": Consumer
* @param config {dictionary}: Dictionary containing a configuration.
*  - key: symbol
*  - value: symbol
* @return
* - error: If passing client type which is neither of "p" or "c". 
* - int: Client index in `CLIENTS`.
\
newClient_impl:LIBPATH_ (`new_client; 2);

/
* @brief Create a client based on a given client type (producer or consumer) and a given configuration and then
*  add client type (consumer or producer) to `.kafka.CLIENT_TYPE_MAP`.
* @param client_type {char}:
* - "p": Producer
* - "c": Consumer
* @param config {dictionary}: Dictionary containing a configuration.
*  - key: symbol
*  - value: symbol
* @return
* - error: If passing client type which is neither of "p" or "c". 
* - int: Client index in `CLIENTS`.
\
newClient:{[client_type;config]
  if[(not `group.id in key config) and client_type="c"; '"consumer must define 'group.id' within the config"];
  client:.kafka.newClient_impl[client_type; config];
  .kafka.CLIENT_TYPE_MAP ,:enlist[client]!enlist[`Consumer];
  client
 };

/
* @brief Destroy client handle and remove from `CLIENTS`.
* @param client_idx {int}: Index of client in `CLIENTS`.
* @type
* - int
\
deleteClient_impl:LIBPATH_	(`delete_client;1);

//%% Topic %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Create a new topic.
* @param client_idx: index of client in `CLIENTS`.
* @type
* - int
* @param topic: New topic to create.
* @type
* - symbol
* @param config: Dictionary storing configuration of the new topic.
* @type
* - dictionary
*   @key symbol: Key of the configuration.
*   @value symbol: Value of the configuration.
* @return
* - int: Topic handle assigned by kafka.
\
newTopic_impl:LIBPATH_ (`new_topic; 3);

/
* @brief Delete the given topic.
* @param topic_idx: Index of topic in `TOPICS`.
* @type
* - int
* @note
* Replacement of `.kfk.TopicDel`
\
deleteTopic:LIBPATH_ (`delete_topic; 1);

//%% Configuration %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
@brief Assign a new map from topic to partition for consumption of message to a client.
*  Client will consume from the specified partition for the specified topic.
* @param consumer_idx: Index of client (consumer) in `CLIENTS`.
* @type
* - int
* @param topic_to_partiton: Dictionary mapping from topic to partition.
* @type
* - dictionary
*   @key symbol: Topic name.
*   @value long: Partition ID.
* @note
* - This function will replace existing mapping.
\
assignNewTopicPartition_impl:LIBPATH_ (`assign_new_topic_partition; 1);

/
* @brief Add pairs of topic and partition to the current assignment for a given lient.
* @param consumer_idx: Index of cient (consumer) in `CLIENTS`.
* @type
* - int
* @param topic_to_part {dictionary}: Dictionary mapping from topic to partition to add.
* - key {symbol}: Topic name.
* - value {int}: Partition ID.
* @note
* Replacement of `.kfk.AssignmentAdd`.
\
addTopicPartition_impl:LIBPATH_ (`add_topic_partion; 2);

/
* @brief Delete pairs of topic and partition from the current assignment for a client.
* @param consumer_idx: Index of cient (consumer) in `CLIENTS`.
* @type
* - int
* @param topic_to_part {dictionary}: Dictionary mapping from topic to partition to delete.
* - key {symbol}: Topic name.
* - value {int}: Partition ID.
\
deleteTopicPartition_impl:LIBPATH_ (`delete_topic_partition; 2);

/
* @brief Reset offsets for given partitions to last message+1.
* @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
* @param topic {symbol}: Topic.
* @param part_to_offset: Map from partition to offset. Offsets are dummy appended by q function `.kafka.setOffsetsToEnd`.
* @return 
* - list of dictionary: List of topic partition information incuding the reset offsets.
* @note
* Replacement of `.kfk.PositionOffsets`.
\
setOffsetsToEnd_impl:LIBPATH_ (`set_offsets_to_end; 3);

/
* @brief Query earliest offsets for given partitions whose timestamps are greater or equal to given offsets (milliseconds from epoch `1970.01.01`).
* @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
* @param topic {symbol}: Topic.
* @param part_to_offset {dictionary}: Map from partition to offset to use as start time.
* @param timeout: Timeout (milliseconds) for querying.
* @type
* - short
* - int
* - long
* @return 
* - list of dictionary: List of topic partition information incuding the found offsets.
* @note
* Replacement of `.kfk.OffsetsForTimes`.
\
getEarliestOffsetsForTimes_impl:LIBPATH_ (`get_earliest_offsets_for_times; 3);

//%% Producer %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
 * @brief Send messages with a specified topic to single or multiple partitions.
 * @param topic_idx {int}: Index of topic in `TOPICS`.
 * @param partitions: 
 * - int: Partition to use for all message
 * - list of ints: Partition per message 
 * @param payloads {compound list}: List of messages.
 * @param keys: 
 * - `""`: Use auto-generated key for all messages
 * - list of string: Keys for each message
 * @return 
 * - list of bool: Status for each published message (`1b` for error) 
 * @note
 * Replacement of `.kfk.BatchPub`.
\
publishBatch_impl:LIBPATH_	(`publish_batch; 4);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Public Interface                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Initializer %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Initialize internal state of interface.
* @note
* Replacement of `.kfk.Init`.
\
init:LIBPATH_	(`init; 1);

//%% Configuration %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Get a name of client from client index.
* @param client_index: Index of client in `CLIENTS`.
* @type
* - int
* @return
* - symbol: handle name of the client denoted by the given index.
* @note
* Replacement of `.kfk.ClientName`
\
getClientName:LIBPATH_ (`get_client_name; 1);

/
* @brief Set log level for a given client.
* @param client_idx {int}: Index of client in `CLIENTS`.
* @param level: Severity levels in syslog.
* @type
* - short
* - int
* - long
* @note 
* - For level setting, see https://en.wikipedia.org/wiki/Syslog#Severity_level
* - Replacement of `.kfk.SetLoggerLevel`.
\
setLogLevel:LIBPATH_ (`set_log_level; 2);

/
* @brief Get the broker-assigned group member ID of the client (consumer).
* @param consumer_idx: Index of client (consumer) in `CLIENTS`.
* @type
* - int
* @return
* - symbol: Broker-assigned group member ID of the consumer.
* @note
* Replacement of `.kfk.ClientMemberId`
\
getConsumerGroupMemberID:LIBPATH_ 	(`get_consumer_group_member_id; 1);

/
* @brief Get current subscription information for a consumer.
* @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
* @return
* - list of dictionary: A list of topic-partition information dictionary.
* @note
* Replacement of `.kfk.Subscription`.
\
getCurrentSubscription:LIBPATH_ (`get_current_subscription; 1);

/
* @brief Get a name of topic from topic index.
* @param topic_idx: Index of topic in `TOPICS`.
* @type
* - int
* @return
* - symbol: Topic name.
* @note
* Replacement of `.kfk.TopicName`
\
getTopicName:(`get_topic_name; 1);

/
* @brief Assign a new map from topic to partition for consumption of message to a client.
*  Client will consume from the specified partition for the specified topic.
* @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
* @param topic_to_partiton {dictionary}: Dictionary mapping from topic to partition.
* - key {symbol}: Topic name.
* - value {long}: Partition ID.
* @note
* - This function will replace existing mapping.
* - Replacement of `.kfk.Assign`.
\
assignNewTopicPartition:{[consumer_idx;topic_to_partiton]
  // Make key-value distinct to avoid system crash
  topic_to_partiton:.[!] flip distinct flip (key; value) @\: topic_to_partiton;
  .kafka.assignNewTopicPartition_impl[consumer_idx; topic_to_partiton];
 };

/
* @brief Add pairs of topic and partition to the current assignment for a given lient.
* @param consumer_idx: Index of cient (consumer) in `CLIENTS`.
* @type
* - int
* @param topic_to_part {dictionary}: Dictionary mapping from topic to partition to add.
* - key {symbol}: Topic name.
* - value {int}: Partition ID.
* @note
* Replacement of `.kfk.AssignmentAdd`.
\
addTopicPartition:{[client_idx;topic_to_partition]
  topic_to_partition:assignCheck[client_idx; topic_to_partition; `add];
  addTopicPartition_impl[client_idx; topic_to_partition];
 };

/
* @brief Delete pairs of topic and partition from the current assignment for a client.
* @param consumer_idx: Index of cient (consumer) in `CLIENTS`.
* @type
* - int
* @param topic_to_part {dictionary}: Dictionary mapping from topic to partition to delete.
* - key {symbol}: Topic name.
* - value {int}: Partition ID.
* @note
* Replacement of `.kfk.AssignmentDel`.
\
deleteTopicPartition:{[client_idx;topic_to_partition]
  topic_to_partition:assignCheck[client_idx; topic_to_partition; `delete];
  deleteTopicPartition_impl[client_idx; topic_to_partition];
 };

/
* @brief Set offsets on partitions of a given topic for a given client.
* @param consumer_idx: Index of client (consumer) in `CLIENTS`.
* @type
* - int
* @param topic: Topic of partitions to which assign offsets.
* @type
* - symbol
* @param new_part_to_offset: Map from partition to offsets.
* @type
* - dictionary
*   @key int: partition
*   @value long: offset
* @note
* - This function will replace existing mapping.
* - Replacement of `.kfk.AssignOffset`
\
assignNewOffsetsToTopicPartition:LIBPATH_	(`assign_new_offsets_to_topic_partition; 3);

/
* @brief Commit new offsets on partitions of a given topic for a given client.
* @param consumer_idx: Index of client (consumer) in `CLIENTS`.
* @type
* - int
* @param topic: Topic of partitions to which assign offsets.
* @type
* - symbol
* @param new_part_to_offset: Map from partition to offsets.
* @type
* - dictionary
*   @key int: partition
*   @value long: offset
* @param is_async: True to process asynchronusly. If `is_async` is false this operation will
* @type
* - bool
*  block until the broker offset commit is done.
* @note
* - This function will replace existing mapping.
* - Replacement of `.kfk.CommitOffset`
\
commitNewOffsetsToTopicPartition:LIBPATH_ (`commit_new_offsets_to_topic_partition; 4);

/
* @brief Query earliest offsets for given partitions whose timestamps are greater or equal to given offsets (milliseconds from epoch `1970.01.01`).
* @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
* @param topic {symbol}: Topic.
* @param part_to_offset {dictionary}: Map from partition to offset to use as start time.
* @param timeout: Timeout (milliseconds) for querying.
* @type
* - short
* - int
* - long
* @return 
* - list of dictionary: List of topic partition information incuding the found offsets.
* @note
* Replacement of `.kfk.OffsetsForTimes`.
\
getEarliestOffsetsForTimes:{[consumer_idx;topic;part_to_offset;timeout]

  offset_type:type value part_to_offset;
  if[not offset_type in (7h; 12h; 14h);
    '"offset must be [list of longs | list of timestamp | list of date] type."
  ];

  // Convert offset to long (milisecond)
  part_to_offset:$[
    // date
    offset_type=14h;
    ONE_DAY_MILLIS * part_to_offset - 1970.01.01;
    // timestamp
    offset_type=12h;
    floor (`long$part_to_offset-1970.01.01D)%1e6;
    // long
    // offset_type=7h;
    part_to_offset
  ];

  getEarliestOffsetsForTimes_impl[consumer_idx; topic; part_to_offset; timeout]
 };

/
* @brief Reset offsets for given partitions to last message+1.
* @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
* @param topic {symbol}: Topic.
* @param partitions: Partitions whose offsets are set to the prevailing position.
* @return 
* - list of dictionary: List of topic partition information incuding the reset offsets.
* @note
* Replacement of `.kfk.PositionOffsets`.
\
setOffsetsToEnd:{[consumer_idx;topic;partitions]
  .kafka.setOffsetsToEnd_impl[consumer_idx; topic; partitions!count[partitions]#0]
 };

/
* @brief Return the current consumption assignment for a specified client
* @param consumer_idx: Indexc of client (consumer).
* @type
* - int
* @return
* - list of dictionaries: List of information of topic-partitions.
* @note
* Replacement of `.kfk.Assignment`
\
getCurrentAssignment:LIBPATH_ (`get_current_assignment; 1);

/
* @brief Get latest commited offset for a given topic and partitions for a client (consumer).
* @param cousumer_idx: Index of client (consumer) in `CLIENTS`.
* @type
* - int
* @param topic: Topic of partitions to which assign offsets.
* @type
* - symbol
* @param partitions: List of partitions.
* @type
* - list of long
* @return
* - list of dictionary: List of dictionary of partition and offset
* @note
* Replacement of `.kfk.CommittedOffsets`
\
getCommittedOffsetsForTopicPartition:LIBPATH_ (`get_committed_offsets_for_topic_partition; 3);

/
* @brief Get configuration of topic and broker for a given client index.
* @param client_idx: Index of client in `CLIENT`.
* @type
* - int
* @return 
* - dictionary: Informaition of originating broker, brokers and topics.
*   @key orig_broker_id: int | Broker originating this meta data
*   @key orig_broker_name | symbol | Name of originating broker
*   @key brokers: list of dictionary | Information of brokers
*   @key topics: list of dictionary | Infomation of topics
* @note
* Replacement of `.kfk.Metadata`
\
getBrokerTopicConfig:LIBPATH_ (`get_broker_topic_config; 1);

//%% Topic %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Create a new topic and tie up with a given client by `.kafka.CLIENT_TOPIC_MAP`.
* @param client_idx: index of client in `CLIENTS`.
* @type
* - int
* @param topic: New topic to create.
* @type
* - symbol
* @param config: Dictionary storing configuration of the new topic.
* @type
* - dictionary
*   @key symbol: Key of the configuration.
*   @value symbol: Value of the configuration.
* @return
* - int: Topic handle assigned by kafka.
* @note
* Replacement of `.kfk.Topic`
\
newTopic:{[client_idx;topic;config]
  topic:.kafka.newTopic_impl[client_idx; topic; config];
  .kafka.CLIENT_TOPIC_MAP[client_idx],: topic;
  topic
 };

//%% Producer %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Flush a handle of a producer.
* @param producer_idx: Index of a client (producer) in `CLIENT`.
* @type
* - int
* @param q_timeout: Timeout (milliseconds) for waiting for flush.
* @type
* - short
* - int
* - long
* @note
* Replacement of `.kfk.Flush`
\
flushProducerHandle:LIBPATH_ (`flush_producer_handle; 2);

/
* @brief Publish message with custom headers.
* @param producer_idx: {int} Index of client (producer) in `CLIENTS`.
* @param topic_idx: int} Index of topic in `TOPICS`.
* @param partition: {int} Topic partition.
* @param payload: {string} Payload to be sent.
* @param key: {string} Message key.
* @param headers: Message headers expressed in a map between header keys to header values.
* @type
* - dictionary
*   @key symbol
*   @value string
* @note
* Replacement of `.kfk.PubWithHeaders`.
\
publishWithHeaders:LIBPATH_	(`publish_with_headers; 6);

/
* @brief Send a message with a specified topic to a specified partition.
* @param topic_idx {int}: Index of topic in `TOPICS`.
* @param partition {int}: Topic partition.
* @param payload {string}: Message to send.
* @key {string}: Message key.
* @note
* Replacement of `.kfk.Pub`.
\
publish:LIBPATH_ (`publish; 4);

/
 * @brief Send messages with a specified topic to single or multiple partitions.
 * @param topic_idx {int}: Index of topic in `TOPICS`.
 * @param partitions: 
 * - int: Partition to use for all message
 * - list of ints: Partition per message 
 * @param payloads {compound list}: List of messages.
 * @param keys: 
 * - `""`: Use auto-generated key for all messages
 * - list of string: Keys for each message
 * @note
 * Replacement of `.kfk.BatchPub`.
\
publishBatch:{[topic_idx;partitions;payloads;keys_]
  errors:publishBatch_impl[topic_idx; partitions; payloads; keys_];
  if[count err_indices:where ` = errors; '"error in sending messages: ", -3! flip (err_indices; errors err_indices)];
 };

//%% Consumer %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Subscribe to a given topic with its partitions (and offsets).
* @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
* @param topic {symbol}: Topic to subscribe.
* @param partition_to_offset: Topic partitons (and corresponding offsets).
* @type
* - list of int: List of partitions.
* - dictionary: Map from partition to offset 
* @note
* Replacement of `.kfk.Sub`.
\
subscribe:LIBPATH_ (`subscribe; 3);

/
* @brief Make a given consumer unsubscribe.
* @param consumer_idx: Index of client (consumer) in `CLIENTS`.
* @note
* Replacement of `.kfk.Unsub`.
\
unsubscribe:LIBPATH_ (`unsubscribe; 1);

//%% Client %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Destroy client handle and remove from `CLIENTS`.
* @param client_idx {int}: Index of client in `CLIENTS`.
* @note
* Replacement of `.kfk.ClientDel`. 
\
deleteClient:{[client_idx]
  // Get topics with which the client is tied up.
  topics:.kafka.CLIENT_TOPIC_MAP[client_idx];

  // Delete the client from client-topic map
  .kafka.CLIENT_TOPIC_MAP:client_idx _ .kafka.CLIENT_TOPIC_MAP;

  // Get a topic with which no one is tied up and delete them frm kafka ecosystem
  garbage_topic:topics where not topics in .kafka.CLIENT_TOPIC_MAP;
  if[count garbage_topic; @[.kafka.deleteTopic; ; {[error] -2 error;}] each garbage_topic];

  // Delete the client frm kafka ecosystem
  .kafka.deleteClient_impl[client_idx];
 };

/
* @brief Create a producer with a given configuration.
* @param config {dictionary}: Dictionary containing a configuration.
*  - key: symbol
*  - value: symbol
* @return
* - int: Client index in `CLIENTS`.
\
newProducer:{[config]
  .kafka.newClient["p"; config]
 };

/
* @brief Create a consumer with a given configuration.
* @param config {dictionary}: Dictionary containing a configuration.
*  - key: symbol
*  - value: symbol
* @return
* - int: Client index in `CLIENTS`.
\
newConsumer:{[config]
  .kafka.newClient["c"; config]
 };

//%% Callback %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Register error callback function for a given client.
* @param client_idx: Index of client in `CLIENTS`.
* @type
* - int
* @param callback: Callback function.
* @type
* - function
* @note
* Replacement of `.kfk.errcbreg`.
\
registerErrorCallback:{[client_idx;callback]
  ERROR_CALLBACK_PER_CLIENT[client_idx]:callback;
 };

/
* @brief Register error callback function for a given client.
* @param client_idx: Index of client in `CLIENTS`.
* @type
* - int
* @param callback: Callback function.
* @type
* - function
* @note
* Replacement of `.kfk.throttlecbreg`.
\
registerThrottleCallback:{[client_idx;callback]
  THROTTLE_CALLBACK_PER_CLIENT[client_idx]:callback;
 };

/
* @brief Register callback at message consumption for a given client and topic.
* @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
* @param topic {symbol}: Topic for which calback is to be set.
* @param callback {function}: Callback function.
\
registerConsumeTopicCallback:{[consumer_idx; topic; callback]
  CONSUME_TOPIC_CALLBACK_PER_CONSUMER[consumer_idx],:enlist[topic]!enlist callback;
 };

//%% Poll %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Poll client manually.
* @param client_idx: Client index in `CLIENTS`.
* @type
* - int
* @param timeout: The maximum amount of time (in milliseconds) that the call will block waiting for events.
* - 0: non-blocking
* - -1: wait indefinitely
* - others: wait for this period
* @type
* - long
* @param max_poll_cnt: The maximum number of polls, in turn the number of messages to get.
* @type
* - long
* @return
* - long: The number of messages retrieved (poll count).
* @note
* Replacement of `.kfk.Poll`
\
manualPoll:LIBPATH_ (`manual_poll; 3);

/
* @brief Set maximum number of polling at execution of `.kafka.manualPoll` function or C function `poll_client`.
*  This number coincides with the number of maximum number of messages to retrieve.
* @param n: The maximum number of polling at execution of `.kafka.manualPoll` function.
* @type
* - long
* @return
* - long: The number set.
* @note
* Replacement of `.kfk.MaxMsgsPerPoll`.
\
setMaximumNumberOfPolling:LIBPATH_ (`set_maximum_number_of_polling; 1);

//%% Miscellaneous %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Return the current out queue length for a given client.
* @param client_idx {int}: Index of client in `CLIENTS`.
* @note
* - Only for debug. This function is called inside `.kafka.deleteClient` and exit timing internally.
* - Replacement of `.kfk.OutQLen`.
\
getOutQueueLength:LIBPATH_ (`get_out_queue_length; 1);

/
* @brief Returns the number of threads currently being used by librdkafka.
* @return The number of thread used by rdkafka.
* @note
* Replacement of `.kfk.Threadcount`.
\
getKafkaThreadCount:LIBPATH_ (`get_kafka_thread_count; 1);

/
* @brief Get rdkafka version.
* @return
* - int: Version of rdkafka.
* @note
* Replacement of `.kfk.Version`.
\
version:LIBPATH_ (`version; 1);

/
* @brief Returns the human readable librdkafka version.
* @return
* - string: String version of librdkafka.
\
versionString:LIBPATH_ (`version_string; 1);

/
* @brief Display error description for each error code.
* @return
* - table: Error description table of librdkafka.
* @note
* Replacement of `.kfk.ExportErr`.
\
errorDescriptionTable:LIBPATH_ (`kafka_error_description_table; 1);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      DO NOT EDIT                      //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Close namespace `.kafka`
\d .

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Initialize State                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

.kafka.init[];
