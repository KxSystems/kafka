#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
#include <librdkafka/rdkafka.h>
#include "socketpair.c"
#include <fcntl.h>
#include "k.h"
#define K3(f) K f(K x,K y,K z)
#define K4(f) K f(K x,K y,K z,K r)

#ifdef _WIN32
#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "librdkafka.lib")
#define EXP __declspec(dllexport)
static SOCKET spair[2];
#else
#include <unistd.h>
#define EXP
#define SOCKET_ERROR -1
static I spair[2];
#endif
static J maxMsgsPerPoll = 0;

#define KR -128
#define KNL (K) 0
#define KFK_OK RD_KAFKA_RESP_ERR_NO_ERROR
#ifdef __GNUC__
#  define UNUSED(x) x __attribute__((__unused__))
#else
#  define UNUSED(x) x
#endif
// create dictionary q dictionary from list of items (s1;v1;s2;v2;...)
K xd0(I n, ...){
  va_list a;
  S s;
  K x, y= ktn(KS, n), z= ktn(0, n);
  y->n=0;z->n=0;
  va_start(a, n);
  for(; s= va_arg(a, S), s && (x= va_arg(a, K));)
    js(&y, ss(s)), jk(&z, x);
  va_end(a);
  return xD(y, z);
}
#define xd(...) xd0(0, __VA_ARGS__, (S) 0)

typedef unsigned int UI;
static K S0;
static K clients, topics;
static I validinit;

K decodeParList(rd_kafka_topic_partition_list_t *t);

// check type
// letter as usual, + for table, ! for dict
static I checkType(const C* tc, ...){
  va_list args;
  K x;
  static C lt[256]= " tvunzdmpscfejihg xb*BX GHIJEFCSPMDZNUVT";
  static C b[256];
  const C* tc0= tc;
  I match=0;
  lt[20 + 98]= '+';
  lt[20 + 99]= '!';
  va_start(args, tc);
  for(; *tc;){
    match= 0;
    x= va_arg(args, K);
    if(!x){
      strcpy(b, "incomplete type string ");
      break;
    };
    if('[' == *tc){
      while(*tc && ']' != *tc){
        match= match || lt[20 + xt] == *tc;
        ++tc;
      }
    }
    else
      match= lt[20 + xt] == *tc;
    if(!match){
      strcat(strcpy(b, "type:expected "), tc0);
      break;
    };
    ++tc;
  }
  va_end(args);
  if(!match)
    krr(b);
  return match;
}

// use QS
rd_kafka_t *clientIndex(K x){
  return (rd_kafka_t *) ((((UI) xi < clients->n) && kS(clients)[xi]) ?kS(clients)[xi] :(S) krr("unknown client"));
}

I indexClient(const rd_kafka_t *rk){
  int i;
  for (i = 0; i < clients->n; ++i)
    if(rk==(rd_kafka_t *)kS(clients)[i]) return i;
  return ni;
}

rd_kafka_topic_t *topicIndex(K x){
  return (rd_kafka_topic_t *) ((((UI) xi < topics->n) && kS(topics)[xi]) ?kS(topics)[xi] :(S) krr("unknown topic"));
}

// print error if any and release K object.
// should return 0 to indicate mem free to kafka where needed in callback
static I printr0(K x){
  if(!x)
    return 0;
  if(KR == xt)
    fprintf(stderr, "%s\n", x->s);
  r0(x);
  return 0;
}

K decodeMsg(const rd_kafka_t*rk,const rd_kafka_message_t *msg);

static I statscb(rd_kafka_t*UNUSED(rk), S json, size_t json_len, V*UNUSED(opaque)){
  return printr0(k(0, (S) ".kfk.statcb", kpn(json, json_len), KNL));
} // should return 0 to indicate mem free to kafka

static V logcb(const rd_kafka_t *UNUSED(rk), int level, const char *fac, const char *buf){
  printr0(k(0, (S) ".kfk.logcb", ki(level), kp((S) fac), kp((S) buf), KNL));
}

static V offsetcb(rd_kafka_t *rk, rd_kafka_resp_err_t err,
                  rd_kafka_topic_partition_list_t*offsets, V*UNUSED(opaque)){
  printr0(k(0, (S) ".kfk.offsetcb", ki(indexClient(rk)), kp((S)rd_kafka_err2str(err)), decodeParList(offsets),KNL));
}

static V drcb(rd_kafka_t*rk,const rd_kafka_message_t *msg,V*UNUSED(opaque)){
  printr0(k(0,(S)".kfk.drcb",ki(indexClient(rk)), decodeMsg(rk,msg),KNL));
}

static V errorcb(rd_kafka_t *rk, int err, const char *reason, V*UNUSED(opaque)){
  printr0(k(0, (S) ".kfk.errcb", ki(indexClient(rk)), ki(err), kp((S)reason), KNL));
}

static V throttlecb(rd_kafka_t *rk, const char *brokername,
                    int32_t brokerid, int throttle_time_ms, V*UNUSED(opaque)){
  printr0(k(0,(S) ".kfk.throttlecb", ki(indexClient(rk)),
          kp((S)brokername), ki(brokerid), ki(throttle_time_ms),KNL));
}

// client api
// x - config dict sym->sym
static K loadConf(rd_kafka_conf_t *conf, K x){
  char b[512];
  J i;
  for(i= 0; i < xx->n; ++i){
    if(RD_KAFKA_CONF_OK !=rd_kafka_conf_set(conf, kS(xx)[i], kS(xy)[i], b, sizeof(b))){
      return krr((S) b);
    }
  }
  return knk(0);
}
static K loadTopConf(rd_kafka_topic_conf_t *conf, K x){
  char b[512];
  J i;
  for(i= 0; i < xx->n; ++i){
    if(RD_KAFKA_CONF_OK !=rd_kafka_topic_conf_set(conf, kS(xx)[i], kS(xy)[i], b, sizeof(b)))
      return krr((S) b);
  }
  return knk(0);
}

// x:client type p - producer, c - consumer
// y:config dict sym->sym
EXP K2(kfkClient){
  rd_kafka_type_t type;
  rd_kafka_t *rk;
  rd_kafka_conf_t *conf;
  char b[512];
  if(!checkType("c!", x, y))
    return KNL;
  if('p' != xg && 'c' != xg)
    return krr("type: unknown client type");
  type= 'p' == xg ? RD_KAFKA_PRODUCER : RD_KAFKA_CONSUMER;
  if(!loadConf(conf= rd_kafka_conf_new(), y))
    return KNL;
  rd_kafka_conf_set_stats_cb(conf, statscb);
  rd_kafka_conf_set_log_cb(conf, logcb);
  rd_kafka_conf_set_dr_msg_cb(conf,drcb);
  rd_kafka_conf_set_offset_commit_cb(conf,offsetcb);
  rd_kafka_conf_set_throttle_cb(conf,throttlecb);
  rd_kafka_conf_set_error_cb(conf,errorcb);
  if(RD_KAFKA_CONF_OK !=rd_kafka_conf_set(conf, "log.queue", "true", b, sizeof(b)))
    return krr((S) b);
  if(!(rk= rd_kafka_new(type, conf, b, sizeof(b))))
    return krr(b);
  /* Redirect logs to main queue */
  rd_kafka_set_log_queue(rk,NULL);
  /* Redirect rd_kafka_poll() to consumer_poll() */
  if(type == RD_KAFKA_CONSUMER){
    rd_kafka_poll_set_consumer(rk);
    rd_kafka_queue_io_event_enable(rd_kafka_queue_get_consumer(rk),spair[1],"X",1);
  }
  else
    rd_kafka_queue_io_event_enable(rd_kafka_queue_get_main(rk),spair[1],"X",1);
  js(&clients, (S) rk);
  return ki(clients->n - 1);
}

EXP K1(kfkClientDel){
  rd_kafka_t *rk;
  if(!checkType("i", x))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;
  rd_kafka_consumer_close(rk);
  rd_kafka_destroy(rk);
  kS(clients)[x->i]= (S) 0;
  return KNL;
}

EXP K1(kfkClientName){
  rd_kafka_t *rk;
  if(!checkType("i", x))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;
  return ks((S) rd_kafka_name(rk));
}

EXP K1(kfkClientMemberId){
  rd_kafka_t *rk;
  if(!checkType("i", x))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;
  return ks(rd_kafka_memberid(rk));
}

// topic api
EXP K3(kfkTopic){
  rd_kafka_topic_t *rkt;
  rd_kafka_t *rk;
  rd_kafka_topic_conf_t *rd_topic_conf;
  if(!checkType("is!",x ,y ,z))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;
  rd_topic_conf= rd_kafka_topic_conf_new();
  loadTopConf(rd_topic_conf, z);
  rkt= rd_kafka_topic_new(rk, y->s, rd_topic_conf);
  js(&topics, (S) rkt);
  return ki(topics->n - 1);
}

EXP K1(kfkTopicDel){
  rd_kafka_topic_t *rkt;
  if(!checkType("i", x))
    return KNL;
  if(!(rkt= topicIndex(x)))
    return KNL;
  rd_kafka_topic_destroy(rkt);
  kS(topics)[x->i]= (S) 0;
  return KNL;
}

EXP K1(kfkTopicName){
  rd_kafka_topic_t *rkt;
  if(!checkType("i", x))
    return KNL;
  if(!(rkt= topicIndex(x)))
    return KNL;
  return ks((S) rd_kafka_topic_name(rkt));
}

// metadata api
// rd_kafka_metadata_broker: `id`host`port!(id;host;port)
K decodeMetaBroker(rd_kafka_metadata_broker_t *x){
  return xd("id", ki(x->id), "host", ks(x->host), "port", ki(x->port));
}

// rd_kafka_metadata_partition: `id`err`leader`replicas`isrs!(int;err;int;int
// list;int list)
K decodeMetaPart(rd_kafka_metadata_partition_t *p){
  K x= ktn(KI, p->replica_cnt);
  J i;
  for(i= 0; i < xn; ++i)
    kI(x)[i]= p->replicas[i];
  K y= ktn(KI, p->isr_cnt);
  for(i= 0; i < y->n; ++i)
    kI(y)[i]= p->isrs[i];
  return xd("id", ki(p->id), "err", ks((S) rd_kafka_err2str(p->err)),
            "leader",ki(p->leader), "replicas", x, "isrs", y);
}

// rd_kafka_metadata_topic: `topic`partitions`err!(string;partition list;err)
K decodeMetaTopic(rd_kafka_metadata_topic_t *t){
  K x= ktn(0, 0);
  J i;
  for(i= 0; i < t->partition_cnt; ++i)
    jk(&x, decodeMetaPart(&t->partitions[i]));
  return xd("topic", ks(t->topic), 
            "err",ks((S) rd_kafka_err2str(t->err)),"partitions", x);
}

// rd_kafka_metadata: `brokers`topics`orig_broker_id`orig_broker_name!(broker
// list;topic list;int;string)
K decodeMeta(const rd_kafka_metadata_t *meta) {
  K x= ktn(0, 0);
  J i;
  for(i= 0; i < meta->broker_cnt; ++i)
    jk(&x, decodeMetaBroker(&meta->brokers[i]));
  K y= ktn(0, 0);
  for(i= 0; i < meta->topic_cnt; ++i)
    jk(&y, decodeMetaTopic(&meta->topics[i]));
  return xd("orig_broker_id", ki(meta->orig_broker_id),
            "orig_broker_name",ks(meta->orig_broker_name),
            "brokers", x, "topics", y);
}

EXP K1(kfkMetadata){
  const struct rd_kafka_metadata *meta;
  K r;
  rd_kafka_t *rk;
  if(!checkType("i", x))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;
  rd_kafka_resp_err_t err= rd_kafka_metadata(rk, 1, NULL, &meta, 5000);
  if(KFK_OK != err)
    return krr((S) rd_kafka_err2str(err));
  r= decodeMeta(meta);
  rd_kafka_metadata_destroy(meta);
  return r;
}

K decodeTopPar(rd_kafka_topic_partition_t *tp){
  return xd("topic", ks((S) tp->topic), "partition", ki(tp->partition),
            "offset", kj(tp->offset), 
            "metadata",kpn(tp->metadata, tp->metadata_size));
}

K decodeParList(rd_kafka_topic_partition_list_t *t){
  K r;J i;
  if(!t)return knk(0);
  r= ktn(0, t->cnt);
  for(i= 0; i < r->n; ++i)
    kK(r)[i]= decodeTopPar(&t->elems[i]);
  return r;
}


static V plistoffsetdict(S topic,K partitions,rd_kafka_topic_partition_list_t *t_partition){
  K dk=kK(partitions)[0],dv=kK(partitions)[1];
  I*p;J*o,i;
  p=kI(dk);o=kJ(dv);
  for(i= 0; i < dk->n; ++i){
    rd_kafka_topic_partition_list_add(t_partition, topic, p[i]);
    rd_kafka_topic_partition_list_set_offset(t_partition, topic, p[i],o[i]);
  }
}

EXP K2(kfkFlush){
  rd_kafka_t *rk;
  I qy=0;
  if(!checkType("i[hij]",x,y))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;
  SW(y->t){
    CS(-KH,qy=y->h);
    CS(-KI,qy=y->i);
    CS(-KJ,qy=y->j);
  }
  rd_kafka_resp_err_t err= rd_kafka_flush(rk,qy);
  if(KFK_OK != err)
    return krr((S) rd_kafka_err2str(err));
  return KNL;
 }

// producer api
EXP K4(kfkPub){
  rd_kafka_topic_t *rkt;
  if(!checkType("ii[CG][CG]", x, y, z, r))
    return KNL;
  if(!(rkt= topicIndex(x)))
    return KNL;
  if(rd_kafka_produce(rkt, y->i, RD_KAFKA_MSG_F_COPY, kG(z), z->n, kG(r), r->n, NULL))
    return krr((S) rd_kafka_err2str(rd_kafka_last_error()));
  return KNL;
}

/**
 * @param x Topic Index (prev created)
 * @param y Partition to use for all message (int) or partition per message (list of ints)
 * @param z Payload for all messages (mixed list containing either bytes or string).
 * @param r Key. Empty string to use auto key for all messages, or key per message (mixed list containing either bytes or string)
 * @returns Integer list with a status for each send message (zero indicates success) 
 *          reference: https://github.com/edenhill/librdkafka/blob/master/src/rdkafka.h (rd_kafka_resp_err_t)
 */

#if (RD_KAFKA_VERSION >= 0x000b04ff)

EXP K4(kfkBatchPub){
  rd_kafka_topic_t *rkt;
  if(!checkType("i[iI]*[CG*]", x, y, z, r))
    return KNL;
  int msgcnt = z->n;
  if ((r->t == 0) && (msgcnt != r->n))
    return krr((S)"msg field not same len as key field");
  if ((y->t == KI) && (msgcnt != y->n))
    return krr((S)"msg field not same len as partition field");
  int i=0;
  for (i = 0 ; i < msgcnt ; i++)
  {
    if (((K*)z->G0)[i]->t != KG && ((K*)z->G0)[i]->t !=KC)
      return krr((S)"incorrect type for msg");
    if ((r->t ==0) && ((K*)r->G0)[i]->t != KG && ((K*)r->G0)[i]->t !=KC)
      return krr((S)"incorrect type for key");
  }
  if(!(rkt= topicIndex(x)))
    return KNL;
  int defaultPartition = RD_KAFKA_PARTITION_UA;
  int msgFlags = RD_KAFKA_MSG_F_COPY;
  if (y->t == KI)
    msgFlags |= RD_KAFKA_MSG_F_PARTITION; /* use partition per msg */
  else
    defaultPartition = y->i; /* partition passed for all msgs */
  
  rd_kafka_message_t *rkmessages;
  rkmessages = calloc(sizeof(*rkmessages), msgcnt);
  K key = r;
  for (i = 0 ; i < msgcnt ; i++)
  {
    K msg = ((K*)z->G0)[i];
    if (r->t == 0)
      key = ((K*)r->G0)[i];
    rkmessages[i].payload = kG(msg);
    rkmessages[i].len = msg->n;
    rkmessages[i].key = kG(key);
    rkmessages[i].key_len = key->n;
    if (y->t == KI)
      rkmessages[i].partition = kI(y)[i]; /* use partition per msg */
  }
  rd_kafka_produce_batch(rkt,defaultPartition,msgFlags,rkmessages,msgcnt);
  K results = ktn(KI, msgcnt);
  for (i = 0 ; i < msgcnt ; i++)
    kI(results)[i]=rkmessages[i].err;
  free(rkmessages);
  return results;
}

#else

EXP K kfkBatchPub(K UNUSED(x), K UNUSED(y), K UNUSED(z), K UNUSED(r)){
  return krr("BatchPub unsupported - please update librdkafka");
}

#endif

// consume api
EXP K3(kfkSub){
  rd_kafka_resp_err_t err;
  rd_kafka_t *rk;rd_kafka_topic_partition_list_t *t_partition;
  J i;
  I*p;
  if(!checkType("is[I!]", x, y, z))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;
  if(KFK_OK != (err = rd_kafka_subscription(rk, &t_partition)))
    return krr((S)rd_kafka_err2str(err));
  if(z->t == XD){
    if(!checkType("IJ", kK(z)[0], kK(z)[1]))
      return KNL;
    plistoffsetdict(y->s,z,t_partition);
  }
  else
    for(p=kI(z), i= 0; i < z->n; ++i)
      rd_kafka_topic_partition_list_add(t_partition, y->s, p[i]);
  if(KFK_OK != (err= rd_kafka_subscribe(rk, t_partition)))
    return krr((S) rd_kafka_err2str(err));
  rd_kafka_topic_partition_list_destroy(t_partition);
  return knk(0);
}

EXP K1(kfkUnsub){
  rd_kafka_t *rk;
  rd_kafka_resp_err_t err;
  if(!checkType("i", x))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;
  err= rd_kafka_unsubscribe(rk);
  if(KFK_OK != err)
    return krr((S) rd_kafka_err2str(err));
  return knk(0);
}

// https://github.com/edenhill/librdkafka/wiki/Manually-setting-the-consumer-start-offset
EXP K3(kfkAssignOffsets){
  rd_kafka_t *rk;
  rd_kafka_topic_partition_list_t *t_partition;
  rd_kafka_resp_err_t err;
  if(!checkType("is!", x,y,z))
    return KNL;
  if(!checkType("IJ",kK(z)[0],kK(z)[1]))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;
  t_partition = rd_kafka_topic_partition_list_new(z->n);
  plistoffsetdict(y->s,z,t_partition);
  if(KFK_OK != (err=rd_kafka_assign(rk,t_partition)))
    return krr((S) rd_kafka_err2str(err));
  rd_kafka_topic_partition_list_destroy(t_partition);
  return knk(0);
}

EXP K4(kfkCommitOffsets){
  rd_kafka_resp_err_t err;
  rd_kafka_t *rk;rd_kafka_topic_partition_list_t *t_partition;
  if(!checkType("is!b", x, y, z, r))
    return KNL;
  if(!checkType("IJ",kK(z)[0],kK(z)[1]))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;  
  t_partition = rd_kafka_topic_partition_list_new(z->n);
  plistoffsetdict(y->s,z,t_partition);
  if(KFK_OK != (err= rd_kafka_commit(rk, t_partition,r->g)))
    return krr((S) rd_kafka_err2str(err));
  rd_kafka_topic_partition_list_destroy(t_partition);
  return knk(0);
}

EXP K3(kfkCommittedOffsets){
  K r;
  rd_kafka_resp_err_t err;
  rd_kafka_t *rk;rd_kafka_topic_partition_list_t *t_partition;
  if(!checkType("is!", x, y, z))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;
  if(!checkType("IJ",kK(z)[0],kK(z)[1]))
    return KNL;
  t_partition = rd_kafka_topic_partition_list_new(z->n);
  plistoffsetdict(y->s,z,t_partition);
  if(KFK_OK != (err= rd_kafka_committed(rk, t_partition,5000)))
    return krr((S) rd_kafka_err2str(err));
  r=decodeParList(t_partition);
  rd_kafka_topic_partition_list_destroy(t_partition);
  return r;
}

EXP K3(kfkPositionOffsets){
  K r;
  rd_kafka_resp_err_t err;
  rd_kafka_t *rk;rd_kafka_topic_partition_list_t *t_partition;
  if(!checkType("is!", x, y, z))
    return KNL;
  if(!checkType("IJ",kK(z)[0],kK(z)[1]))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;
  t_partition = rd_kafka_topic_partition_list_new(z->n);
  plistoffsetdict(y->s,z,t_partition); 
  if(KFK_OK != (err= rd_kafka_position(rk, t_partition)))
    return krr((S) rd_kafka_err2str(err));
  r=decodeParList(t_partition);
  rd_kafka_topic_partition_list_destroy(t_partition);
  return r;
}

EXP K1(kfkSubscription){
  K r;
  rd_kafka_topic_partition_list_t *t;
  rd_kafka_t *rk;
  rd_kafka_resp_err_t err;
  if (!checkType("i", x))
    return KNL;
  if (!(rk = clientIndex(x)))
    return KNL;
  if (KFK_OK != (err= rd_kafka_subscription(rk, &t)))
    return krr((S)rd_kafka_err2str(err));
  r = decodeParList(t);
  rd_kafka_topic_partition_list_destroy(t);
  return r;
}

static J pu(J u){return 1000000LL*(u-10957LL*86400000LL);}
// `mtype`topic`partition`data`key`offset`opaque
K decodeMsg(const rd_kafka_t* rk, const rd_kafka_message_t *msg) {
  K x= ktn(KG, msg->len), y=ktn(KG, msg->key_len), z;
  J ts= rd_kafka_message_timestamp(msg, NULL);
  memmove(kG(x), msg->payload, msg->len);
  memmove(kG(y), msg->key, msg->key_len);
  z= ktj(-KP, ts > 0 ? pu(ts) : nj);
  return xd0(8,
    "mtype", msg->err ? ks((S) rd_kafka_err2name(msg->err)) : r1(S0), 
    "topic", msg->rkt ? ks((S) rd_kafka_topic_name(msg->rkt)) : r1(S0),
    "client", ki(indexClient(rk)), "partition", ki(msg->partition), "offset", kj(msg->offset),
    "msgtime", z, "data", x, "key", y, (S) 0);
}

J pollClient(rd_kafka_t *rk, J timeout, J maxcnt) {
  if(rd_kafka_type(rk) == RD_KAFKA_PRODUCER)
    return rd_kafka_poll(rk, timeout);
  K r;
  J n= 0;
  rd_kafka_message_t *msg;
  while((msg= rd_kafka_consumer_poll(rk, timeout))) {
    r= decodeMsg(rk,msg);
    printr0(k(0, ".kfk.consumecb", r, KNL));
    rd_kafka_message_destroy(msg);
    ++n;
    /* as n is never 0 in next call, when maxcnt is 0 and maxMsgsPerPoll is 0, doesnt return early */
    /* maxcnt has priority over maxMsgsPerPoll */
    if ((maxcnt==n) || (maxMsgsPerPoll==n && maxcnt==0)) 
    {
      char data = 'Z';
      send(spair[1], &data, 1, 0);
      return n;
    }
  }
  return n;
}

EXP K1(kfkMaxMsgsPerPoll){
  if(!checkType("j", x))
    return KNL;
  maxMsgsPerPoll=x->j;
  return kj(maxMsgsPerPoll);
}

// for manual poll of the feed.
EXP K3(kfkPoll){
  J n= 0;
  rd_kafka_t *rk;
  if(!checkType("ijj", x, y, z))
    return KNL;
  if(!(rk= clientIndex(x)))
    return KNL;
  n=pollClient(rk,y->j,z->j);
  return kj(n);
}

// other
EXP K1(kfkOutQLen){
  rd_kafka_t *rk;
  if(!(rk= clientIndex(x)))
    return KNL;
  return ki(rd_kafka_outq_len(rk));
}

// logger level is set based on Severity levels in syslog https://en.wikipedia.org/wiki/Syslog#Severity_level
EXP K2(kfkSetLoggerLevel){
  rd_kafka_t *rk;
  I qy=0;
  if(!checkType("i[hij]",x,y))
    return KNL;
  if(!(rk=clientIndex(x)))
    return KNL;
  SW(y->t){
    CS(-KH,qy=y->h);
    CS(-KI,qy=y->i);
    CS(-KJ,qy=y->j);
  }
  rd_kafka_set_log_level(rk, qy);
  return KNL;
}

// Returns the number of threads currently being used by librdkafka
EXP K kfkThreadCount(K UNUSED(x)){return ki(rd_kafka_thread_cnt());}

EXP K kfkVersion(K UNUSED(x)){return ki(rd_kafka_version());}

// Returns the human readable librdkafka version
EXP K kfkVersionSym(K UNUSED(x)){return ks((S)rd_kafka_version_str());}

EXP K kfkExportErr(K UNUSED(dummy)){
  const struct rd_kafka_err_desc *errdescs;
  size_t i,n;
  K x= ktn(0, 0), y= ktn(0, 0), z= ktn(0, 0);
  rd_kafka_get_err_descs(&errdescs, &n);
  for(i= 0; i < n; ++i)
    if(errdescs[i].code) {
      jk(&x, ki(errdescs[i].code));
      jk(&y, ks((S)(errdescs[i].name ? errdescs[i].name : "")));
      jk(&z, kp((S)(errdescs[i].desc ? errdescs[i].desc : "")));
    }
  return xT(xd("errid", x, "code", y, "desc", z));
}

// shared lib loading
EXP K kfkCallback(I d){
  char buf[1024];J i,n,consumed=0;
  /*MSG_DONTWAIT - set in sd1(-h,...) */
  while(0 < (n=recv(d, buf, sizeof(buf), 0)))
    consumed+=n;
  // pass consumed to poll for possible batching
  for(i= 0; i < clients->n; i++)
    pollClient((rd_kafka_t*)kS(clients)[i], 0, 0);
  return KNL;
}

static V detach(V){
  I sp,i;
  if(topics){
    for(i= 0; i < topics->n; i++)
      kfkTopicDel(ki(i));
    r0(topics);
  }
  if(clients){
    for(i= 0; i < clients->n; i++){
      if(!((S)0 == kS(clients)[i]))   /* ignore any clients that have been deleted previously */
        kfkClientDel(ki(i));
    }
    rd_kafka_wait_destroyed(1000);    /* wait for cleanup*/
    r0(clients); 
  }
  if(sp=spair[0]){
    sd0x(sp,0);
    close(sp);
  }
  if(sp=spair[1])
    close(sp); 
  spair[0]= 0;
  spair[1]= 0;
  validinit = 0;
}

EXP K kfkInit(K UNUSED(x)){
  if(!(0==validinit))
   return 0; 
  clients=ktn(KS,0);
  topics=ktn(KS,0);
  S0=ks("");
  if(dumb_socketpair(spair, 1) == SOCKET_ERROR)
    fprintf(stderr, "Init failed, creating socketpair: %s\n", strerror(errno));
#ifdef WIN32
  u_long iMode = 1;
  if (ioctlsocket(spair[0], FIONBIO, &iMode) != NO_ERROR)
    return krr((S)"Init couldn't set socket to non-blocking");
  if (ioctlsocket(spair[1], FIONBIO, &iMode) != NO_ERROR)
    return krr((S)"Init couldn't set socket to non-blocking");
#else
  if (fcntl(spair[0], F_SETFL, O_NONBLOCK) == -1)
    return krr((S)"Init couldn't set socket to non-blocking");
  if (fcntl(spair[1], F_SETFL, O_NONBLOCK) == -1)
    return krr((S)"Init couldn't set socket to non-blocking");
#endif
  K r=sd1(-spair[0], &kfkCallback);
  if(r==0){
    fprintf(stderr, "Init failed, adding callback\n");
    spair[0]=0;
    spair[1]=0;
    return 0;
  }
  r0(r);
  validinit=1;
  atexit(detach);
  return 0;
}
