//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file idle_consumer.q
// @fileoverview
// Example consumer who does not decode messages with pipelines.

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

// Table to store received data.
data1:();
data2:();

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\c 25 200

// Create pipelines used for decoding
.qtfm.createNewPipeline[`slowth];
.qtfm.addDeserializationLayer[`slowth; .qtfm.NONE; (::)];
.qtfm.compile[`slowth];

// Create a consumer.
consumer:.kafka.newConsumer[kfk_cfg; 5000i; `slowth];

// Get pipeline map
pipeline_map: .kafka.getPipelinePerClient[];
show pipeline_map;

// Topics to subscribe to
topic1:`test1;
topic2:`test2;

// Define datasets and topic callbacks for individual
// topic subscriptions `topic1 and `topic2
topic_cb1:{[consumer;msg]
  msg[`rcvtime]:.z.p;
  if[`headers in key msg; msg[`headers]: "c"$msg[`headers]];
  data1,: enlist key msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b];
 };

topic_cb2:{[consumer;msg]
  msg[`rcvtime]:.z.p;
  if[`headers in key msg; msg[`headers]: "c"$msg[`headers]];
  data2,: enlist key msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b];
 };

.kafka.offset_commit_cb:{[consumer_idx;error;offsets]
  $[
    error ~ "Success";
    -1 "committed:", .Q.s1 offsets;
    -2 "commit error: ", error
  ];
 };

// Subscribe to topic1 and topic2 with different callbacks from a single client
.kafka.subscribe[consumer;topic1];
.kafka.subscribe[consumer;topic2];

// Register callback functions for the topic.
.kafka.registerConsumeTopicCallback[consumer; topic1; topic_cb1 consumer];
.kafka.registerConsumeTopicCallback[consumer; topic2; topic_cb2 consumer];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

client_meta:.kafka.getBrokerTopicConfig[consumer; 5000i];

show client_meta`topics;