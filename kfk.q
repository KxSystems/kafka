\d .kfk
LIBPATH:`:libkfk 2:
funcs:(
	  // .kfk.init[]:i
	(`kfkInit;1);
	  // .kfk.Client[client_type:c;conf:S!S]:i
	(`kfkClient;2);
	  // .kfk.deleteClient[client_id:i]:_
	(`kfkdeleteClient;1);
	  // .kfk.ClientName[client_id:i]:s
	(`kfkClientName;1);
	  // .kfk.memberId[client_id:i]:s
	(`kfkmemberID;1);
	  // .kfk.generateTopic[client_id:i;topicname:s;conf:S!S]:i
	(`kfkgenerateTopic;3);
	  // .kfk.TopicDel[topic_id:i]:_
	(`kfkTopicDel;1);
	  // .kfk.TopicName[topic_id:i]:s
	(`kfkTopicName;1);
	  // .kfk.Metadata[client_id:i]:S!()
	(`kfkMetadata;1);
	  // .kfk.Pub[topic_id:i;partid:i;data;key]:_
	(`kfkPub;4);
	  // .kfk.PubWithHeaders[client_id:i;topic_id:i;partid:i;data;key;headers]:_
	(`kfkPubWithHeaders;6);
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
        (`kfkSetLoggerLevel;2);
          // .kfk.Assignment[client_id:i]:T
        (`kfkAssignment;1);
          // .kfk.AssignTopPar[client_id:i;topic_partition:S!J]:()
        (`kfkAssignTopPar;2);
          // .kfk.AssignmentAdd[client_id:i;topic_partition:S!J]:()
        (`kfkAssignmentAdd;2);
          // .kfk.AssignmentDel[client_id:i;topic_partition:S!J]:()
        (`kfkAssignmentDel;2);
        // .kfk.OffsetsForTimes[client_id:i;topic:s;partition_offsets:I!J;timeout_ms]:partition_offsets
        (`kfkoffsetForTime;4)
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

// Mapping between client and the topics associated with these clients
ClientTopicMap:(`int$())!()
// Mapping between client and the type of handle created i.e. producer/consumer
ClientTypeMap :(`int$())!`symbol$()

// Producer client code
PRODUCER:"p"
Producer:{
  client:Client[x;y];
  .kfk.ClientTopicMap,:enlist[client]!enlist ();
  .kfk.ClientTypeMap ,:enlist[client]!enlist[`Producer];
  client}[PRODUCER]

// Consumer client code
CONSUMER:"c"
Consumer:{
  if[not `group.id in key y;'"Consumers are required to define a `group.id within the config"];
  client:Client[x;y];
  .kfk.ClientTopicMap,:enlist[client]!enlist ();
  .kfk.ClientTypeMap ,:enlist[client]!enlist[`Consumer];
  client}[CONSUMER]

// Addition of topics and mapping
Topic:{[cid;tname;conf]
  topic:generateTopic[cid;tname;conf];
  .kfk.ClientTopicMap[cid],:topic;
  topic
  }

ClientDel:{[cid]
  @[TopicDel;;()]each ClientTopicMap[cid];
  deleteClient[cid]
  }

// table with kafka statistics
stats:() 	

// CALLBACKS -  should not be deleted or renamed and be present in .kfk namespace
// https://docs.confluent.io/current/clients/librdkafka/rdkafka_8h.html

// statistics provided by kafka about current state (rd_kafka_conf_set_stats_cb)
statcb:{[j]
  s:.j.k j;
  if[all `ts`time in key s;
    s[`ts]:-10957D+`timestamp$s[`ts]*1000;
    s[`time]:-10957D+`timestamp$1000000000*s[`time]
    ];
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


// Retrieve the client member id associated with an assigned consumer
/* cid    = Integer denoting client ID
ClientMemberId:{[cid]
  if[`Producer~ClientTypeMap[cid];'".kfk.ClientMemberID cannot be called on Producer clients"];
  memberID[cid]
  }


// Assignment API logic

// Assign a new topic-partition dictionary to be consumed by a designated clientid
/* cid    = Integer denoting client ID
/* toppar = Symbol!Long dictionary mapping the name of a topic to an associated partition
Assign:{[cid;toppar]
  i.checkDict[toppar];
  // Create a distinct set of topic-partition pairs to assign,
  // non distinct entries cause a segfault
  toppar:(!). flip distinct(,'/)(key;value)@\:toppar;
  AssignTopPar[cid;toppar]
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


// Handling of error callbacks (rd_kafka_conf_set_error_cb)
/* cid is an integer
/* err_int is an integer code relating to the kafka issue
/* reason is a string denoting the reason for the error

// Default callback for the handling of errors 
errclient.:{[cid;err_int;reason]}
// Main function for the handling of error callbacks
errcb:{[cid;err_int;reason]$[null f:errclient`$string cid;errclient.;f].(cid;err_int;reason)}
// Registration function allowing error callbacks to be added on a per client basis
errcbreg:{[cid;cb]if[not null cb;errclient[`$string cid]:cb];}


// Handling of throttle callbacks (rd_kafka_conf_set_throttle_cb)
/* cid is an integer denoting the client id from which the callback is triggered
/* bname is a string denoting the name of the broker
/* bid is an integer denoting the broker id
/* throttle_time is an integer denoting the non-zero throttle time that triggered the callback

// Default callback for the handling of throttle events
throttleclient.:{[cid;bname;bid;throttle_time]}
// Main function for the handling of throttle events
throttlecb:{[cid;bname;bid;throttle_time]
  $[null f:throttleclient`$string cid;throttleclient.;f].(cid;bname;bid;throttle_time)
  }
// Registration function allowing throttle callbacks to be set of a per client basis
throttlecbreg:{[cid;cb]if[not null cb;throttleclient[`$string cid]:cb];}


\d .
