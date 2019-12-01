\l ../kfk.q

kfk_cfg:(!) . flip(
    (`metadata.broker.list;`localhost:9092);
    (`group.id;`0);
    (`queue.buffering.max.ms;`1);
    (`fetch.wait.max.ms;`10);
    (`statistics.interval.ms;`10000)
    );
client:.kfk.Consumer[kfk_cfg];

data:();
.kfk.consumecb:{[msg]
    msg[`data]:"c"$msg[`data];
    msg[`rcvtime]:.z.p;
    data,::enlist msg;}

// Topics to subscribe to
topic1:`test1; topic2:`test2;

// Subscribe to multiple topics from a single client
.kfk.Sub[client;;enlist .kfk.PARTITION_UA]each(topic1;topic2);

client_meta:.kfk.Metadata[client];
show client_meta`topics;
