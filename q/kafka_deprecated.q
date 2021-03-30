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
 }
.kfk.ThreadCount: .kafka.getKafkaThreadCount;

//%% Table %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

.kfk.stats::.kafka.STATISTICS;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                 Unsupported Functions                 //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* Callback funtion for a topic is tied with the client in an internal mapping.
*  Use `.kafka.registerConsumeTopicCallback` to set a callback for the client-topic pair.
\
// .kfk.Subscribe

/
* Use `.kafka.log_cb`.
\
// .kfk.logcb

/
* Use `.kafka.dr_msg_cb`.
\
// .kfk.drcb

/
* Use `.kafka.offset_commit_cb`.
\
// .kfk.offsetcb

/
* Use `.kafka.default_consume_topic_cb`.
\
// .kfk.consumetopic

/
* Use `.kafka.default_error_cb`.
\
// .kfk.errcbreg

/
* Use .kafka.default_throttle_cb
\
// .kfk.throttlecbreg

/
* Manuall polling is not provided as polling is done in background. 
\
// .kfk.MaxMsgsPerPoll
// .kfk.Poll: .kafka.manualPoll
 