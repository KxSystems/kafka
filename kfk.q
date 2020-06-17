\d .kfk
LIBPATH:`:libkfk 2:
funcs:(
	  // .kfk.init[]:i
	(`kfkInit;1);
	  // .kfk.Client[client_type:c;conf:S!S]:i
	(`kfkClient;2);
	  // .kfk.ClientDel[client_id:i]:_
	(`kfkClientDel;1);
	  // .kfk.ClientName[client_id:i]:s
	(`kfkClientName;1);
	  // .kfk.ClientMemberId[client_id:i]:s
	(`kfkClientMemberId;1);
	  // .kfk.Topic[client_id:i;topicname:s;conf:S!S]:i
	(`kfkTopic;3);
	  // .kfk.TopicDel[topic_id:i]:_
	(`kfkTopicDel;1);
	  // .kfk.TopicName[topic_id:i]:s
	(`kfkTopicName;1);
	  // .kfk.Metadata[client_id:i]:S!()
	(`kfkMetadata;1);
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
	  // .kfk.MaxMsgsPerPoll[max_messages]
	(`kfkMaxMsgsPerPoll;1);
	  // .kfk.Poll[client_id:i;timeout;max_messages]
	(`kfkPoll;3);
	  // .kfk.Version[]:i
	(`kfkVersion;1);
	  // .kfk.Flush[producer_id:i;timeout_ms:i]:()
	(`kfkFlush;2);
	  // .kfk.ExportErr[]:T
	(`kfkExportErr;1);
	  // .kfk.CommitOffsets[client_id;topic:s;partition_offsets:I!J;async:b]:()
	(`kfkCommitOffsets;4);
	  // .kfk.PositionOffsets[client_id:i;topic:s;partition_offsets:I!J]:partition_offsets
	(`kfkPositionOffsets;3);
	  // .kfk.CommittedOffsets[client_id:i;topic:s;partition_offsets:I!J]:partition_offsets
	(`kfkCommittedOffsets;3);
	  // .kfk.AssignOffsets[client_id:i;topic:s;partition_offsets:I!J]:()
	(`kfkAssignOffsets;3);
          // .kfk.Threadcount[]:i
        (`kfkThreadCount;1);
          // .kfk.VersionSym[]:s
        (`kfkVersionSym;1);
          // .kfk.SetLoggerLevel[client_id:i;int_level:i]:()
        (`kfkSetLoggerLevel;2)
	);

// binding functions from dictionary funcs using rule
// kfk<Name> -> .kfk.<Name>
.kfk,:(`$3_'string funcs[;0])!LIBPATH@/:funcs

Init[];

// Current version of librdkafka
Version:Version[];

// Table with all errors return by kafka with codes and description
Errors:ExportErr[];

// projection function for handling int/long lists of partitions for offset functions
osetp:{[cf;x;y;z]cf[x;y;$[99h=type z;z;("i"$z,())!count[z]#0]]}
// Allow Offset functionality to take topics as a list in z argument
CommittedOffsets:osetp[CommittedOffsets;;]
PositionOffsets :osetp[PositionOffsets;;]

// Unassigned partition.
// The unassigned partition is used by the producer API for messages
// that should be partitioned using the configured or default partitioner.
PARTITION_UA:-1i

// taken from librdkafka.h
OFFSET.BEGINNING:		-2  /**< Start consuming from beginning of kafka partition queue: oldest msg */
OFFSET.END:     		-1  /**< Start consuming from end of kafka partition queue: next msg */
OFFSET.STORED:	 -1000  /**< Start consuming from offset retrieved from offset store */
OFFSET.INVALID:	 -1001  /**< Invalid offset */

// Producer client code
PRODUCER:"p"
Producer:Client[PRODUCER;]

// Consumer client code
CONSUMER:"c"
Consumer:{
  if[not `group.id in key y;'"Consumers are required to define a `group.id within the config"];
  Client[x;y]}[CONSUMER;]

// table with kafka statistics
stats:() 	

// CALLBACKS -  should not be deleted or renamed and be present in .kfk namespace
// https://docs.confluent.io/current/clients/librdkafka/rdkafka_8h.html

// statistics provided by kafka about current state (rd_kafka_conf_set_stats_cb)
statcb:{[j]
	s:.j.k j;if[all `ts`time in key s;s[`ts]:-10957D+`timestamp$s[`ts]*1000;s[`time]:-10957D+`timestamp$1000000000*s[`time]];
	.kfk.stats,::enlist s;
	delete from `.kfk.stats where i<count[.kfk.stats]-100;}

// logger callback(rd_kafka_conf_set_log_cb)
logcb:{[level;fac;buf] show -3!(level;fac;buf);}

// PRODUCER: delivery callback (rd_kafka_conf_set_dr_msg_cb )
drcb:{[cid;msg]}

// CONSUMER: offset commit callback(rd_kafka_conf_set_offset_commit_cb)
offsetcb:{[cid;err;offsets]}

// Default callback for consuming messages if individual topic callbacks not defined(including errors)
consumetopic.:{[msg]}

// Main function called on consumption of data for both default and per topic callback
consumecb:{[msg]$[null f:consumetopic msg`topic;consumetopic.;f]msg}

// Subscribe to a topic from a client, with a defined topic/partition offset and unique callback function
/* cid  = Integer denoting client Id
/* top  = Topic to be subscribed to as a symbol
/* part = Partition list or partition/offset dictionary
/* cb   = callback function to be used for the specified topic
Subscribe:{[cid;top;part;cb]
  Sub[cid;top;part];
  if[not null cb;consumetopic[top]:cb];
  }


// Addition of error callback (rd_kafka_conf_set_error_cb)
/* cid is an integer
/* err_int is an integer code relating to the kafka issue
/* reason is a string denoting the reason for the error
errcb:{[cid;err_int;reason]}

// Triggered callback on non-zero throttle time from a broker (rd_kafka_conf_set_throttle_cb)
/* cid is an integer
/* broker_name is a string
/* broker_id is an integer
/* throttle_time_ms is an integer
throttlecb:{[cid;broker_name;broker_id;throttle_time_ms]}

\d .
