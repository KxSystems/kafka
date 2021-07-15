//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file kafka_deprecated.q
// @fileoverview
// Define deprecated functions. These functions will be removed at v2.1.0.
// @note
// This file is assuming transformer is not linked to the kafkakdb, meaning we can pass
//  `(::)` for `pipeline_name` when creating a client.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Public Interface                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Functions %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

.kfk.Init: .kafka.init;
.kfk.Topic: .kafka.newTopic;
.kfk.TopicDel: .kafka.deleteTopic;
.kfk.TopicName: .kafka.getTopicName;
.kfk.errcbreg: .kafka.registerErrorCallback;
.kfk.throttlecbreg: .kafka.registerThrottleCallback;
.kfk.ClientDel: .kafka.deleteClient;
.kfk.ClientName: .kafka.getClientName;
.kfk.ClientMemberId: .kafka.getConsumerGroupMemberID;
.kfk.Consumer:{[config]
  .kafka.newConsumer[config; 5000i; (::)]
 };
.kfk.Producer:{[config]
  .kafka.newProducer[config; 5000i; (::)]
 };
.kfk.SetLoggerLevel: .kafka.setLogLevel;
.kfk.CommitOffsets: .kafka.commitOffsetsToTopicPartition;
.kfk.PositionOffsets: .kafka.getPrevailingOffsets;
.kfk.CommittedOffsets: .kafka.getCommittedOffsetsForTopicPartition;
.kfk.AssignOffsets: .kafka.assignNewOffsetsToTopicPartition;
.kfk.offsetForTimes: .kafka.getEarliestOffsetsForTimes;
.kfk.BatchPub: .kafka.publishBatch;
.kfk.Pub: .kafka.publish;
.kfk.PubWithHeaders:.kafka.publishWithHeaders;
.kfk.OutQLen: .kafka.getOutQueueLength;
.kfk.Sub:{[consumer_idx;topic;partition_to_offset_]
  .kafka.subscribe[consumer_idx; topic]
 };
.kfk.Subscribe:{[consumer_idx;topic;partition_to_offset_;callback]
  .kafka.subscribe[consumer_idx; topic];
  .kafka.registerConsumeTopicCallback[consumer_idx; topic; callback];
 }
.kfk.Subscription: .kafka.getCurrentSubscription;
.kfk.Unsub: .kafka.unsubscribe;
.kfk.Assign:{[consumer_idx;topic_to_partiton]
  // convert partitions from long to int
  topic_to_partiton: key[topic_to_partiton]!`int$value topic_to_partiton;
  .kafka.assignNewTopicPartition;[consumer_idx; topic_to_partiton]
 };
.kfk.AssignAdd: .kafka.addTopicPartitionToAssignment;
.kfk.AssignDel: .kafka.deleteTopicPartitionFromAssignment;
.kfk.Assignment: .kafka.getCurrentAssignment;
.kfk.Metadata:{[client_idx]
  .kafka.getBrokerTopicConfig[client_idx; 5000i]
 };
.kfk.Version: .kafka.version;
.kfk.VersionSym:{[]
  `$.kafka.versionString[]
 };
.kfk.ThreadCount: .kafka.getKafkaThreadCount;

//%% Callback %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// Old default definitions
.kfk.logcb:{[level;fac;buf] -1 .Q.s1 (level;fac;buf);};
.kfk.drcb:{[producer_idx;message]};
.kfk.offsetcb:{[consumer_idx;error;offsets]};
.kfk.consumetopic.:{[message]};
.kfk.errclient.:{[client_idx;error_code;reason]};
.kfk.throttleclient.:{[client_idx;broker_name;broker_id;throttle_time_ms]};

/
* As `.kfk.statcb` is private, KX are reluctant to redirect. Only its artefact
*  `.kfk.stats` is available to users.
\

//%% Table %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

.kfk.stats::.kafka.STATISTICS;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                 Unsupported Functions                 //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* Manuall polling is not provided as polling is done in background. 
\
// .kfk.MaxMsgsPerPoll
// .kfk.Poll: .kafka.manualPoll
 