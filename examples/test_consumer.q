\l ../q/kafka.q

kfk_cfg:(!) . flip(
    (`metadata.broker.list;`localhost:9092);
    (`group.id;`0);
    (`fetch.wait.max.ms;`10);
    (`statistics.interval.ms;`10000);
    (`enable.auto.commit; `false)
    );
consumer:.kafka.newConsumer[kfk_cfg; 5000];

// Topics to subscribe to
topic1:`test1; topic2:`test2;

// Define datasets and topic callbacks for individual
// topic subscriptions `topic1 and `topic2
data1:();
topic_cb1:{[consumer;msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.p;
  data1,::enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b]
 };

data2:();
topic_cb2:{[consumer;msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.t;
  data2,::enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b]
 };

// Subscribe to topic1 and topic2 with different callbacks from a single client
.kafka.subscribe[consumer;topic1];
.kafka.subscribe[consumer;topic2];

.kafka.registerConsumeTopicCallback[consumer; topic1; topic_cb1 consumer];
.kafka.registerConsumeTopicCallback[consumer; topic2; topic_cb2 consumer];

client_meta:.kafka.getBrokerTopicConfig[consumer];

show client_meta`topics;
