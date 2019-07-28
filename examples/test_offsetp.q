\l ../kfk.q
kfk_cfg:(!) . flip(
  (`metadata.broker.list;`localhost:9092);
  (`statistics.interval.ms;`10000);
  (`queue.buffering.max.ms;`1);
  (`fetch.wait.max.ms;`10)
  );
producer:.kfk.Producer[kfk_cfg]
test_topic:.kfk.Topic[producer;`test;()!()]

.kfk.drcb:{[cid;msg]show "Delivered msg on ",string[cid],": ",.Q.s1 msg;}


.z.ts:{.kfk.Pub[test_topic;0i;string x;""]}
show "Publishing on topic:",string .kfk.TopicName test_topic;
.kfk.Pub[test_topic;0i;string .z.p;""];
show "Published 1 message";
show "Set timer with \\t 1000 to publish message every second";

