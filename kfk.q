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
\d .kfk

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

SHARED_FUNCTIONS_:(
	// .kfk.init[]:i
	(`kfkInit;1);
	// .kfk.Pub[topic_id:i;partid:i;data;key]:_
	(`kfkPub;4);
	// .kfk.BatchPub[topic_id:i;partid:i;data;key]:_
	(`kfkBatchPub;4);
	// .kfk.OutQLen[client_id:i]:i
	(`kfkOutQLen;1);
	// .kfk.Sub[client_id:i;topicname:s;partition_list|partition_offsets:I!J]:()
	(`kfkSub;3);
	// .kfk.Unsub[client_id:i]:()
	(`kfkUnsub;1);
	// .kfk.Subscription[client_id:i]
	(`kfkSubscription;1);
	// .kfk.ExportErr[]:T
	(`kfkExportErr;1);
	// .kfk.PositionOffsets[client_id:i;topic:s;partition_offsets:I!J]:partition_offsets
	(`kfkPositionOffsets;3);
  // .kfk.Threadcount[]:i
  (`kfkThreadCount;1);
  // .kfk.VersionSym[]:s
  (`kfkVersionSym;1);
  // .kfk.SetLoggerLevel[client_id:i;int_level:i]:()
  (`kfkSetLoggerLevel;2);
  // .kfk.OffsetsForTimes[client_id:i;topic:s;partition_offsets:I!J;timeout_ms]:partition_offsets
  (`kfkoffsetForTime;4)
 );

// Add functions to namespace dictionary
// ex.) kfkAssignmentAdd => .kfk.assignmentAdd
LIBPATH_:`:libkfk 2:;
.kfk,: (`$3_' (.Q.a .Q.A?first each funcnames),' 1 _/: funcnames:string SHARED_FUNCTIONS_[::; 0])!LIBPATH_ @/: SHARED_FUNCTIONS_;

/
* @todo
* Change function name snake case in C file and convert to camel case with following command:
* {[funcname] `$raze {[word] (.Q.A .Q.a?first word), 1_word} each "_" vs string funcname} each SHARED_FUNCTIONS_[::; 0]
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Utility %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Offset between UNIX epoch (1970.01.01) and kdb+ epoch (2000.01.01) in day.
\
KDB_DAY_OFFSET:10957D;

// Unassigned partition.
// The unassigned partition is used by the producer API for messages
// that should be partitioned using the configured or default partitioner.
PARTITION_UA:-1i;

// taken from librdkafka.h
OFFSET.BEGINNING:		-2  /**< Start consuming from beginning of kafka partition queue: oldest msg */
OFFSET.END:     		-1  /**< Start consuming from end of kafka partition queue: next msg */
OFFSET.STORED:	 -1000  /**< Start consuming from offset retrieved from offset store */
OFFSET.INVALID:	 -1001  /**< Invalid offset */

// Mapping between client and the topics associated with these clients
ClientTopicMap:(`int$())!();
// Mapping between client and the type of handle created i.e. producer/consumer
ClientTypeMap :(`int$())!`symbol$();

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
* int: Client index in `CLIENTS`.
* @value
* dictionary: Dictionary of callback function for each topic.
* - key: symbol: topic.
* - value: function: callback function called inside `.kfk.consume_callback`.
\
CONSUME_TOPIC_CALLBACK_PER_CLIENT:enlist[0Ni]!enlist ()!();

PRODUCER:"p";
CONSUMER:"c";

// table with kafka statistics
stats:();


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Private Functions                  //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Utility %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// Utility function to check current assignment against proposed additions/deletions,
// retirn unique toppar pairs as a dictionary to avoid segfaults from duplicate 
/* cid    = Integer denoting the client ID
/* toppar = Symbol!Long dictionary mapping the name of a topic to an associated partition
/* addDel = Boolean denoting addition/deletion functionality
i.assignCheck:{[cid;toppar;addDel]
  i.checkDict[toppar];
  // Generate the partition provided used to compare to current assignment
  tplist:distinct(,'/)(key;value)@\:toppar;
  // Mark locations where user is attempting to delete from an non existent assignment
  loc:$[addDel;not;]i.compAssign[cid;tplist];
  if[any loc;
    show tplist where loc;
    $[addDel;
      '"The above topic-partition pairs cannot be deleted as they are not assigned";
      '"The above topic-partition pairs already exist, please modify dictionary"]
    ];
  (!). flip tplist
 }

// dictionary defining the current assignment for used in comparisons 
i.compAssign:{[cid;tplist]
  assignment:Assignment[cid];
  // current assignment is a list of dictionaries
  currentTopPar:(assignment@'`topic),'"j"$assignment@'`partition;
  tplist in currentTopPar
 }

// Ensure that the dictionaries used in assignments map symbol to long
i.checkDict:{[dict]
  if[not 99h=type dict      ;'"Final parameter must be a dictionary"];
  if[not 11h=type key dict  ;'"Dictionary key must of type symbol"];
  if[not 7h =type value dict;'"Dictionary values must be of type long"];
 }


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
    statistics[`ts]:neg[KDB_DAY_OFFSET]+`timestamp$statistics[`ts]*1000;
    statistics[`time]:neg[KDB_DAY_OFFSET]+`timestamp$1000000000*statistics[`time]
  ];
  if[not `cgrp in key statistics; statistics[`cgrp]:()];
  .kfk.stats,::enlist statistics;
  delete from `.kfk.stats where i<count[.kfk.stats]-100;
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
default_consume_cb:{[msg]}

/
* @brief Callback function for consuming messages triggered by `rd_kafka_consumer_poll()`. Deligated by C function `poll_client`.
* @param client_idx: Index of client (consumer).
* @type
* - int
* @param message: Dictionary containing a message returned by `rd_kafka_consumer_poll()`.
* @type
* - dictionary
\
consume_cb:{[client_idx; message]
  // Call registered callback function for the topic in the message if any; otherwise call default callback function.
  $[null registered_consume_cb:CONSUME_TOPIC_CALLBACK_PER_CLIENT[client_idx; message `topic]; default_consume_cb; registered_consume_cb] message
 };

//%% Client %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Create a client based on a given client type (producer or consumer) and a given configuration.
* @param client_type:
* - "p": Producer
* - "c": Consumer
* @type
* - char
* @param q_config: Dictionary containing a configuration.
* @type
* - dictionary
*   @key symbol
*   @value symbol
* @return
* - error: If passing client type which is neither of "p" or "c". 
* - int: Client index.
\
newClient:LIBPATH_ (`new_client; 2);

/
* @brief Destroy client handle and remove from `CLIENTS`.
* @param client_idx: Index of client in `CLIENTS`.
* @type
* - int
\
deleteClient:LIBPATH_	(`delete_client;1);

//%% Topic %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Create a new topic.
* @param client_idx: index of client in `CLIENTS`.
* @type
* - int
* @param topic: New topic to create.
* @type
* - symbol
* @param q_config: Dictionary storing configuration of the new topic.
* @type
* - dictionary
*   @key symbol: Key of the configuration.
*   @value symbol: Value of the configuration.
* @return
* - int: Topic handle assigned by kafka.
* @note
* Replacement of `.kfk.generateTopic`
\
newTopic:LIBPATH_ (`kfkgenerateTopic; 3);

/
* @brief Delete the given topic.
* @param topic_idx: Index of topic in `TOPICS`.
* @type
* - int
* @note
* Replacement of `.kfk.TopicDel`
\
deleteTopic:LIBPATH_ (`delete_topic; 1);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Public Interface                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Return current version of librdkafka.
* @return
* - int: Version of librdkafka.
* @note
* Replacement of `.kfk.Version`
\
version:LIBPATH_ (`kfkVersion; 1);

// Table with all errors return by kafka with codes and description
Errors:ExportErr[];


//%% Client %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

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


//%% Topic %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

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

//%% Assign %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

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
* - Replacement of `.kfk.assignTopPar`
\
assignNewTopicPartition:LIBPATH_ (`assign_new_topic_partition; 1);

/
* @brief Add pairs of topic and partition to the current assignment for a given lient.
* @param consumer_idx: Index of cient (consumer) in `CLIENTS`.
* @type
* - int
* @param topic_to_part: Dictionary mapping from topic to partition to add.
* @type
* - dictionary
*   @key symbol: Topic name.
*   @value long: Partition ID.
* @note
* Replacement of `.kfk.AssignmentAdd`.
\
addTopicPartition:LIBPATH_ (`add_topic_partion; 2);

/
* @brief Delete pairs of topic and partition from the current assignment for a client.
* @param consumer_idx: Index of cient (consumer) in `CLIENTS`.
* @type
* - int
* @param topic_to_part: Dictionary mapping from topic to partition to delete.
* @type
* - dictionary
*   @key symbol: Topic name.
*   @value long: Partition ID.
* @note
* Replacement of `.kfk.AssignmentDel`.
\
deleteTopicPartition:LIBPATH_ (`delete_topic_partition; 2);

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
commitNewOffsetsToTopicPartition:LIBPATH_ (`kfkCommitOffsets; 4);

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


//%% Configuration %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

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



// projection function for handling int/long lists of partitions for offset functions
osetp:{[cf;x;y;z]
  cf[x;y;$[99h=type z;z;("i"$z,())!count[z]#0]]
  };

// Allow Offset functionality to take topics as a list in z argument
PositionOffsets :osetp[PositionOffsets;;]

// Producer client code
Producer:{
  client:newClient[x;y];
  .kfk.ClientTopicMap,:enlist[client]!enlist ();
  .kfk.ClientTypeMap ,:enlist[client]!enlist[`Producer];
  client}[PRODUCER]

// Consumer client code
Consumer:{
  if[not `group.id in key y;'"Consumers are required to define a `group.id within the config"];
  client:newClient[x;y];
  .kfk.ClientTopicMap,:enlist[client]!enlist ();
  .kfk.ClientTypeMap ,:enlist[client]!enlist[`Consumer];
  client}[CONSUMER]

// Addition of topics and mapping
Topic:{[cid;tname;conf]
  topic:newTopic[cid;tname;conf];
  .kfk.ClientTopicMap[cid],:topic;
  topic
  }

ClientDel:{[cid]
  @[deleteTopic;;()]each ClientTopicMap[cid];
  deleteClient[cid]
  }


/
* @brief Subscribe to a topic from a client, with a defined topic/partition offset and unique callback function
* @param cid: Client index inside `CLIENTS`.
* @type
* - int
* @param topic: Topic to be subscribed
* @type
* - symbol
* @param partition: Partition or partition and offset.
* @type
* - list: Partition list
* - dictionary: Partition/offset dictionary
* @param callback: Callback function to be used for the specified topic.
* @type
* - function
\
Subscribe:{[client_idx;topic;partition;callback]
  Sub[client_idx; topic; partition];
  if[not null callback; CONSUME_TOPIC_CALLBACK_PER_CLIENT[client_idx],::enlist[topic]!enlist callback];
 };


// Assignment API logic

// Assign a new topic-partition dictionary to be consumed by a designated clientid
/* cid    = Integer denoting client ID
/* toppar = Symbol!Long dictionary mapping the name of a topic to an associated partition
Assign:{[cid;toppar]
  i.checkDict[toppar];
  // Create a distinct set of topic-partition pairs to assign,
  // non distinct entries cause a segfault
  toppar:(!). flip distinct(,'/)(key;value)@\:toppar;
  .kfk.assignNewTopicPartition[cid;toppar]
  }

// Assign additional topic-partition pairs which could be consumed from
/* cid    = Integer denoting client ID
/* toppar = Symbol!Long dictionary mapping the name of a topic to an associated partition
AssignAdd:{[cid;toppar]
  tpdict:i.assignCheck[cid;toppar;0b];
  AssignmentAdd[cid;tpdict];
  }

// Remove assigned topic-parition pairs from the current assignment from which data can be consumed
/* cid    = Integer denoting client ID
/* toppar = Symbol!Long dictionary mapping the name of a topic to an associated partition
AssignDel:{[cid;toppar]
  tpdict:i.assignCheck[cid;toppar;1b];
  AssignmentDel[cid;tpdict];
  }


// Retrieval of offset associated with a specified time
/* cid is an integer denoting client id
/* top is the topic which is being queried
/* partoff is a dictionary mapping the partition to the offset being queried
/*   in this case offset can be a long denoting milliseconds since 1970.01.01,
/*   a timestamp or date.
/* tout is the maximum timeout in milliseconds the function will block for
OffsetsForTimes:{[cid;top;partoff;tout]
  if[6h<>type key partoff;'"'partoff' key must be an integer list"];
  offsetType:type value partoff;
  if[not offsetType in(7h;12h;14h);
    '"'partoff' value must be a list of longs, timestamps or dates only"];
  timeOffset:$[14h=offsetType;0t+;]partoff;
  if[7h<>offsetType;timeOffset:floor(`long$timeOffset-1970.01.01D00)%1e6];
  offsetForTime[cid;top;timeOffset;tout]
  }



//%% Callback %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Register error calback function for a client.
* @param client_idx: Index of client in `CLIENTS`.
* @type
* - int
* @param callback: Callback function.
* @type
* - function
\
registerErrorCallback:{[client_idx;callback]
  if[not null callback; ERROR_CALLBACK_PER_CLIENT[client_idx]:callback];
 };

// Registration function allowing throttle callbacks to be set of a per client basis
/
* @brief Register error calback function for a client.
* @param client_idx: Index of client in `CLIENTS`.
* @type
* - int
* @param callback: Callback function.
* @type
* - function
\
registerThrottleCallback:{[client_idx;callback]
  if[not null callback; THROTTLE_CALLBACK_PER_CLIENT[client_idx]:callback];
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
* @brief Set maximum number of polling at execution of `.kfk.poll` function. This number coincides with
*  the number of maximum number of messages to retrieve at the execution of `.kfk.poll` function.
* @param n: The maximum number of polling at execution of `.kfk.manual_poll` function.
* @type
* - long
* @return
* - long: The number set.
\
setMaximumNumberOfPolling:LIBPATH_ (`set_maximum_number_of_polling; 1);


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                  Deprecated Functions                 //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Flags to dispay warning. Use only once.
DEPRECATED_ERRCBREG_USE_FIRST:1b;
DEPRECATED_THROTTLECBREG_USE_FIRST:1b;

/
* @brief Register error calback function for a client.
* @param client_idx: Index of client in `CLIENTS`.
* @type
* - int
* @param callback: Callback function.
* @type
* - function
* @note
* Deprecated. Use `.kfk.registerErrorCallback` instead.
\
errcbreg:{[client_idx;callback]
  if[DEPRECATED_ERRCBREG_USE_FIRST;
    DEPRECATED_ERRCBREG_USE_FIRST::0b;
    -1 "Use of deprecated function: .kfk.errcbreg";
    -1 "Use .kfk.registerErrorCallback instead.";
  ];
  registerErrorCallback[client_idx; callback]
 };

/
* @brief Register error calback function for a client.
* @param client_idx: Index of client in `CLIENTS`.
* @type
* - int
* @param callback: Callback function.
* @type
* - function
* @note
* Deprecated. Use `.kfk.registerErrorCallback` instead.
\
throttlecbreg:{[client_idx;callback]
  if[DEPRECATED_THROTTLECBREG_USE_FIRST;
    DEPRECATED_THROTTLECBREG_USE_FIRST::0b;
    -1 "Use of deprecated function: .kfk.throttlecbreg";
    -1 "Use .kfk.registerThrotteCallback instead.";
  ];
  registerErrorCallback[client_idx; callback]
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      DO NOT EDIT                      //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Close namespace `.kfk`
\d .

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Initialize State                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

.kfk.Init[];
