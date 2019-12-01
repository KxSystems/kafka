\l ../kfk.q
kfk_cfg:(!) . flip(
  (`metadata.broker.list;`localhost:9092);
  (`statistics.interval.ms;`10000);
  (`queue.buffering.max.ms;`1);
  (`fetch.wait.max.ms;`10)
  );
producer:.kfk.Producer[kfk_cfg]

topic1:.kfk.Topic[producer;`test1;()!()]
topic2:.kfk.Topic[producer;`test2;()!()]

.z.ts:{n+:1;topic:$[n mod 2;topic1;topic2];
       .kfk.Pub[topic;.kfk.PARTITION_UA;string x;""]}



-1 "Publishing on topics:",string[.kfk.TopicName topic1],", ",string[.kfk.TopicName topic2];
.kfk.Pub[;.kfk.PARTITION_UA;string .z.p;""]each(topic1;topic2);
-1 "Published one message for each topic";
producer_meta:.kfk.Metadata[producer];
show producer_meta`topics;
-1 "Set timer with \\t 500 to publish a message each second to each topic.";

