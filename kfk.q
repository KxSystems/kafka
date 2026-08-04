libFuncs:use`.clib;

// Current version of librdkafka
Version:libFuncs.Version[];

// Table with all errors return by kafka with codes and description
Errors:libFuncs.ExportErr[];

// projection function for handling int/long lists of partitions for offset functions
osetp:{[cf;x;y;z]cf[x;y;$[99h=type z;z;("i"$z,())!count[z]#0]]}
// Allow Offset functionality to take topics as a list in z argument
CommittedOffsets:osetp[libFuncs.CommittedOffsets;;]
PositionOffsets :osetp[libFuncs.PositionOffsets;;]

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
GetClientTopicMap: {ClientTopicMap}
// Mapping between client and the type of handle created i.e. producer/consumer
ClientTypeMap :(`int$())!`symbol$()
GetClientTypeMap: {ClientTypeMap}

// Producer client code
PRODUCER:"p"
Producer:{
  client:libFuncs.Client[x;y];
  ClientTopicMap,:enlist[client]!enlist ();
  ClientTypeMap ,:enlist[client]!enlist[`Producer];
  client}[PRODUCER]

// Consumer client code
CONSUMER:"c"
Consumer:{
  if[not `group.id in key y;'"Consumers are required to define a `group.id within the config"];
  client:libFuncs.Client[x;y];
  ClientTopicMap,:enlist[client]!enlist ();
  ClientTypeMap ,:enlist[client]!enlist[`Consumer];
  client}[CONSUMER]

// Addition of topics and mapping
Topic:{[cid;tname;conf]
  topic:libFuncs.generateTopic[cid;tname;conf];
  ClientTopicMap[cid],:topic;
  topic
  }

ClientDel:{[cid]
  @[libFuncs.TopicDel;;()]each ClientTopicMap[cid];
  libFuncs.deleteClient[cid]
  }

// table with kafka statistics
stats:()
GetStats:{stats}

// CALLBACKS
// https://docs.confluent.io/current/clients/librdkafka/rdkafka_8h.html

// statistics provided by kafka about current state (rd_kafka_conf_set_stats_cb)
statcb:{[j]
  s:.j.k j;
  if[all `ts`time in key s;
    s[`ts]:-10957D+`timestamp$s[`ts]*1000;
    s[`time]:-10957D+`timestamp$1000000000*s[`time]
    ];
  if[not `cgrp in key s;s[`cgrp]:()];
  .z.m.stats,:enlist s;
  delete from .z.M.stats where i<count[.z.m.stats]-100;}

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

SetTopicCb: {[topic;cb] consumetopic[topic]:cb}

// Subscribe to a topic from a client, with a defined topic/partition offset and unique callback function
/* cid  = Integer denoting client Id
/* top  = Topic to be subscribed to as a symbol, or list of topics (as symbol list)
/* part = Partition list or partition/offset dictionary (depreciated / unused)
/* cb   = callback function to be used for the specified topic
Subscribe:{[cid;top;part;cb]
  libFuncs.Sub[cid;top;part];
  if[all not null cb;if[(count top)<>count cb;'"Subscribe callback needed for each topic"];consumetopic[top]:cb];
  }


// Retrieve the client member id associated with an assigned consumer
/* cid    = Integer denoting client ID
ClientMemberId:{[cid]
  if[`Producer~ClientTypeMap[cid];'"ClientMemberID cannot be called on Producer clients"];
  libFuncs.memberID[cid]
  }


// Assignment API logic

// Run assignment of a topic to a particular partition making
/* cid      = Integer denoting the client ID
/* top      = Topic to be subscribed to as a symbol
/* partoff  = Dictionary mapping integer partition to long offset location
AssignOffsets:{[cid;top;partoff]
  toppar:(count[partoff]#top)!key partoff;
  tplist:distinct(,'/)(key;{"j"$value x})@\:toppar;
  // Find locations where the current assigment needs to be overwritten
  loc:where i.compAssign[cid;tplist];
  if[count loc;
    currentAssign:(!). flip tplist loc;
    AssignDel[cid;currentAssign]
    ];
  libFuncs.assignOffsets[cid;top;partoff]
  }

i.checkOffsetDict:{[dict]
  if[not all 99h=type each dict;'"Partition info must be of type  dictionary"];
  if[not all 6h=type each key each dict;'"Partition dictionary key must of type int"];
  if[not all 7h=type each value each dict;'"Partition dictionary values must be of type long"];
  }
// Assign a new topic-partition dictionary to be consumed by a designated clientid
/* cid    = Integer denoting client ID
/* toppar = Symbol!Long dictionary mapping the name of a topic to an associated partition or Symbol!Dictionary mapping of topic to partitions/offset (dictionary mapping of integer partition to long offset location)
Assign:{[cid;toppar]
  if[not 99h=type toppar      ;'"Final parameter must be a dictionary"];
  if[not 11h=type key toppar  ;'"Dictionary key must of type symbol"];
  if[2=(7h;0h)?type value toppar;'"Dictionary values must be of type long or a list"];
  // Create a distinct set of topic-partition pairs to assign,
  // non distinct entries cause a segfault
  if[7h=type value toppar;toppar:(!). flip distinct(,'/)(key;value)@\:toppar;]
  if[0h=type value toppar;i.checkOffsetDict[value toppar];if[(count distinct a)<>count a:raze key[toppar],/:'key each value toppar;'"Topic and Partition mapping not unique"];]
  libFuncs.AssignTopPar[cid;toppar]
  }

// Assign additional topic-partition pairs which could be consumed from
/* cid    = Integer denoting client ID
/* toppar = Symbol!Long dictionary mapping the name of a topic to an associated partition
AssignAdd:{[cid;toppar]
  tpdict:i.assignCheck[cid;toppar;0b];
  libFuncs.AssignmentAdd[cid;tpdict];
  }

// Remove assigned topic-parition pairs from the current assignment from which data can be consumed
/* cid    = Integer denoting client ID
/* toppar = Symbol!Long dictionary mapping the name of a topic to an associated partition
AssignDel:{[cid;toppar]
  tpdict:i.assignCheck[cid;toppar;1b];
  libFuncs.AssignmentDel[cid;tpdict];
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
  libFuncs.offsetForTime[cid;top;timeOffset;tout]
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
  assignment:libFuncs.Assignment[cid];
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
/* errInt is an integer code relating to the kafka issue
/* reason is a string denoting the reason for the error

// Default callback for the handling of errors 
errclient.:{[cid;errInt;reason]}
// Main function for the handling of error callbacks
errcb:{[cid;errInt;reason]$[null f:errclient`$string cid;errclient.;f].(cid;errInt;reason)}
// Registration function allowing error callbacks to be added on a per client basis
SetPerClientErrorCb:{[cid;cb]if[not null cb;errclient[`$string cid]:cb];}


// Handling of throttle callbacks (rd_kafka_conf_set_throttle_cb)
/* cid is an integer denoting the client id from which the callback is triggered
/* bname is a string denoting the name of the broker
/* bid is an integer denoting the broker id
/* throttleTime is an integer denoting the non-zero throttle time that triggered the callback

// Default callback for the handling of throttle events
throttleclient.:{[cid;bname;bid;throttleTime]}
// Main function for the handling of throttle events
throttlecb:{[cid;bname;bid;throttleTime]
  $[null f:throttleclient`$string cid;throttleclient.;f].(cid;bname;bid;throttleTime)
  }
// Registration function allowing throttle callbacks to be set of a per client basis
SetPerClientThrottleCb:{[cid;cb]if[not null cb;throttleclient[`$string cid]:cb];}

ResetStatCb: {libFuncs.SetStatCb[statcb];}
ResetLogCb: {libFuncs.SetLogCb[logcb];}
ResetOffsetCb: {libFuncs.SetOffsetCb[offsetcb];}
ResetDeliveryCb: {libFuncs.SetDeliveryCb[drcb];}
ResetErrorCb: {libFuncs.SetErrorCb[errcb];}
ResetThrottleCb: {libFuncs.SetThrottleCb[throttlecb];}
ResetConsumeCb: {libFuncs.SetConsumeCb[consumecb];}

ResetStatCb[];
ResetLogCb[];
ResetOffsetCb[];
ResetDeliveryCb[];
ResetErrorCb[];
ResetThrottleCb[];
ResetConsumeCb[];
libFuncs.Init[];

export:([Version;Errors;CommittedOffsets;PositionOffsets;PARTITION_UA;GetClientTopicMap;GetClientTypeMap;
         Producer;Consumer;Topic;ClientDel;GetStats;SetTopicCb;Subscribe;ClientMemberId;AssignOffsets;Assign;
         AssignAdd;AssignDel;OffsetsForTimes;SetPerClientThrottleCb;SetPerClientErrorCb;ResetStatCb;ResetLogCb;ResetOffsetCb;
         ResetDeliveryCb;ResetErrorCb;ResetThrottleCb;ResetConsumeCb;OFFSET]),`Version _ libFuncs;
