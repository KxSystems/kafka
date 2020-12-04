//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
#include <librdkafka/rdkafka.h>
#include "socketpair.c"
#include <fcntl.h>
#include "k.h"

//%% Socket Library %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

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

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                         Macros                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Utility for Quench Warning %%//vvvvvvvvvvvvvvvvvvvvvv/

#ifdef __GNUC__
#  define UNUSED(x) x __attribute__((__unused__))
#else
#  define UNUSED(x) x
#endif

//%% Utility for Function Signature %%//vvvvvvvvvvvvvvvvvv/

#define K3(f) K f(K x,K y,K z)
#define K4(f) K f(K x,K y,K z,K r)

//%% Type Alias %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

typedef unsigned int UI;

/**
 * @brief Null of K object
 */
#define KNULL (K) 0

/**
 * @brief Indicator of successful response from Kafka
 */
#define KFK_OK RD_KAFKA_RESP_ERR_NO_ERROR

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Utility %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Error type of K object
 */
static const I KR=-128;

/**
 * @brief Offset between UNIX epoch (1970.01.01) and kdb+ epoch (2000.01.01) in day.
 */
static const J KDB_DAY_OFFSET=10957;

/**
 * @brief Milliseconds in a day
 */
static const J ONEDAY_MILLIS=86400000;

//%% Interface %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 *  @brief Maximum number of messages to poll at once. Set `0` by default.
 */
static J MAX_MESSAGES_PER_POLL = 0;

/**
 * @brief WHAT IS THIS??
 */
static K S0;

/**
 * @brief Client names expressed in symbol list
 */
static K CLIENTS;

/**
 * @brief Topic names expressed in symbol list
 */
static K TOPICS;

static I validinit;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Functions                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Pre-Declaration %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

K decode_topic_partition_list(rd_kafka_topic_partition_list_t *t);
K decode_message(const rd_kafka_t*rk,const rd_kafka_message_t *msg);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% General Utility Functions %%//vvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Internal function to create dictionary q dictionary from list of items (s1;v1;s2;v2;...) with reserved `n` spaces.
 * @param n: The number of spaces to be reserved.
 * @param args: Expressed as variadic. key and value of dictionary appear alternately.
 * @note
 * `(S) 0` must be provided at the end.
 */
K build_dictionary_n(I n, ...){
  // Holder of variadic
  va_list args;
  // Receiver of keys and values from variadic
  S key_holder;
  K value_holder;
  // Container of keys and values
  K keys= ktn(KS, n);
  K values= ktn(0, n);
  keys->n=0;
  values->n=0;
  va_start(args, n);
  for(; key_holder= va_arg(args, S), key_holder && (value_holder= va_arg(args, K));){
    js(&keys, ss(key_holder));
    jk(&values, value_holder);
  } 
  va_end(args);
  return xD(keys, values);
}

/**
 * @brief Create dictionary q dictionary from list of items (s1;v1;s2;v2;...) without reserving spaces initially.
 * @param args: Expressed as variadic. key and value of dictionary appear alternately.
 */
#define build_dictionary(...) build_dictionary_n(0, __VA_ARGS__, (S) 0)


/**
 * @brief Check type of arguments.
 * @param types: Type indicators to test.
 * - Letter denotes kdb+ simple type
 * - '+' denotes table
 * - '!' denotes dict
 * - [xyz] denotes any of x, y or z
 * @param args: Arguments to check their types.
 * @example
 * Check if:
 * - `x` is int
 * - `y` is symbol
 * - `z` is dictionary
 * ```
 * checkType("is!",x ,y ,z)
 * ```
 */
static I checkType(const C* types, ...){
  // Holder of variadic
  va_list args;
  // Receiver of K object to test its type
  K obj;
  // Type indicators sorted in ascending order by underlying integer values
  static C indicators[256]= " tvunzdmpscfejihg xb*BX GHIJEFCSPMDZNUVT";
  // Holder of error message if any
  static C error_message[256];
  const C* start= types;
  I match;
  indicators[20 + 98]= '+';
  indicators[20 + 99]= '!';
  va_start(args, types);
  for(; *types;){
    match= 0;
    obj= va_arg(args, K);

    if(!obj){
      // Null K object
      // Is this right error message?? Rather "extra type indicator" is better.
      // strcpy(error_message, "incomplete type string ");
      strcpy(error_message, "extra type indicator ");
      break;
    };

    if('[' == *types){
      // Check if it is any type in [].
      while(*types && ']' != *types){
        match= match || indicators[20 + (obj -> t)] == *types;
        // Progress pointer of type array
        ++types;
      }
    }
    else{
      // Specific type indicator 
      match= indicators[20 + (obj -> t)] == *types;
    }

    // Break in case of type mismatch  
    if(!match){
      strcat(strcpy(error_message, "type:expected "), start);
      break;
    };

    // Progress pointer of type array
    ++types;
  }
  va_end(args);

  // Return error if any
  if(!match)
    krr(error_message);

  return match;
}

/**
 * @brief Convert millisecond timestamp to kdb+ nanosecond timestamp.
 * @param timestamp_millis: Timestamp expressed in milliseconds.
 * @return
 * - long: kdb+ timestamp (nanoseconds)
 */
static J millis_to_kdb_nanos(J timestamp_millis){return 1000000LL*(timestamp_millis - KDB_DAY_OFFSET * ONEDAY_MILLIS);}

//%% Index Conversion %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Retrieve client name from a given index.
 * @param index: Index of client.
 * @return
 * - symbol: client name if index is valid
 * - error: error message if index is not valid
 */
rd_kafka_t *clientIndex(K index){
  return (rd_kafka_t *) ((((UI) index->i < CLIENTS->n) && kS(CLIENTS)[index->i]) ? kS(CLIENTS)[index->i] :(S) krr("unknown client"));
}

/**
 * @brief Retrieve index from a given client handle.
 * @param handle: Client handle
 * @return
 * - int: Index of the given client
 * - null int: if the client name is not valid
 */
I indexClient(const rd_kafka_t *handle){
  for (int i = 0; i < CLIENTS->n; ++i){
    if(handle==(rd_kafka_t *)kS(CLIENTS)[i])
      return i;
  }
  
  // If there is no matched client for the handle return null 0Ni
  return ni;
}

/**
 * @brief Retrieve topic object by topic index
 * @param index: Index of topic
 * @return
 * - symbol: Topic
 * - error if index is invalid
 */
rd_kafka_topic_t *topicIndex(K index){
  return (rd_kafka_topic_t *) ((((UI) index->i < TOPICS->n) && kS(TOPICS)[index->i])? kS(TOPICS)[index->i]: (S) krr("unknown topic"));
}


//%% Client %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

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
    return KNULL;
  if('p' != xg && 'c' != xg)
    return krr("type: unknown client type");
  type= 'p' == xg ? RD_KAFKA_PRODUCER : RD_KAFKA_CONSUMER;
  if(!loadConf(conf= rd_kafka_conf_new(), y))
    return KNULL;
  rd_kafka_conf_set_stats_cb(conf, stats_cb);
  rd_kafka_conf_set_log_cb(conf, log_cb);
  if('p' == xg)
    rd_kafka_conf_set_dr_msg_cb(conf, dr_msg_cb);
  else
    rd_kafka_conf_set_offset_commit_cb(conf, offset_commit_cb);
  rd_kafka_conf_set_throttle_cb(conf, throttle_cb);
  rd_kafka_conf_set_error_cb(conf, error_cb);
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
  js(&CLIENTS, (S) rk);
  return ki(CLIENTS->n - 1);
}

EXP K1(kfkdeleteClient){
  rd_kafka_t *rk;
  if(!checkType("i", x))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  rd_kafka_consumer_close(rk);
  rd_kafka_destroy(rk);
  kS(CLIENTS)[x->i]= (S) 0;
  return KNULL;
}

EXP K1(kfkClientName){
  rd_kafka_t *rk;
  if(!checkType("i", x))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  return ks((S) rd_kafka_name(rk));
}

EXP K1(kfkmemberID){
  rd_kafka_t *rk;
  if(!checkType("i", x))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  return ks(rd_kafka_memberid(rk));
}

// topic api
EXP K3(kfkgenerateTopic){
  rd_kafka_topic_t *rkt;
  rd_kafka_t *rk;
  rd_kafka_topic_conf_t *rd_topic_conf;
  if(!checkType("is!",x ,y ,z))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  rd_topic_conf= rd_kafka_topic_conf_new();
  loadTopConf(rd_topic_conf, z);
  rkt= rd_kafka_topic_new(rk, y->s, rd_topic_conf);
  js(&TOPICS, (S) rkt);
  return ki(TOPICS->n - 1);
}

EXP K1(kfkTopicDel){
  rd_kafka_topic_t *rkt;
  if(!checkType("i", x))
    return KNULL;
  if(!(rkt= topicIndex(x)))
    return KNULL;
  rd_kafka_topic_destroy(rkt);
  kS(TOPICS)[x->i]= (S) 0;
  return KNULL;
}

EXP K1(kfkTopicName){
  rd_kafka_topic_t *rkt;
  if(!checkType("i", x))
    return KNULL;
  if(!(rkt= topicIndex(x)))
    return KNULL;
  return ks((S) rd_kafka_topic_name(rkt));
}

//%% Metadata %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// rd_kafka_metadata_broker: `id`host`port!(id;host;port)
K decodeMetaBroker(rd_kafka_metadata_broker_t *x){
  return build_dictionary("id", ki(x->id), "host", ks(x->host), "port", ki(x->port));
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
  return build_dictionary(
            "id", ki(p->id),
            "err", ks((S) rd_kafka_err2str(p->err)),
            "leader", ki(p->leader),
            "replicas", x,
            "isrs", y
         );
}

// rd_kafka_metadata_topic: `topic`partitions`err!(string;partition list;err)
K decodeMetaTopic(rd_kafka_metadata_topic_t *t){
  K x= ktn(0, 0);
  J i;
  for(i= 0; i < t->partition_cnt; ++i)
    jk(&x, decodeMetaPart(&t->partitions[i]));
  return build_dictionary(
            "topic", ks(t->topic), 
            "err", ks((S) rd_kafka_err2str(t->err)),
            "partitions", x
         );
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
  return build_dictionary(
            "orig_broker_id", ki(meta->orig_broker_id),
            "orig_broker_name",ks(meta->orig_broker_name),
            "brokers", x,
            "topics", y
         );
}

EXP K1(kfkMetadata){
  const struct rd_kafka_metadata *meta;
  K r;
  rd_kafka_t *rk;
  if(!checkType("i", x))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  rd_kafka_resp_err_t err= rd_kafka_metadata(rk, 1, NULL, &meta, 5000);
  if(KFK_OK != err)
    return krr((S) rd_kafka_err2str(err));
  r= decodeMeta(meta);
  rd_kafka_metadata_destroy(meta);
  return r;
}

K decode_topic_partition(rd_kafka_topic_partition_t *topic_partition){
  // build dictionary
  return build_dictionary(
            "topic", ks((S) topic_partition->topic),
            "partition", ki(topic_partition->partition),
            "offset", kj(topic_partition->offset), 
            "metadata",kpn(topic_partition->metadata, topic_partition->metadata_size)
          );
}

/**
 * @brief Build a list of topic-partition information dictionaries
 * @param topic_partition_list: Pointer to topic-partition list
 * @return
 * compound list: A list of topic-partition information dictionaries
 */
K decode_topic_partition_list(rd_kafka_topic_partition_list_t *topic_partition_list){
  if(!topic_partition_list){
    // Empty list. Return ()
    return knk(0);
  }
  K list= ktn(0, topic_partition_list->cnt);
  for(J i= 0; i < list->n; ++i){
    // Contain topic-partition information dictionary
    kK(list)[i]= decode_topic_partition(&topic_partition_list->elems[i]);
  }
  return list;
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
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  SW(y->t){
    CS(-KH,qy=y->h);
    CS(-KI,qy=y->i);
    CS(-KJ,qy=y->j);
  }
  rd_kafka_resp_err_t err= rd_kafka_flush(rk,qy);
  if(KFK_OK != err)
    return krr((S) rd_kafka_err2str(err));
  return KNULL;
 }

#if (RD_KAFKA_VERSION >= 0x000b04ff)

EXP K kfkPubWithHeaders(K clientIdx,K topicIdx,K partition,K val,K key,K hdrs){
  rd_kafka_t *rk;
  rd_kafka_topic_t *rkt;
  if(!checkType("iii[CG][CG]!", clientIdx, topicIdx, partition, val, key, hdrs))
    return KNULL;
  if(!(rk= clientIndex(clientIdx)))
    return KNULL;
  if(!(rkt= topicIndex(topicIdx)))
    return KNULL;
  K hdrNames = (kK(hdrs)[0]);
  K hdrValues = (kK(hdrs)[1]);
  if (hdrNames->t != KS && hdrValues->t != 0)
    return krr((S)"Incorrect header type");
  int idx=0;
  for (idx=0;idx<hdrValues->n;++idx)
  {
    K hdrval = kK(hdrValues)[idx];
    if (hdrval->t != KG && hdrval->t != KC)
      return krr((S)"Incorrect header value type");
  }
  rd_kafka_headers_t* msghdrs = rd_kafka_headers_new((int)hdrNames->n);
  for (idx=0;idx<hdrNames->n;++idx)
  {
    K hdrval = kK(hdrValues)[idx];
    if (hdrval->t == KG || hdrval->t == KC)
      rd_kafka_header_add(msghdrs,kS(hdrNames)[idx],-1,hdrval->G0,hdrval->n);
  }
  rd_kafka_resp_err_t err = rd_kafka_producev(
                        rk,
                        RD_KAFKA_V_RKT(rkt),
                        RD_KAFKA_V_PARTITION(partition->i),
                        RD_KAFKA_V_MSGFLAGS(RD_KAFKA_MSG_F_COPY),
                        RD_KAFKA_V_VALUE(kG(val), val->n),
                        RD_KAFKA_V_KEY(kG(key), key->n),
                        RD_KAFKA_V_HEADERS(msghdrs),
                        RD_KAFKA_V_END);
  if (err)
    return krr((S) rd_kafka_err2str(err));
  return KNULL;
}

#else
EXP K kfkPubWithHeaders(K UNUSED(clientIdx),K UNUSED(topicIdx),K UNUSED(partition),K UNUSED(val),K UNUSED(key),K UNUSED(hdrs)) {
  return krr("PubWithHeaders unsupported - please update to librdkafka >= 0.11.4");
}
#endif

//%% Producer %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// producer api
EXP K4(kfkPub){
  rd_kafka_topic_t *rkt;
  if(!checkType("ii[CG][CG]", x, y, z, r))
    return KNULL;
  if(!(rkt= topicIndex(x)))
    return KNULL;
  if(rd_kafka_produce(rkt, y->i, RD_KAFKA_MSG_F_COPY, kG(z), z->n, kG(r), r->n, NULL))
    return krr((S) rd_kafka_err2str(rd_kafka_last_error()));
  return KNULL;
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
    return KNULL;
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
    return KNULL;
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
  return krr("BatchPub unsupported - please update to librdkafka >= 0.11.4");
}

#endif

// consume api
EXP K3(kfkSub){
  rd_kafka_resp_err_t err;
  rd_kafka_t *rk;rd_kafka_topic_partition_list_t *t_partition;
  J i;
  I*p;
  if(!checkType("is[I!]", x, y, z))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  if(KFK_OK != (err = rd_kafka_subscription(rk, &t_partition)))
    return krr((S)rd_kafka_err2str(err));
  if(z->t == XD){
    if(!checkType("IJ", kK(z)[0], kK(z)[1]))
      return KNULL;
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
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
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
    return KNULL;
  if(!checkType("IJ",kK(z)[0],kK(z)[1]))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
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
    return KNULL;
  if(!checkType("IJ",kK(z)[0],kK(z)[1]))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;  
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
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  if(!checkType("IJ",kK(z)[0],kK(z)[1]))
    return KNULL;
  t_partition = rd_kafka_topic_partition_list_new(z->n);
  plistoffsetdict(y->s,z,t_partition);
  if(KFK_OK != (err= rd_kafka_committed(rk, t_partition,5000)))
    return krr((S) rd_kafka_err2str(err));
  r=decode_topic_partition_list(t_partition);
  rd_kafka_topic_partition_list_destroy(t_partition);
  return r;
}

EXP K4(kfkoffsetForTime){
  K t;
  rd_kafka_resp_err_t err;
  rd_kafka_t *rk;rd_kafka_topic_partition_list_t *t_partition;
  I qr=0;
  if(!checkType("is![hij]", x, y, z, r))
    return KNULL;
  if(!checkType("IJ",kK(z)[0],kK(z)[1]))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  SW(r->t){
    CS(-KH, qr=r->h);
    CS(-KI, qr=r->i);
    CS(-KJ, qr=r->j);
  }
  t_partition = rd_kafka_topic_partition_list_new(z->n);
  plistoffsetdict(y->s,z,t_partition);
  if(KFK_OK != (err= rd_kafka_offsets_for_times(rk, t_partition, qr)))
    return krr((S) rd_kafka_err2str(err));
  t=decode_topic_partition_list(t_partition);
  rd_kafka_topic_partition_list_destroy(t_partition);
  return t;
}

EXP K3(kfkPositionOffsets){
  K r;
  rd_kafka_resp_err_t err;
  rd_kafka_t *rk;rd_kafka_topic_partition_list_t *t_partition;
  if(!checkType("is!", x, y, z))
    return KNULL;
  if(!checkType("IJ",kK(z)[0],kK(z)[1]))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  t_partition = rd_kafka_topic_partition_list_new(z->n);
  plistoffsetdict(y->s,z,t_partition); 
  if(KFK_OK != (err= rd_kafka_position(rk, t_partition)))
    return krr((S) rd_kafka_err2str(err));
  r=decode_topic_partition_list(t_partition);
  rd_kafka_topic_partition_list_destroy(t_partition);
  return r;
}

EXP K1(kfkSubscription){
  K r;
  rd_kafka_topic_partition_list_t *t;
  rd_kafka_t *rk;
  rd_kafka_resp_err_t err;
  if (!checkType("i", x))
    return KNULL;
  if (!(rk = clientIndex(x)))
    return KNULL;
  if (KFK_OK != (err= rd_kafka_subscription(rk, &t)))
    return krr((S)rd_kafka_err2str(err));
  r = decode_topic_partition_list(t);
  rd_kafka_topic_partition_list_destroy(t);
  return r;
}

/**
 * @brief Build dictionary from message pointer returned from `rd_kafka_consume*()` family of functions
 *  for the given consumer (client) handle.
 * @param handle: Client handle
 * @param msg: Message pointer returned from `rd_kafka_consume*()` family of functions.
 * @return
 * - dictionary: Information contained in the message.
 */
K decode_message(const rd_kafka_t* handle, const rd_kafka_message_t *msg) {

#if (RD_KAFKA_VERSION >= 0x000b04ff)
  // Retrieve message headers
  rd_kafka_headers_t* hdrs = NULL;
  rd_kafka_message_headers(msg, &hdrs);
  K k_headers = NULL;
  if (hdrs==NULL){
    // Empty header. Empty dictionary
    k_headers = xD(ktn(KS,0), ktn(KS,0));
  }
  else{
    // Non-empty header
    K header_keys = ktn(KS, (int) rd_kafka_header_cnt(hdrs));
    K header_values = knk(0);
    size_t idx = 0;
    // key header name holder
    const char *name;
    // value holder
    const void *value;
    // length holder for value
    size_t size;
    while (!rd_kafka_header_get_all(hdrs, idx++, &name, &value, &size)){
      // add key
      kS(header_keys)[idx-1]=ss((char*) name);
      // add value
      K val = ktn(KG, (int) size);
      memcpy(kG(val), value, (int) size);
      jk(&header_values, val);
    }
    k_headers = xD(header_keys, header_values);
  }
#else
  // Set empty dictionary
  K k_headers = xD(ktn(KS,0),ktn(KS,0));
#endif

  // Retrieve `payload` and `key`
  K payload= ktn(KG, msg->len);
  K key=ktn(KG, msg->key_len);
  memmove(kG(payload), msg->payload, msg->len);
  memmove(kG(key), msg->key, msg->key_len);

  // Millisecond timestamp from epoch
  J timestamp= rd_kafka_message_timestamp(msg, NULL);
  // Convert it to kdb+ timestamp
  K msgtime= ktj(-KP, (timestamp > 0)? millis_to_kdb_nanos(timestamp): nj);

  return build_dictionary_n(9,
            "mtype", msg->err? ks((S) rd_kafka_err2name(msg->err)): r1(S0), 
            "topic", msg->rkt? ks((S) rd_kafka_topic_name(msg->rkt)): r1(S0),
            "client", ki(indexClient(handle)),
            "partition", ki(msg->partition),
            "offset", kj(msg->offset),
            "msgtime", msgtime,
            "data", payload,
            "key", key,
            "headers", k_headers,
            (S) 0);
}

J pollClient(rd_kafka_t *rk, J timeout, J maxcnt) {
  if(rd_kafka_type(rk) == RD_KAFKA_PRODUCER)
    return rd_kafka_poll(rk, timeout);
  K r;
  J n= 0;
  rd_kafka_message_t *msg;
  while((msg= rd_kafka_consumer_poll(rk, timeout))) {
    r= decode_message(rk,msg);
    printr0(k(0, ".kfk.consumecb", r, KNULL));
    rd_kafka_message_destroy(msg);
    ++n;
    /* as n is never 0 in next call, when maxcnt is 0 and MAX_MESSAGES_PER_POLL is 0, doesnt return early */
    /* maxcnt has priority over MAX_MESSAGES_PER_POLL */
    if ((maxcnt==n) || (MAX_MESSAGES_PER_POLL==n && maxcnt==0)) 
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
    return KNULL;
  MAX_MESSAGES_PER_POLL=x->j;
  return kj(MAX_MESSAGES_PER_POLL);
}

// for manual poll of the feed.
EXP K3(kfkPoll){
  J n= 0;
  rd_kafka_t *rk;
  if(!checkType("ijj", x, y, z))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  n=pollClient(rk,y->j,z->j);
  return kj(n);
}


//%% Callback Functions %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Print error if any and release K object.
 * @note
 * Return 0 to indicate mem free to kafka where needed in callback
 */
static I printr0(K response){
  if(!response){
    // null object (success). Nothing to do.
    return 0;
  }
  //else if(KR == response->t){
  else{
    // non-null response (execution error)
    // print error message
    fprintf(stderr, "%s\n", response->s);
    r0(response);
    return 0;
  }    
}

/**
 * @brief Callback function for statistics set by `rd_kafka_conf_set_stats_cb` and triggered from `rd_kafka_poll()` every `statistics.interval.ms`.
 *  Deigate to q function `.kfk.stats_cb`.
 * @param json: String statistics in JSON format
 * @param joson_len: Length of the statistics string.
 */
static I stats_cb(rd_kafka_t *UNUSED(handle), S json, size_t json_len, V *UNUSED(opaque)){
  // Pass string statistics to q
  // Return 0 to indicate mem free to kafka
  return printr0(k(0, (S) ".kfk.stats_cb", kpn(json, json_len), KNULL));
}

/**
 * @brief Callback function to print log set by `rd_kafka_conf_set_log_cb`. Deligate to q function `.kfk.logcb`.
 * @param level: Log level
 * @param fac: WHAT IS THIS??
 * @param buf: WHAT IS THIS??
 */
static void log_cb(const rd_kafka_t *UNUSED(handle), int level, const char *fac, const char *buf){
  printr0(k(0, (S) ".kfk.log_cb", ki(level), kp((S) fac), kp((S) buf), KNULL));
}

/**
 * @brief Callback function for offset commit set by `rd_kafka_conf_set_offset_commit_cb` and triggered by `rd_kafka_consumer_poll()`
 *  for use with consumer groups. Deligate to q function `.kfk.offset_commit_cb`.
 * @param handle Consumer handle.
 * @param error_code: Error code for commit error
 * @param offsets Topic-partiton list
 */
static void offset_commit_cb(rd_kafka_t *handle, rd_kafka_resp_err_t error_code, rd_kafka_topic_partition_list_t *offsets, V *UNUSED(opaque)){
  // Pass client (consumer) index, error message and a list of topic-partition information dictionaries
  printr0(k(0, (S) ".kfk.offset_commit_cb", ki(indexClient(handle)), kp((S) rd_kafka_err2str(error_code)), decode_topic_partition_list(offsets), KNULL));
}

/**
 * @brief Callback function for delivery report set by `rd_kafka_conf_set_dr_msg_cb`. Deligate to q function `.kfk.dr_msg_cb`.
 * @param handle: Producer handle.
 * @param msg: Message pointer to a delivery report.
 * @note
 * - The callback is called when a message is succesfully produced or if librdkafka encountered a permanent failure, or the retry counter
 *  for temporary errors has been exhausted.
 * - Triggered by `rd_kafka_poll()` at regular intervals.
 */
static V dr_msg_cb(rd_kafka_t *handle, const rd_kafka_message_t *msg, V *UNUSED(opaque)){
  // Pass client (producer) index and dictionary of delivery report information
  printr0(k(0, (S) ".kfk.dr_msg_cb", ki(indexClient(handle)), decode_message(handle, msg), KNULL));
}

/**
 * @brief Callback function for error or warning. Deligate to q function `.kfk.error_cb`.
 * @param handle: Client handle.
 * @param error_code: Error code.
 * @param reason: reason for the error.
 * @todo
 * Address this statement? "This function will be triggered with `err` set to `RD_KAFKA_RESP_ERR__FATAL` if a fatal error has been raised.
 *  In this case use rd_kafka_fatal_error() to retrieve the fatal error code and error string, and then begin terminating the client instance."
 */
static V error_cb(rd_kafka_t *handle, int error_code, const char *reason, V *UNUSED(opaque)){
  // Pass client index, error code and reson for the error.
  printr0(k(0, (S) ".kfk.error_cb", ki(indexClient(handle)), ki(error_code), kp((S)reason), KNULL));
}

/**
 * @brief Callback function for throttle time notification to request producing and consuming. Deligate to q function `.kfk.throttle_cb`.
 * @param handle: Client handle.
 * @param brokername: Name of broker.
 * @param brokerid: ID of broker.
 * @param throttle_time_ms: Broker throttle time in milliseconds.
 * @note
 * Callbacks are triggered whenever a non-zero throttle time is returned by the broker, or when the throttle time drops back to zero.
 *  Triggered by `rd_kafka_poll()` or `rd_kafka_consumer_poll()` at regular intervals.
 */
static V throttle_cb(rd_kafka_t *handle, const char *brokername, int32_t brokerid, int throttle_time_ms, V *UNUSED(opaque)){
  // Pass client index, brker name, broker ID and throttle time
  printr0(k(0,(S) ".kfk.throttle_cb", ki(indexClient(handle)), kp((S) brokername), ki(brokerid), ki(throttle_time_ms), KNULL));
}

/* The following set of functions define interactions with the assign functionality with Kafka.
 * This provides more control to the user over where data can be consumed from.
 * Note the differences between Kafka Assign vs Subscribe functionality, summarised in part
 * https://github.com/confluentinc/confluent-kafka-dotnet/issues/278#issuecomment-318858243
*/

/** Define functionality needed for the addition and deletion of topic-partition 
 ** pairs to the current assignment
 * @param dict topic!associated-partitions --> S!J
*/

static V ptlistadd(K dict, rd_kafka_topic_partition_list_t *t_partition){
  K dk=kK(dict)[0],dv=kK(dict)[1];
  S*p;J*o,i;
  p=kS(dk);o=kJ(dv);
  for(i = 0; i < dk->n; i++)
    rd_kafka_topic_partition_list_add(t_partition,p[i],o[i]);
}

static V ptlistdel(K dict,rd_kafka_topic_partition_list_t *t_partition){
  K dk=kK(dict)[0],dv=kK(dict)[1];
  S*p;J*o,i;
  p=kS(dk);o=kJ(dv);
  for(i = 0; i < dk->n; i++)
    rd_kafka_topic_partition_list_del(t_partition,p[i],o[i]);
}

/** Assign the partitions from which to consume data for specified topics
 * @param x Client Index (previously created)
 * @param y Dictionary mapping individual topics to associated partitions. S!J
 * @returns Null value on correct execution
*/

EXP K2(kfkAssignTopPar){
  rd_kafka_t *rk;
  rd_kafka_topic_partition_list_t *t_partition;
  rd_kafka_resp_err_t err;
  if(!checkType("i", x))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  t_partition = rd_kafka_topic_partition_list_new(y->n);
  // topic-partition assignment
  ptlistadd(y,t_partition);
  if(KFK_OK != (err=rd_kafka_assign(rk,t_partition)))
    return krr((S) rd_kafka_err2str(err));
  rd_kafka_topic_partition_list_destroy(t_partition);
  return KNULL;
}

/** Return the current consumption assignment for a specified client
 * @param x Client Index (previously created) 
 * @returns List of dictionaries defining information about the current assignment
*/
EXP K1(kfkAssignment){
  K r;
  rd_kafka_topic_partition_list_t *t;
  rd_kafka_t *rk;
  rd_kafka_resp_err_t err;
  if(!checkType("i", x))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  if(KFK_OK != (err=rd_kafka_assignment(rk, &t)))
    return krr((S)rd_kafka_err2str(err));
  r = decode_topic_partition_list(t);
  rd_kafka_topic_partition_list_destroy(t);
  return r;
}

/** Add to the current assignment for a client with new topic-partition pair
 * @param x Client Index (previously created)
 * @param y Dictionary mapping individual topics to associated partitions. S!J
 * @returns Null value on correct execution
*/

EXP K2(kfkAssignmentAdd){
  rd_kafka_t *rk;
  rd_kafka_topic_partition_list_t *t;
  rd_kafka_resp_err_t err;
  if(!checkType("i", x))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  // retrieve the current assignment
  if(KFK_OK != (err=rd_kafka_assignment(rk, &t)))
    return krr((S)rd_kafka_err2str(err));
  ptlistadd(y,t);
  if(KFK_OK != (err=rd_kafka_assign(rk,t)))
    return krr((S) rd_kafka_err2str(err));
  rd_kafka_topic_partition_list_destroy(t);
  return 0;
}

/** Delete a topic-partition mapped dictionary from the current assignment for a client
 * @param x Client Index (previously created)
 * @param y Dictionary mapping individual topics to associated partitions. S!J
 * @returns Null value on correct execution
*/

EXP K2(kfkAssignmentDel){
  rd_kafka_t *rk;
  rd_kafka_topic_partition_list_t *t;
  rd_kafka_resp_err_t err;
  if(!checkType("i", x))
    return KNULL;
  if(!(rk= clientIndex(x)))
    return KNULL;
  // retrieve the current assignment
  if(KFK_OK != (err=rd_kafka_assignment(rk, &t)))
    return krr((S)rd_kafka_err2str(err));
  ptlistdel(y,t);
  if(KFK_OK != (err=rd_kafka_assign(rk,t)))
    return krr((S) rd_kafka_err2str(err));
  rd_kafka_topic_partition_list_destroy(t);
  return 0;
}


// other
EXP K1(kfkOutQLen){
  rd_kafka_t *rk;
  if(!(rk= clientIndex(x)))
    return KNULL;
  return ki(rd_kafka_outq_len(rk));
}

// logger level is set based on Severity levels in syslog https://en.wikipedia.org/wiki/Syslog#Severity_level
EXP K2(kfkSetLoggerLevel){
  rd_kafka_t *rk;
  I qy=0;
  if(!checkType("i[hij]",x,y))
    return KNULL;
  if(!(rk=clientIndex(x)))
    return KNULL;
  SW(y->t){
    CS(-KH,qy=y->h);
    CS(-KI,qy=y->i);
    CS(-KJ,qy=y->j);
  }
  rd_kafka_set_log_level(rk, qy);
  return KNULL;
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
  for(i= 0; i < CLIENTS->n; i++){
    if(!(((S)0)==kS(CLIENTS)[i]))
      pollClient((rd_kafka_t*)kS(CLIENTS)[i], 0, 0);
  }
  return KNULL;
}

static V detach(V){
  I sp,i;
  if(TOPICS){
    for(i= 0; i < TOPICS->n; i++)
      if(!(((S)0) == kS(TOPICS)[i]))
        kfkTopicDel(ki(i));
    r0(TOPICS);
  }
  if(CLIENTS){
    for(i= 0; i < CLIENTS->n; i++){
      if(!(((S)0) == kS(CLIENTS)[i]))
        kfkdeleteClient(ki(i));
    }
    rd_kafka_wait_destroyed(1000); /* wait for cleanup*/
    r0(CLIENTS);
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
  CLIENTS=ktn(KS,0);
  TOPICS=ktn(KS,0);
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
