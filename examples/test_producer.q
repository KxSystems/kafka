\l ../kfk.q

kfk_cfg:(!) . flip(
  (`metadata.broker.list;`localhost:9092);
  (`statistics.interval.ms;`10000);
  (`queue.buffering.max.ms;`1)
  );
producer:.kfk.Producer[kfk_cfg]

topic1:.kfk.Topic[producer;`test1;()!()]
topic2:.kfk.Topic[producer;`test2;()!()]

.z.ts:{n+:1;topic:$[n mod 2;topic1;topic2];
       .kfk.Pub[topic;.kfk.PARTITION_UA;string x;""]}

printver:{
  -1 "==== librdkafka version ==============================";
  -1 "." sv 2 cut -8$"0123456789abcdef" 16 vs .kfk.Version;}

printmeta:{
  -1 "==== MetaData provided by the following broker =======";
  -1 "name:",string x`orig_broker_name;
  -1 "id:",string x`orig_broker_id;
  -1 "==== Brokers =========================================";
  show each x`brokers;
  -1 "==== Topics ==========================================";
  $[count x`topics;show each x`topics;-1 "[None]"];
  -1 "";}

printver[];
printmeta .kfk.Metadata[producer];

-1 "Publishing single msg on topics: ",string[.kfk.TopicName topic1],", ",string[.kfk.TopicName topic2];
.kfk.Pub[;.kfk.PARTITION_UA;string .z.p;""]each(topic1;topic2);
-1 "Set timer with \\t 500 to publish a message every 1/2 second to each topic in turn";

