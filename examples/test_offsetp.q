\l ../q/kfk.q
kfk_cfg:(!) . flip(
  (`metadata.broker.list;`localhost:9092);
  (`statistics.interval.ms;`10000);
  (`queue.buffering.max.ms;`1);
  (`fetch.wait.max.ms;`10)
  );
producer:.kfk.Producer[kfk_cfg]

// Create two topics associated with the producer publishing on `test1`test2
topic1:.kfk.Topic[producer;`test1;()!()]
topic2:.kfk.Topic[producer;`test2;()!()]

// Define a delivery callback
.kfk.drcb:{[cid;msg]show "Delivered msg on ",string[cid],": ",.Q.s1 msg;}

// Publish messages at different rates
.z.ts:{n+:1;
       .kfk.Pub[topic1;0i;string x;""];
       if[n mod 2;.kfk.Pub[topic2;0i;string x;""]]}
-1 "Publishing on topics:", " "sv{string .kfk.TopicName x}each(topic1;topic2);
.kfk.Pub[topic1;0i;string .z.p;""];
.kfk.Pub[topic2;0i;string .z.p;""];

-1 "Published one message to each topic.\n";
-1"Set timer with \\t 1000 to publish a message on `test1 every second and on `test2 every two seconds.";

