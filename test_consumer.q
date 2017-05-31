\l kfk.q

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

.kfk.Sub[client;`test;enlist .kfk.PARTITION_UA];

client_meta:.kfk.Metadata[client];
show client_meta`topics;
