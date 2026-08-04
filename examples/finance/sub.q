// usage - $HOME/.kx/bin/q examples/finance/sub.q -topic trade -init 1 -stats 1

/ load modules
.kafka:use`kx.kafka;
.logger:use`kx.log;
.log:.logger.createLog[]

client:.kafka.Consumer[`metadata.broker.list`group.id!`localhost:9092`0];

/ topic subscription
mytopic:first`$(opts:.Q.opt[.z.x])`topic
start:"B"$0^first opts`init;
stats:"B"$0^first opts`stats;

/ schema
position:([sym:`$()]time:`timestamp$();pos:`long$())
trade:([]time:`timestamp$();sym:`$();side:`$();price:`float$();size:`long$())
quote:([sym:`$()]time:`timestamp$(); bid:`float$(); ask:`float$(); bsize:`long$(); asize:`long$());

getPayload:{[msg] -9! msg`data }
printStats:{
  .log.info .j.j tables[]!count each value each tables[]
  }

/ table specific call backs
cb_default:{[t;x] insert[t] cols[t]#x}
cb_quote:{[t;x] upsert[t] cols[t]#x}
cb_trade:{[t;x]
  cb_default[t;x]; 
  old_pos:0^(position x`sym)`pos;
  sd:$[`buy=x`side;+;-];
  new_pos:.[sd;(old_pos;x`size); {.log.info "Issue updating position"}];
  upsert[`position]`sym`time`pos!(x`sym;.z.p; new_pos);
  }
cb_dict:`trade`quote!(`cb_trade;`cb_quote); 

/ callback function when message received
cb:{[msg]
  if[-1h=type dict:@[getPayload; msg; 0b]; :()];  
  f:$[dict[`t] in key cb_dict; cb_dict dict`t; `cb_default];
  .[value[f]; (dict`t; dict`x); {[dict;e].log.info "Failed to process update for: ",string dict`t }dict];
  }

.z.ts:printStats;
init:{
  .kafka.SetConsumeCb[cb]
  .log.info "Subscribed to topic: ",string[mytopic];
  .kafka.Sub[client;mytopic;enlist .kafka.PARTITION_UA];
  }
if[start; init[]]
if[`stats in key opts; system"t 30000"]