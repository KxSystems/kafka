//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @file test_stage1.q
* @fileoverview
* Conduct tests until subscription is done.
* @note The location of kafka broker director where `bin/` is included must be set on `KAFKA_BROKER_HOME`.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Initial Setting                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\c 50 200
\l test_helper_function.q

// Delete existing topic
@[system; getenv[`KAFKA_BROKER_HOME], "/bin/kafka-topics.sh --bootstrap-server localhost:9092 --topic topic1 --delete"; {[error] show error}];
@[system; getenv[`KAFKA_BROKER_HOME], "/bin/kafka-topics.sh --bootstrap-server localhost:9092 --topic topic2 --delete"; {[error] show error}];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Load Library                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l ../q/kafka.q

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

consumer_configuration: .[!] flip(
  (`metadata.broker.list;`localhost:9092);
  (`group.id;`0);
  (`fetch.wait.max.ms;`10);
  (`statistics.interval.ms;`10000);
  (`enable.auto.commit; `false);
  (`api.version.request; `true)
  );

producer_configuration: .[!] flip(
  (`metadata.broker.list;`localhost:9092);
  (`statistics.interval.ms;`10000);
  (`queue.buffering.max.ms;`1);
  (`fetch.wait.max.ms;`10);
  (`api.version.request; `true)
  );

consumer_table1: ();
consumer_table2: ();

topic_callback1:{[consumer;msg]
  msg[`rcvtime]:.z.p;
  msg[`data]:"c"$msg[`data];
  msg[`key]:"c"$msg[`key];
  msg[`headers]:"c"$msg[`headers];
  consumer_table1,:enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b]
 };

topic_callback2:{[consumer;msg]
  msg[`rcvtime]:.z.p;
  msg[`data]:"c"$msg[`data];
  msg[`key]:"c"$msg[`key];
  msg[`headers]:"c"$msg[`headers];
  consumer_table2,:enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b]
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                          Tests                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

if[USE_TRANSFORMER_;
  .qtfm.createNewPipeline[`idle];
  .qtfm.addSerializationLayer[`idle; .qtfm.NONE; (::)];
  .qtfm.compile[`idle]
 ];

// Create a consumer
consumer: .kafka.newConsumer[consumer_configuration; 5000i; $[USE_TRANSFORMER_; `idle; (::)]];

// Create a producer
producer: .kafka.newProducer[producer_configuration; 5000i; $[USE_TRANSFORMER_; `idle; (::)]];

// Register error callback.
.kafka.registerErrorCallback[producer; {[client_idx;error_code;reason] show "Oh no!! Error happenned due to :", reason, "!";}] 

// Create topics
topic1:.kafka.newTopic[producer; `topic1; ()!()];
topic2:.kafka.newTopic[producer; `topic2; ()!()];

.test.ASSERT_EQ["get topic name 1"; .kafka.getTopicName topic1; `topic1]
.test.ASSERT_EQ["get topic name 2"; .kafka.getTopicName topic2; `topic2]

.test.ASSERT_EQ["register topics"; .kafka.PRODUCER_TOPIC_MAP; enlist[producer]!enlist (topic1; topic2)]

// Register callback functions for the consumer
.kafka.registerConsumeTopicCallback[consumer; `topic1; topic_callback1 consumer];
.kafka.registerConsumeTopicCallback[consumer; `topic2; topic_callback2 consumer];

system "sleep 2";

while[not all `topic1`topic2 in (asc exec topic from .kafka.getBrokerTopicConfig[consumer; 5000i] `topics) except `$"__consumer_offsets"; system "sleep 1"];

// Subscribe to topic1 and topic2.
.kafka.subscribe[consumer; `topic1];
.kafka.subscribe[consumer; `topic2];

// Rebalancing will happen at the initial subscription.
while[0 = count .kafka.getCurrentAssignment[consumer]; system "sleep 5"];

// Expected assignment information
current_assignment: flip `topic`partition`offset`metadata!(`topic1`topic2; 0 0i; 2#-1001; 2#enlist "");

.test.ASSERT_EQ["initial assignment"; .kafka.getCurrentAssignment[consumer]; current_assignment]

// Expected subscription information
current_subscription: flip `topic`partition`offset`metadata!(`topic1`topic2; 2#0 0i; 2#-1001; 2#enlist "");

.test.ASSERT_EQ["subscription config"; .kafka.getCurrentSubscription[consumer]; current_subscription]

// Add topic-partition 2 for topic1.
.kafka.addTopicPartitionToAssignment[consumer; enlist[`topic1]!enlist 1i];

// Expected assignment information
current_assignment: flip `topic`partition`offset`metadata!(`topic1`topic1`topic2; 0 1 0i; 3#-1001; 3#enlist "");

.test.ASSERT_EQ["add partition 2 to topic1"; .kafka.getCurrentAssignment[consumer]; current_assignment]

// Delete topic-partition 2 from topic1.
.kafka.deleteTopicPartitionFromAssignment[consumer; enlist[`topic1]!enlist 1i];

// Expected assignment information
current_assignment: flip `topic`partition`offset`metadata!(`topic1`topic2; 0 0i; 2#-1001; 2#enlist "");

.test.ASSERT_EQ["delete partition 2 from topic1"; .kafka.getCurrentAssignment[consumer]; current_assignment]

// To be continued to test_stage_2.q
// Once q) console appeared, execute test_stage2.q line by line...
