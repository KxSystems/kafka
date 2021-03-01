//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @file test_stage1.q
* @fileoverview
* Conduct tests until subscription is done.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Initial Setting                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\c 50 200
\l test_helper_function.q

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
    (`statistics.interval.ms;`10000)
  );

producer_configuration: .[!] flip(
  (`metadata.broker.list;`localhost:9092);
  (`statistics.interval.ms;`10000);
  (`queue.buffering.max.ms;`1);
  (`fetch.wait.max.ms;`10)
  );

consumer_table1: ();
consumer_table2: ();

topic_callback1:{[msg]
  msg[`rcvtime]:.z.p;
  msg[`data]:"c"$msg[`data];
  msg[`key]:"c"$msg[`key];
  msg[`headers]:"c"$msg[`headers];
  consumer_table1,::enlist msg;
 };

topic_callback2:{[msg]
  msg[`rcvtime]:.z.p;
  msg[`data]:"c"$msg[`data];
  msg[`key]:"c"$msg[`key];
  msg[`headers]:"c"$msg[`headers];
  consumer_table2,::enlist msg;
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                          Tests                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Create a consumer
consumer: .kafka.newConsumer[consumer_configuration];

// Create a producer
producer: .kafka.newProducer[producer_configuration];

// Create topics
topic1:.kafka.newTopic[producer; `topic1; ()!()];
topic2:.kafka.newTopic[producer; `topic2; ()!()];

.test.ASSERT_EQ[.kafka.getTopicName topic1; `topic1]
.test.ASSERT_EQ[.kafka.getTopicName topic2; `topic2]

// Register callback functions for the consumer
.kafka.registerConsumeTopicCallback[consumer; `topic1; topic_callback1];
.kafka.registerConsumeTopicCallback[consumer; `topic2; topic_callback2];

// Get current visible topic configuration for the consumer
consumer_topic_config:.kafka.getBrokerTopicConfig[consumer];

.test.ASSERT_EQ[(asc exec topic from consumer_topic_config `topics) except `$"__consumer_offsets"; `topic1`topic2]

// Subscribe to topic1 and topic2.
.kafka.subscribe[consumer; `topic1; enlist .kafka.PARTITION_UA];
.kafka.subscribe[consumer; `topic2; enlist .kafka.PARTITION_UA];

// Rebalancing will happen at the initial subscription.
while[0 = count .kafka.getCurrentAssignment[consumer]; system "sleep 5"];

// Expected assignment information
current_assignment: flip `topic`partition`offset`metadata!(`topic1`topic1`topic2`topic2; 0 1 0 1i; 4#-1001; 4#enlist "");

.test.ASSERT_EQ[.kafka.getCurrentAssignment[consumer]; current_assignment]

// Expected subscription information
current_subscription: flip `topic`partition`offset`metadata!(`topic1`topic2; 2#-1i; 2#-1001; 2#enlist "");

.test.ASSERT_EQ[.kafka.getCurrentSubscription[consumer]; current_subscription]

// Add topic-partition 2 for topic1.
.kafka.addTopicPartition[consumer; enlist[`topic1]!enlist 2i];

// Expected assignment information
current_assignment: flip `topic`partition`offset`metadata!(`topic1`topic1`topic1`topic2`topic2; 0 1 2 0 1i; 5#-1001; 5#enlist "");

.test.ASSERT_EQ[.kafka.getCurrentAssignment[consumer]; current_assignment]

// Delete topic-partition 2 from topic1.
.kafka.deleteTopicPartition[consumer; enlist[`topic1]!enlist 2i];

// Expected assignment information
current_assignment: flip `topic`partition`offset`metadata!(`topic1`topic1`topic2`topic2; 0 1 0 1i; 4#-1001; 4#enlist "");

.test.ASSERT_EQ[.kafka.getCurrentAssignment[consumer]; current_assignment]

// To be continued to test_stage_2.q
// Once q) console appeared, execute test_stage2.q line by line...
