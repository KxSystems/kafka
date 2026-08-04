// usage - $HOME/.kx/bin/q examples/finance/feed.q -init 1

/ load modules
.kafka:use`kx.kafka
.logger:use`kx.log;
.log:.logger.createLog[]

/ cfg for a kafka broker running on localhost:9002
kfk_cfg:`metadata.broker.list`statistics.interval.ms!`localhost:9092`10000


/ topic subscription
opts:.Q.opt[.z.x];
start:"B"$0^first opts`init;
i:0;

getTradeData:{
   -8!`t`x!(`trade;`time`sym`side`price`size!(.z.p;first 1?`AAPL`MSFT`NVDA`META; first 1?`buy`sell; first 1?100.;first 1?1000000))     
  }
getQuoteData:{
  bid:first 1?100.; ask:2.+bid;
  size:first 1?100000;
  -8!`t`x!(`quote;`time`sym`bid`ask`bsize`asize!(.z.p;first 1?`AAPL`MSFT`NVDA`META; bid;ask;size;size))     
  }
getTopic:{
  // logic for deciding to send
  i+:1;
  $[0=i mod 10;`trade_topic;`quote_topic]  // every 10th msg send a trade
  }
publish:{[t]
  topic:getTopic[];
  data:$[topic=`trade_topic;getTradeData[]; getQuoteData[]];
  .kafka.Pub[value topic;.kafka.PARTITION_UA; data; "string"]
  }

.z.ts:publish
init:{
  producer:.kafka.Producer[kfk_cfg];
  quote_topic::.kafka.Topic[producer;`quote;()!()];
  trade_topic::.kafka.Topic[producer;`trade;()!()];
  system"t 5000";
  .log.info "Publishing to topics: trade and quote";
  }  
if[start; init[]]