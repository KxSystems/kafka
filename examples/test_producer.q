\l ../kfk.q
kfk_cfg:(!) . flip(
  (`metadata.broker.list;`localhost:9092);
  (`statistics.interval.ms;`10000);
  (`queue.buffering.max.ms;`1);
  (`fetch.wait.max.ms;`10)
  );
producer:.kfk.Producer[kfk_cfg]
test_topic:.kfk.Topic[producer;`test;()!()]

.z.ts:{.kfk.Pub[test_topic;.kfk.PARTITION_UA;string x;""]}
show "Publishing on topic:",string .kfk.TopicName test_topic;
.kfk.Pub[test_topic;.kfk.PARTITION_UA;string .z.p;""];
show "Published 1 message";
producer_meta:.kfk.Metadata[producer];
show producer_meta`topics;
show "Set timer with \\t 1000 to publish message every second";

