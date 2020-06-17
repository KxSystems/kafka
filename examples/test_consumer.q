\l ../kfk.q

kfk_cfg:(!) . flip(
    (`metadata.broker.list;`localhost:9092);
    (`group.id;`0);
    (`queue.buffering.max.ms;`1);
    (`fetch.wait.max.ms;`10);
    (`statistics.interval.ms;`10000)
    );
client:.kfk.Consumer[kfk_cfg];

// Topics to subscribe to
topic1:`test1; topic2:`test2;

// Define datasets and topic callbacks for individual
// topic subscriptions `topic1 and `topic2
data1:();
topcb1:{[msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.p;
  data1,::enlist msg;}

data2:();
topcb2:{[msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.t;
  data2,::enlist msg;}

// Subscribe to topic1 and topic2 with different callbacks from a single client
.kfk.Subscribe[client;topic1;enlist .kfk.PARTITION_UA;topcb1]
.kfk.Subscribe[client;topic2;enlist .kfk.PARTITION_UA;topcb2]

client_meta:.kfk.Metadata[client];
show client_meta`topics;
