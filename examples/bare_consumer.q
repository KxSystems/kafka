//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file bare_consumer.q
// @fileoverview
// Example consumer for kafkakdb not linked with transformer. If `schema_id` is not included in a header of
//  a message, it is automatically counted as non-schema-registry message and then passed through as it is
//  (string or bytes).

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Library                      //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l ../q/kafka.q

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Configuration
kfk_cfg:(!) . flip(
    (`metadata.broker.list;`localhost:9092);
    (`group.id;`0);
    (`fetch.wait.max.ms;`10);
    (`statistics.interval.ms;`10000);
    (`enable.auto.commit; `false);
    (`api.version.request; `true)
  );

data1: ();
data2: ();

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Create a consumer. WIthout transformer, pass `(::)` for the pipeline name.
consumer:.kafka.newConsumer[kfk_cfg; 5000i];

// Topics to subscribe to
topic1:`test1;
topic2:`test2;

// Define datasets and topic callbacks for individual topic subscriptions `test1 and `test2
topic_cb1:{[consumer;msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.p;
  if[`headers in key msg; msg[`headers]: "c"$msg[`headers]];
  data1,:enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b];
 };

topic_cb2:{[consumer;msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.t;
  if[`headers in key msg; msg[`headers]: "c"$msg[`headers]];
  data2,:enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b];
 };

// Callback for committing an offset
.kafka.offset_commit_cb:{[consumer_idx;error;offsets]
  $[
    error ~ "Success";
    -1 "committed:", .Q.s1 offsets;
    -2 "commit error: ", error
  ];
 };

// Subscribe to topic1 and topic2 with different callbacks from a single client
.kafka.subscribe[consumer; topic1];
.kafka.subscribe[consumer; topic2];

// Register callback functions for the topic.
.kafka.registerConsumeTopicCallback[consumer; topic1; topic_cb1 consumer];
.kafka.registerConsumeTopicCallback[consumer; topic2; topic_cb2 consumer];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

consumer_meta: .kafka.getBrokerTopicConfig[consumer; 5000i];

show consumer_meta `topics;
