//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file kafka_deprecated.q
// @fileoverview
// Define deprecated functions. These functions will be removed at v2.1.0.

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
.kfk.Consumer: .kafka.newConsumer;
.kfk.Producer: .kafka.newProducer;
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
.kfk.Metadata: .kafka.getBrokerTopicConfig;
.kfk.Version: .kafka.version;
.kfk.VersionSym:{[]
  `$.kafka.versionString[]
 };
.kfk.ThreadCount: .kafka.getKafkaThreadCount;

//%% Callback %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// Simply redirect to old nameed functions.
.kafka.log_cb::.kfk.logcb;
.kafka.dr_msg_cb::.kfk.drcb;
.kafka.offset_commit_cb::.kfk.offsetcb;
.kafka.default_consume_topic_cb::.kfk.consumetopic.;
.kafka.default_error_cb::.kfk.errclient.;
.kafka.default_throttle_cb::.kfk.throttleclient.;

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
 