\l ../kfk.q

kfk_cfg:(!) . flip(
    (`metadata.broker.list;`localhost:9092);
    (`group.id;`0);
    (`fetch.wait.max.ms;`10);
    (`statistics.interval.ms;`10000)
    );
client:.kfk.Consumer[kfk_cfg];

// Topics to subscribe to
topic1:`test1;
topic2:`test2;

// Define datasets and topic callbacks for topic1
data1:();
topcb1:{[msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.p;
  data1,::enlist msg;}

// Define datasets and topic callbacks for topic2
data2:();
topcb2:{[msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.t;
  data2,::enlist msg;}

printmeta:{
  -1 "==== MetaData provided by the following broker =======";
  -1 "name:",string x`orig_broker_name;
  -1 "id:",string x`orig_broker_id;
  -1 "==== Brokers =========================================";
  show each x`brokers;
  -1 "==== Topics ==========================================";
  $[count x`topics;show each x`topics;-1 "[None]"];
  -1 "";}

printmeta .kfk.Metadata[client];

// Subscribe to topic1 and topic2 with different callbacks from a single client
-1 "Subscribing to topics called ",(string topic1)," and ",string topic2;
-1 "Consumed data will be placed in tables data1 and data2 when available (type 'data1' or 'data2' to view)";
.kfk.Subscribe[client;(topic1;topic2);enlist .kfk.PARTITION_UA;(topcb1;topcb2)]
