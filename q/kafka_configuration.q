//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file kafka_configuration.q
// @fileoverview
// Define kafka configuration interfaces.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @private
// @kind variable
// @category Utility
// @brief One day in milliseconds.
.kafka.ONE_DAY_MILLIS:86400000;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Private Functions                  //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Utility %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// @private
// @kind function
// @category Utility
// @brief Utility function to check current assignment against proposed additions/deletions,
// @param client_idx {int}: Index of client in `CLIENTS`.
// @param toppar {dictionary}: Mapping the name of a topic to an associated partition.
// - key {symbol}: Topic
// - value {int}: topic partition
// @param add_or_delete {symbol}: `add` or `delete` denoting to what kind of function this check is conducted, i.e. `.kafka.addTopicPartition` or `.kafka.deleteTopicPartition`.
// @return
// - dictionary: Map from topic to partition which excluded overwrapping values from `topic_to_partition`.
.kafka.assignCheck:{[client_idx;topic_to_partition;add_or_delete]
  if[not 6h ~ type value topic_to_partition; '"topic-partion map must be (symbol; int) type."];
  // Generate the partition provided used to compare to current assignment
  topic_partition_list:distinct flip (key; value) @\: topic_to_partition;
  // Mark locations where user is attempting to delete from a non-existent assignment, or user is trying to add already existing one
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

//%% Configuration %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// @private
// @kind function
// @category Configuration
// @brief Assign a new map from topic to partition for consumption of message to a client.
//  Client will consume from the specified partition for the specified topic.
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @param topic_to_partiton {dictionary}: Dictionary mapping from topic to partition.
// - key {symbol}: Topic name.
// - value {int}: Partition ID.
// @note
// This function will replace existing mapping.
.kafka.assignNewTopicPartition_impl:LIBPATH_ (`assign_new_topic_partition; 1);

// @private
// @kind function
// @category Configuration
// @brief Add pairs of topic and partition to the current assignment for a given lient.
// @param consumer_idx {int}: Index of cient (consumer) in `CLIENTS`.
// @param topic_to_part {dictionary}: Dictionary mapping from topic to partition to add.
// - key {symbol}: Topic name.
// - value {int}: Partition ID.
.kafka.addTopicPartitionToAssignment_impl:LIBPATH_ (`add_topic_partition; 2);

// @private
// @kind function
// @category Configuration
// @brief Delete pairs of topic and partition from the current assignment for a client.
// @param consumer_idx {int}: Index of cient (consumer) in `CLIENTS`.
// @param topic_to_part {dictionary}: Dictionary mapping from topic to partition to delete.
// - key {symbol}: Topic name.
// - value {int}: Partition ID.
.kafka.deleteTopicPartitionFromAssignment_impl:LIBPATH_ (`delete_topic_partition; 2);

// @private
// @kind function
// @category Configuration
// @brief Get the prevailing offsets for given partitions (last consumed message+1).
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @param topic {symbol}: Topic.
// @param part_to_offset {dictionary}: Map from partition to offset. Offsets are dummy appended by q function `.kafka.setOffsetsToEnd`.
// @return 
// - list of dictionary: List of topic partition information incuding the pervailing offsets.
.kafka.getPrevailingOffsets_impl:LIBPATH_ (`get_prevailing_offsets; 3);

// @kind function
// @category Configuration
// @brief Get latest commited offset for a given topic and partitions for a client (consumer).
// @param cousumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @param topic {symbol}: Topic of partitions to which assign offsets.
// @param topic_to_part {dictionary}:
//  - key {list of symbol}: reproduced topic.
//  - value {list of int}: partition list.
// @return
// - list of dictionary: List of dictionary of partition and offset
// @note
// Replacement of `.kfk.CommittedOffsets`
.kafka.getCommittedOffsetsForTopicPartition_impl:LIBPATH_ (`get_committed_offsets_for_topic_partition; 3);

// @private
// @kind function
// @category Configuration
// @brief Query earliest offsets for given partitions whose timestamps are greater or equal to given offsets (milliseconds from epoch `1970.01.01`).
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @param topic {symbol}: Topic.
// @param part_to_offset {dictionary}: Map from partition to offset to use as start time.
// @param timeout {dynamic}: Timeout (milliseconds) for querying.
// @type
// - short
// - int
// - long
// @return 
// - list of dictionary: List of topic partition information incuding the found offsets.
.kafka.getEarliestOffsetsForTimes_impl:LIBPATH_ (`get_earliest_offsets_for_times; 4);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Public Interface                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @kind function
// @category Configuration
// @brief Assign a new map from topic to partition for the consumer.
//  Client will consume from the specified partition for the specified topic.
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @param topic_to_partiton {dictionary}: Dictionary mapping from topic to partition.
// - key {symbol}: Topic name.
// - value {int}: Partition ID.
// @note
// - This function will replace existing mapping.
// - Replacement of `.kfk.Assign`.
.kafka.assignNewTopicPartition:{[consumer_idx;topic_to_partiton]
  if[not 6i ~ type value topic_to_partiton; '"partition must be integer type."];
  // Make key-value distinct to avoid system crash
  topic_to_partiton:.[!] flip distinct flip (key; value) @\: topic_to_partiton;
  .kafka.assignNewTopicPartition_impl[consumer_idx; topic_to_partiton];
 };

// @kind function
// @category Configuration
// @brief Add pairs of topic and partition to the current assignment for a given client.
// @param consumer_idx {int}: Index of cient (consumer) in `CLIENTS`.
// @param topic_to_part {dictionary}: Dictionary mapping from topic to partition to add.
// - key {symbol}: Topic name.
// - value {int}: Partition ID.
// @note
// Replacement of `.kfk.AssignmentAdd`.
.kafka.addTopicPartitionToAssignment:{[client_idx;topic_to_partition]
  topic_to_partition:.kafka.assignCheck[client_idx; topic_to_partition; `add];
  .kafka.addTopicPartitionToAssignment_impl[client_idx; topic_to_partition];
 };

// @kind function
// @category Configuration
// @brief Delete pairs of topic and partition from the current assignment for a client.
// @param consumer_idx {int}: Index of cient (consumer) in `CLIENTS`.
// @param topic_to_part {dictionary}: Dictionary mapping from topic to partition to delete.
// - key {symbol}: Topic name.
// - value {int}: Partition ID.
// @note
// Replacement of `.kfk.AssignmentDel`.
.kafka.deleteTopicPartitionFromAssignment:{[client_idx;topic_to_partition]
  topic_to_partition:.kafka.assignCheck[client_idx; topic_to_partition; `delete];
  .kafka.deleteTopicPartitionFromAssignment_impl[client_idx; topic_to_partition];
 };

// @kind function
// @category Configuration
// @brief Set offsets on partitions of a given topic for a given client.
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @param topic {symbol}: Topic of partitions to which assign offsets.
// @param new_part_to_offset {dictionary}: Map from partition to offsets.
// - key int: partition
// - value long: offset
// @note
// - This function will replace existing mapping.
// - Replacement of `.kfk.AssignOffsets`
.kafka.assignNewOffsetsToTopicPartition:LIBPATH_	(`assign_new_offsets_to_topic_partition; 3);

// @kind function
// @category Configuration
// @brief Commit offsets on broker for partitions of a given topic for a given client.
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @param topic {symbol}: Topic of partitions to which assign offsets.
// @param part_to_offset {dictionary}: Map from partition to offsets.
// - key int: partition
// - value long: offset
// @param is_async {bool}: True to process asynchronusly. If `is_async` is false this operation will
//  block until the broker offset commit is done.
// @note
// Replacement of `.kfk.CommitOffset`
.kafka.commitOffsetsToTopicPartition:LIBPATH_ (`commit_offsets_to_topic_partition; 4);

// @kind function
// @category Configuration
// @brief Query earliest offsets for given partitions whose timestamps are greater or equal to given offsets (milliseconds from epoch `1970.01.01`).
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @param topic {symbol}: Topic.
// @param part_to_offset {dictionary}: Map from partition to offset to use as start time.
// @param timeout {number}: Timeout (milliseconds) for querying.
// @return 
// - list of dictionary: List of topic partition information incuding the found offsets.
// @note
// Replacement of `.kfk.OffsetsForTimes`.
.kafka.getEarliestOffsetsForTimes:{[consumer_idx;topic;part_to_offset;timeout]

  offset_type:type value part_to_offset;
  if[not offset_type in (7h; 12h; 14h);
    '"offset must be [list of longs | list of timestamp | list of date] type."
  ];

  // Convert offset to long (milisecond)
  part_to_offset:$[
    // date
    offset_type=14h;
    .kafka.ONE_DAY_MILLIS * part_to_offset - 1970.01.01;
    // timestamp
    offset_type=12h;
    floor (`long$part_to_offset-1970.01.01D)%1e6;
    // long
    // offset_type=7h;
    part_to_offset
  ];

  .kafka.getEarliestOffsetsForTimes_impl[consumer_idx; topic; part_to_offset; timeout]
 };

// @kind function
// @category Configuration
// @brief Get the prevailing offsets for given partitions (last consumed message+1).
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @param topic {symbol}: Topic.
// @param partitions: Partitions whose offsets are set to the prevailing position.
// @return 
// - list of dictionary: List of topic partition information including the prevailing offsets.
// @note
// Replacement of `.kfk.PositionOffsets`.
.kafka.getPrevailingOffsets:{[consumer_idx;topic;partitions]
  .kafka.getPrevailingOffsets_impl[consumer_idx; topic; partitions!count[partitions]#0]
 };

// @kind function
// @category Configuration
// @brief Return the current consumption assignment for a specified client
// @param consumer_idx: Indexc of client (consumer).
// @type
// - int
// @return
// - list of dictionaries: List of information of topic-partitions.
// @note
// Replacement of `.kfk.Assignment`
.kafka.getCurrentAssignment:LIBPATH_ (`get_current_assignment; 1);

// @kind function
// @category Configuration
// @brief Get latest commited offset for a given topic and partitions for a client (consumer).
// @param consumer_idx {int}: Index of client (consumer) in `CLIENTS`.
// @param topic {symbol}: Topic of partitions to which assign offsets.
// @param partitions {list of long}: List of partition.
// @return
// - list of dictionary: List of dictionary of partition and offset
// @note
// Replacement of `.kfk.CommittedOffsets`
.kafka.getCommittedOffsetsForTopicPartition:{[consumer_idx;topic;partitions]
  .kafka.getCommittedOffsetsForTopicPartition_impl[consumer_idx; topic; (count[partitions]#topic)!partitions]
 };

// @kind function
// @category Configuration
// @brief Get configuration of topic and broker for a given client index.
// @param client_idx {int}: Index of client in `CLIENT`.
// @param timeout {int}: Timeout (milliseconds) for querying.
// @return 
// - dictionary: Informaition of originating broker, brokers and topics.
//   - orig_broker_id {int}: Broker originating this meta data
//   - orig_broker_name {symbol}: Name of originating broker
//   - brokers {list of dictionary}: Information of brokers
//   - topics {list of dictionary}: Infomation of topics
// @note
// Replacement of `.kfk.Metadata`
.kafka.getBrokerTopicConfig:LIBPATH_ (`get_broker_topic_config; 2);
