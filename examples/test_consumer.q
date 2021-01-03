\l ../q/kfk.q

kfk_cfg:(!) . flip(
    (`metadata.broker.list;`localhost:9092);
    (`group.id;`0);
    (`fetch.wait.max.ms;`10);
    (`statistics.interval.ms;`10000)
    );
consumer:.kfk.newConsumer[kfk_cfg];

// Topics to subscribe to
topic1:`test1; topic2:`test2;

// Define datasets and topic callbacks for individual
// topic subscriptions `topic1 and `topic2
data1:();
topic_cb1:{[msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.p;
  data1,::enlist msg;
 };

data2:();
topic_cb2:{[msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.t;
  data2,::enlist msg;
 };

// Subscribe to topic1 and topic2 with different callbacks from a single client
.kfk.subscribe[consumer;topic1;enlist .kfk.PARTITION_UA];
.kfk.subscribe[consumer;topic2;enlist .kfk.PARTITION_UA];

.kfk.registerConsumeTopicCallback[consumer; topic1; topic_cb1];
.kfk.registerConsumeTopicCallback[consumer; topic2; topic_cb2];

client_meta:.kfk.getBrokerTopicConfig[consumer];

show client_meta`topics;
