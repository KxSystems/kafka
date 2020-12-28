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

/**
 * @brief Type indicators sorted in ascending order by underlying integer values.
 * @note
 * By adding 20 to `arg->t`, the value matches the position in this letters. For example, 't' isnidcates time type whose
 *  integer indicator is -19. Adding 20 to -19 equals 1 and `QTYPE_INDICATORS[1]` matches 't'. Additionally, '+' denotes table
 *  and '!' denotes dictionary.
 */
static const C QTYPE_INDICATORS[256]= " tvunzdmpscfejihg xb*BX GHIJEFCSPMDZNUVT                                                                              +!";

//%% Interface %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Maximum number of polling at execution of `poll_client`. Set `0` by default.
 * @note
 * In order to make this parameter effective, pass `0` for `max_poll_cnt` in `poll_client`.
 */
static J MAXIMUM_NUMBER_OF_POLLING = 0;

/**
 * @brief WHAT IS THIS??
 */
static K S0;

/**
 * @brief Client handles expressed in symbol list
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

//K decode_topic_partition_list(rd_kafka_topic_partition_list_t *t);
//K decode_message(const rd_kafka_t*rk,const rd_kafka_message_t *msg);
K delete_client(K client_idx);

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
 * check_qtype("is!",x ,y ,z)
 * ```
 */
static I check_qtype(const C* types, ...){
  // Holder of variadic
  va_list args;
  // Receiver of K object to test its type
  K obj;
  // Holder of error message if any
  C error_message[256];
  const C* start= types;
  I match;
  va_start(args, types);
  while(*types){
    match= 0;
    obj= va_arg(args, K);

    if(!obj){
      // Null K object. Unexpected end of variables.
      // Return 0 rather than error.
      // This failure will be propagated to q as error by the caller of this function.
      break;
    };

    if('[' == *types){
      // Check if it is any type in [].
      while(*types && ']' != *types){
        match= match || QTYPE_INDICATORS[20 + (obj -> t)] == *types;
        // Progress pointer of type array
        ++types;
      }
    }
    else{
      // Specific type indicator 
      match= QTYPE_INDICATORS[20 + (obj -> t)] == *types;
    }

    // Break in case of type mismatch  
    if(!match){
      // strcat(strcpy(error_message, "type:expected "), start);
      // Return 0 rather than error.
      // This failure will be propagated to q as error by the caller of this function.
      break;
    };

    // Progress pointer of type array
    ++types;
  }
  va_end(args);

  if(!match){
    // Return 0.
    return 0;
  }

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
 * @brief Retrieve client handle from a given index.
 * @param client_idx: Index of client.
 * @return 
 * - symbol: client handle if index is valid
 * - null: error message if index is not valid
 */
rd_kafka_t *index_to_handle(K client_idx){
  if(((UI) client_idx->i < CLIENTS->n) && kS(CLIENTS)[client_idx->i]){
    // Valid client index.
    // Return client handle
    return (rd_kafka_t *) kS(CLIENTS)[client_idx->i];
  }
  else{
    // Index out of range or unregistered client index.
    // Return error.
    char error_message[32];
    sprintf(error_message, "unknown client: %di", client_idx->i);
    return (rd_kafka_t *) krr(error_message);
  }
}

/**
 * @brief Retrieve index from a given client handle.
 * @param handle: Client handle.
 * @return 
 * - int: Index of the given client in `CLIENTS`.
 * - null int: if the client handle is not a registered one.
 */
I handle_to_index(const rd_kafka_t *handle){
  for (int i = 0; i < CLIENTS->n; ++i){
    // Handle is stored as symbol in `CLIENTS` (see `new_client`)
    // Re-cast as handle
    if(handle==(rd_kafka_t *)kS(CLIENTS)[i])
      return i;
  }
  
  // If there is no matched client for the handle, return 0Ni
  return ni;
}

/**
 * @brief Retrieve topic object by topic index
 * @param index: Index of topic
 * @return 
 * - symbol: Topic
 * - error if index is out of range or topic for the index is null
 */
rd_kafka_topic_t *index_to_topic_handle(K topic_idx){
  if(((UI) topic_idx->i < TOPICS->n) && kS(TOPICS)[topic_idx->i]){
    // Valid topic index.
    // Return topic object.
    return (rd_kafka_topic_t *) kS(TOPICS)[topic_idx->i];
  }else{
    // Index out of range or unregistered topic index.
    // Return error.
    char error_message[32];
    sprintf(error_message, "unknown topic: %di", topic_idx->i);
    return (rd_kafka_topic_t *) krr(error_message);
  }
}

//%% Configuration Utility Functions %%//vvvvvvvvvvvvvvvvv/

/**
 * @brief Set configuration in q dictionary on kafka configuration object.
 * @param conf: Destination kafka configuration object.
 * @param q_config: Source q configuration dictionary (symbol -> symbol).
 * @return 
 * - error (nullptr): Failure
 * - empty list: Success
 */
static K load_config(rd_kafka_conf_t *conf, K q_config){
  // Buffer for error message
  char error_message[512];
  for(J i= 0; i < kK(q_config)[0]->n; ++i){
    if(RD_KAFKA_CONF_OK !=rd_kafka_conf_set(conf, kS(kK(q_config)[0])[i], kS(kK(q_config)[1])[i], error_message, sizeof(error_message))){
      return krr((S) error_message);
    }
  }
  // Arbitrary value `()` other than nullptr so that caller of this function can tell error(`krr`) and success
  return knk(0);
}

/**
 * @brief Set topic configuration in q dictionary on kafka topic configuration object.
 * @param tpc_conf: Destination kafka topic configuration object
 * @param q_tpc_config: Source q topic configuration dictionary (symbol -> symbol).
 * @return 
 * - error (nullptr): Failure
 * - empty list: Success
 */
static K load_topic_config(rd_kafka_topic_conf_t *tpc_conf, K q_tpc_config){
  // Buffer for error message
  char error_message[512];
  for(J i= 0; i < kK(q_tpc_config)[0]->n; ++i){
    if(RD_KAFKA_CONF_OK !=rd_kafka_topic_conf_set(tpc_conf, kS(kK(q_tpc_config)[0])[i], kS(kK(q_tpc_config)[1])[i], error_message, sizeof(error_message)))
      return krr((S) error_message);
  }
  // Arbitrary value `()` other than nullptr so that caller of this function can tell error(`krr`) and success
  return knk(0);
}

//%% Topic-partition Utility Functions %%//vvvvvvvvvvvvvvv/

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

/**
 * @brief Add pairs of specific topic and given partitions for the topic to a given topic-partition list and set given offsets on sepcified partitions.
 * @param topic: Topic of partitions to which offsets are set.
 * @param partition_to_offset: q dictionary (map) from partition to offset (i -> j).
 * @param topic_partitions: A list of pairs of topic and partition.
 */
static void extend_topic_partition_list_and_set_offset_for_topic(S topic, K partition_to_offset, rd_kafka_topic_partition_list_t *topic_partitions){
  J n=kK(partition_to_offset)[0]->n;
  I *partitions=kI(kK(partition_to_offset)[0]);
  J *offsets=kJ(kK(partition_to_offset)[1]);
  for(J i=0; i < n; ++i){
    // Add a new pair of topic and partition to topic-partition list
    rd_kafka_topic_partition_list_add(topic_partitions, topic, partitions[i]);
    // Set offset on the pair of topic and partition
    rd_kafka_topic_partition_list_set_offset(topic_partitions, topic, partitions[i], offsets[i]);
  }
}

/**
 * @brief Add a list of pairs of topic and partition to a topic-partition list.
 * @param topic_to_part: Dictionary mapping from topic to partition (s -> i).
 */
static void extend_topic_partition_list(K topic_to_part, rd_kafka_topic_partition_list_t *t_partition){

  // Length of keys
  J n=kK(topic_to_part)[0]->n;
  S *topics=kS(kK(topic_to_part)[0]);
  J *partitions=kJ(kK(topic_to_part)[1]);
  for(J i = 0; i < n; i++){
    // Add a pair of topic and partition to the given list
    rd_kafka_topic_partition_list_add(t_partition, topics[i], partitions[i]);
  } 
}

/**
 * @brief Delete given pairs of topic and partition from the given topic-partitions.
 * @param topic_to_part: q dictionary mapping from topic to partition (s -> i).
 * @param topic_partitions: list of topic-partitons.
 */
static void delete_elems_from_topic_partition_list(K topic_to_part, rd_kafka_topic_partition_list_t *topic_partitions){
  // Length of keys
  J n=kK(topic_to_part)[0]->n;
  S* topics= kS(kK(topic_to_part)[0]);
  J* partitions=kJ(kK(topic_to_part)[1]);
  for(J i = 0; i < n; i++){
    // Delete a pair of topic and partition from the given list
    rd_kafka_topic_partition_list_del(topic_partitions, topics[i], partitions[i]);
  }
}


//%% Metadata %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Get broker's information from kafka broker object.
 * @param broker: A pointer pointing to kafka broker.
 * @return 
 * - dictionary: Dictionary containing broker information of ID, host and port.
 *   - id: symbol | Broker ID
 *   - host symbol | Broker host
 *   - port: int | Broker port
 */
K decode_metadata_broker(rd_kafka_metadata_broker_t *broker){
  return build_dictionary("id", ki(broker->id), "host", ks(broker->host), "port", ki(broker->port));
}

/**
 * @brief Get information of a given partition.
 * @param partition: A pointer to a kafka partition.
 * @return 
 * - dictionary: Dictionary containing partiotion information of ID, error code, leader, replicas and in-sync-replicas. 
 *   - id: int | Partition ID
 *   - err: symbol | Error message
 *   - leader: int | leader
 *   - replicas: list of int | Replicas
 *   - isrs: list of int | In-sync-replicas
 */
K decode_metadata_partition(rd_kafka_metadata_partition_t *partition){

  // Container of replicas
  K replicas= ktn(KI, partition->replica_cnt);
  for(J i= 0; i < replicas->n; ++i){
    // Contain replica ID
    kI(replicas)[i] = partition->replicas[i];
  }
    
  // Conatiner of in-sync-replicas
  K in_sync_replicas = ktn(KI, partition->isr_cnt);
  for(J i= 0; i < partition->isr_cnt; ++i){
    // Contain In-symc replica ID 
    kI(in_sync_replicas)[i]= partition->isrs[i];
  }
    
  return build_dictionary(
            "id", ki(partition->id),
            "err", ks((S) rd_kafka_err2str(partition->err)),
            "leader", ki(partition->leader),
            "replicas", replicas,
            "isrs", in_sync_replicas
         );
}

/**
 * @brief Get information of a given topic.
 * @param topic: A topic.
 * @return 
 * - dictionary: Dictionary containing information of topic name, error and partitions.
 *   - topic: symbol | Topic name
 *   - err: symbol | Error message
 *   - partitions: list of dictionary | Information of partitions
 */
K decode_metadata_topic(rd_kafka_metadata_topic_t *topic){
  // Container of topic information
  K partitions= ktn(0, 0);
  for(J i= 0; i < topic->partition_cnt; ++i){
    // Contain information of partitions
    jk(&partitions, decode_metadata_partition(&topic->partitions[i]));
  }
    
  return build_dictionary(
            "topic", ks(topic->topic), 
            "err", ks((S) rd_kafka_err2str(topic->err)),
            "partitions", partitions
         );
}

/**
 * @brief Get information of broker and topic.
 * @param meta: A pointer to a kafka meta data.
 * @return 
 * - dictionary: Information of original broker, brokers and topics.
 *   - orig_broker_id: int | Broker originating this meta data
 *   - orig_broker_name | symbol | Name of originating broker
 *   - brokers: list of dictionary | Information of brokers
 *   - topics: list of dictionary | Infomation of topics
 */
K decode_metadata(const rd_kafka_metadata_t *meta) {
  // Container of broker information
  K brokers= ktn(0, 0);
  for(J i= 0; i < meta->broker_cnt; ++i){
    //Contain information of brokers
    jk(&brokers, decode_metadata_broker(&meta->brokers[i]));
  }
    
  K topics= ktn(0, 0);
  for(J i= 0; i < meta->topic_cnt; ++i){
    // Contain information of topics
    jk(&topics, decode_metadata_topic(&meta->topics[i]));
  }

  return build_dictionary(
            "orig_broker_id", ki(meta->orig_broker_id),
            "orig_broker_name",ks(meta->orig_broker_name),
            "brokers", brokers,
            "topics", topics
         );
}



// producer api
EXP K4(kfkPub){
  rd_kafka_topic_t *rkt;
  if(!check_qtype("ii[CG][CG]", x, y, z, r))
    return KNULL;
  if(!(rkt= index_to_topic_handle(x)))
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
 * @return  Integer list with a status for each send message (zero indicates success) 
 *          reference: https://github.com/edenhill/librdkafka/blob/master/src/rdkafka.h (rd_kafka_resp_err_t)
 */

#if (RD_KAFKA_VERSION >= 0x000b04ff)

EXP K4(kfkBatchPub){
  rd_kafka_topic_t *rkt;
  if(!check_qtype("i[iI]*[CG*]", x, y, z, r))
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
  if(!(rkt= index_to_topic_handle(x)))
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
  if(!check_qtype("is[I!]", x, y, z))
    return KNULL;
  if(!(rk= index_to_handle(x)))
    return KNULL;
  if(KFK_OK != (err = rd_kafka_subscription(rk, &t_partition)))
    return krr((S)rd_kafka_err2str(err));
  if(z->t == XD){
    if(!check_qtype("IJ", kK(z)[0], kK(z)[1]))
      return KNULL;
    extend_topic_partition_list_and_set_offset_for_topic(y->s,z,t_partition);
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
  if(!check_qtype("i", x))
    return KNULL;
  if(!(rk= index_to_handle(x)))
    return KNULL;
  err= rd_kafka_unsubscribe(rk);
  if(KFK_OK != err)
    return krr((S) rd_kafka_err2str(err));
  return knk(0);
}

// https://github.com/edenhill/librdkafka/wiki/Manually-setting-the-consumer-start-offset

/**
 * @brief Set new offsets on partitions of a given topic for a given client.
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic of partitions to which assign offsets.
 * @param new_part_to_offset: q dictionary (map) from partition to offsets (int -> long).
 */
EXP K assign_new_offsets_to_topic_partition(K consumer_idx, K topic, K new_part_to_offset){
  
  if(!check_qtype("is!", consumer_idx, topic, new_part_to_offset)){
    // Argument types do not match required types
    return krr("consumer index, topic and new offset must be (int; symbol; dictionary) type.");
  }

  if(!check_qtype("IJ", kK(new_part_to_offset)[0], kK(new_part_to_offset)[1])){
    // Partitions are not int or offsets are not long
    return krr("partitions, offsets must be (int; long) type.");
  }

  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  // Create a new topic-partition list.
  rd_kafka_topic_partition_list_t *new_topic_partitions = rd_kafka_topic_partition_list_new(new_part_to_offset->n);
  
  // Extend the new topic-partitions with the pair of given topic and partitions for the topic and set offsets to specified partitions.
  extend_topic_partition_list_and_set_offset_for_topic(topic->s, new_part_to_offset, new_topic_partitions);
  
  // Assign the new topic-partitions to the concumer (client)
  rd_kafka_resp_err_t error = rd_kafka_assign(handle, new_topic_partitions);
  if(KFK_OK != error){
    // Error happened in assign. Return error.
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Discard allocated topic-partition list which is no longer necessary
  rd_kafka_topic_partition_list_destroy(new_topic_partitions);

  return KNULL;
}

/**
 * @brief Commit new offsets on partitions of a given topic for a given client.
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic of partitions to which assign offsets.
 * @param new_part_to_offset: q dictionary (map) from partition to offsets (int -> long).
 * @param is_async: True to process asynchronusly. If `is_async` is false this operation will
 *  block until the broker offset commit is done.
 */
EXP K commit_new_offsets_to_topic_partition(K consumer_idx, K topic, K new_part_to_offset, K is_async){

  if(!check_qtype("is!b", consumer_idx, topic, new_part_to_offset, is_async)){
    // Argument types do not match required types
    return krr("consumer index, topic, new offset and is_async must be (int; symbol; dictionary; bool) type.");
  }
  
  if(!check_qtype("IJ", kK(new_part_to_offset)[0], kK(new_part_to_offset)[1])){
    // Partitions are not int or offsets are not long
    return krr("partitions, offsets must be (int; long) type.");
  }
  
  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  // Create a new topic-partition list.
  rd_kafka_topic_partition_list_t *new_topic_partitions =  rd_kafka_topic_partition_list_new(new_part_to_offset->n);
  
  // Extend the new topic-partitions with the pair of given topic and partitions for the topic and set offsets to specified partitions.
  extend_topic_partition_list_and_set_offset_for_topic(topic->s, new_part_to_offset, new_topic_partitions);
  
  // Commit the new topic-partitions
  rd_kafka_resp_err_t error=rd_kafka_commit(handle, new_topic_partitions, is_async->g);
  if(KFK_OK != error){
    // Error happened in commit. Return error.
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Discard allocated topic-partition list which is no longer necessary
  rd_kafka_topic_partition_list_destroy(new_topic_partitions);

  return KNULL;
}

/**
 * @brief Get latest commited offset for a given topic and partitions for a client (consumer).
 * @param cousumer_idx: Index of client (consumer) in `CLIENTS`.
 * @param topic: Topic of partitions to which assign offsets.
 * @param partitions: List of partitions.
 * @return 
 * - list of dictionary: List of dictionary of partition and offset
 */
EXP K get_committed_offsets_for_topic_partition(K consumer_idx, K topic, K partitions){
  
  if(!check_qtype("isJ", consumer_idx, topic, partitions)){
    // Argument types do not match required types
    return krr("consumer index, topic and new offset must be (int; symbol; list of long) type.");
  }
  
  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  // The number of partitions
  J n=partitions->n;
  // Create a new topic-partition list.
  rd_kafka_topic_partition_list_t *new_topic_partitions = rd_kafka_topic_partition_list_new(n);

  // Build holder of sffset in form of dictionary
  K topics=ktn(KS, n);
  for(J i=0; i < n; i++){
    kS(topics)[i]=ss(topic->s);
  }
  K topic_to_par=xD(topics, partitions);
  // Extend the new topic-partitions with the pair of given topic and partitions for the topic and set offsets to specified partitions.
  extend_topic_partition_list(topic_to_par, new_topic_partitions);
  // Discard K objects which are no longer necessary
  r0(topics);
  r0(topic_to_par);
  
  // Get committed offset and take them into `new_topic_partitions` with timeout in 5 seconds
  rd_kafka_resp_err_t error = rd_kafka_committed(handle, new_topic_partitions, 5000);
  if(KFK_OK != error){
    // Error hapened in getting committed offsets. Return error.
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Convert to list of q dictionary
  K committed=decode_topic_partition_list(new_topic_partitions);

  // Discard allocated topic-partition list which is no longer necessary
  rd_kafka_topic_partition_list_destroy(new_topic_partitions);

  return committed;
}

EXP K4(kfkoffsetForTime){
  K t;
  rd_kafka_resp_err_t err;
  rd_kafka_t *rk;rd_kafka_topic_partition_list_t *t_partition;
  I qr=0;
  if(!check_qtype("is![hij]", x, y, z, r))
    return KNULL;
  if(!check_qtype("IJ",kK(z)[0],kK(z)[1]))
    return KNULL;
  if(!(rk= index_to_handle(x)))
    return KNULL;
  SW(r->t){
    CS(-KH, qr=r->h);
    CS(-KI, qr=r->i);
    CS(-KJ, qr=r->j);
  }
  t_partition = rd_kafka_topic_partition_list_new(z->n);
  extend_topic_partition_list_and_set_offset_for_topic(y->s,z,t_partition);
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
  if(!check_qtype("is!", x, y, z))
    return KNULL;
  if(!check_qtype("IJ",kK(z)[0],kK(z)[1]))
    return KNULL;
  if(!(rk= index_to_handle(x)))
    return KNULL;
  t_partition = rd_kafka_topic_partition_list_new(z->n);
  extend_topic_partition_list_and_set_offset_for_topic(y->s,z,t_partition); 
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
  if (!check_qtype("i", x))
    return KNULL;
  if (!(rk = index_to_handle(x)))
    return KNULL;
  if (KFK_OK != (err= rd_kafka_subscription(rk, &t)))
    return krr((S)rd_kafka_err2str(err));
  r = decode_topic_partition_list(t);
  rd_kafka_topic_partition_list_destroy(t);
  return r;
}

/**
 * @brief Build dictionary from message pointer returned from `rd_kafka_consume*()` family of functions
 *  for the given client handle.
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
            "client", ki(handle_to_index(handle)),
            "partition", ki(msg->partition),
            "offset", kj(msg->offset),
            "msgtime", msgtime,
            "data", payload,
            "key", key,
            "headers", k_headers,
            (S) 0);
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
  else if(KR == response->t){
    // execution error)
    // print error message
    fprintf(stderr, "%s\n", response->s);
  }
  else{
    // Not sure what case is this.
    // nothing to do.
  }
  r0(response);
  return 0;
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
  printr0(k(0, (S) ".kfk.offset_commit_cb", ki(handle_to_index(handle)), kp((S) rd_kafka_err2str(error_code)), decode_topic_partition_list(offsets), KNULL));
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
  printr0(k(0, (S) ".kfk.dr_msg_cb", ki(handle_to_index(handle)), decode_message(handle, msg), KNULL));
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
  printr0(k(0, (S) ".kfk.error_cb", ki(handle_to_index(handle)), ki(error_code), kp((S)reason), KNULL));
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
  printr0(k(0,(S) ".kfk.throttle_cb", ki(handle_to_index(handle)), kp((S) brokername), ki(brokerid), ki(throttle_time_ms), KNULL));
}

//%% Poll %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Poll producer or consumer with timeout (and a limitation of the number of polling for consumer).
 * @param handle: Client handle.
 * @param timeout: The maximum amount of time (in milliseconds) that the call will block waiting for events.
 * - 0: non-blocking
 * - -1: wait indefinitely
 * - others: wait for this period
 * @param max_poll_cnt: The maximum number of polls, in turn the number of messages to get.
 * @return 
 * - int: The number of messages retrieved (poll count).
 */
J poll_client(rd_kafka_t *handle, I timeout, J max_poll_cnt) {
  if(rd_kafka_type(handle) == RD_KAFKA_PRODUCER){
    // Main poll for producer
    return rd_kafka_poll(handle, timeout);
  }
  else{
    // Polling for consumer
    // Counter of the number of polling
    J n= 0;
    // Holder of message from polling
    rd_kafka_message_t *message;
    // Holder of q message converted from message
    K q_message;

    while((message= rd_kafka_consumer_poll(handle, timeout))){
      // Poll and retrieve message while message is not empty
      q_message= decode_message(handle, message);
      // Call `.kfk.consume_cb` passing client index and message information dictionary
      printr0(k(0, ".kfk.consume_cb", ki(handle_to_index(handle)), q_message, KNULL));
      // Discard message which is not necessary any more
      rd_kafka_message_destroy(message);

      // Increment the poll counter
      ++n;

      // Argument `max_poll_cnt` has priority over MAXIMUM_NUMBER_OF_POLLING
      if ((n == max_poll_cnt) || (n == MAXIMUM_NUMBER_OF_POLLING && max_poll_cnt==0)){
        // The counter of polling reacched specified `max_poll_cnt` or globally set `MAX_MESSAGES_PER_POLL`.
        char data = 'Z';
        send(spair[1], &data, 1, 0);
        // Return the number of mesasges
        return n;
      }
    }
    // Return the number of mesasges
    return n;
  }
  
}



// other
EXP K1(kfkOutQLen){
  rd_kafka_t *rk;
  if(!(rk= index_to_handle(x)))
    return KNULL;
  return ki(rd_kafka_outq_len(rk));
}

// logger level is set based on Severity levels in syslog https://en.wikipedia.org/wiki/Syslog#Severity_level
EXP K2(kfkSetLoggerLevel){
  rd_kafka_t *rk;
  I qy=0;
  if(!check_qtype("i[hij]",x,y))
    return KNULL;
  if(!(rk=index_to_handle(x)))
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
  return xT(build_dictionary("errid", x, "code", y, "desc", z));
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
      poll_client((rd_kafka_t*)kS(CLIENTS)[i], 0, 0);
  }
  return KNULL;
}

static V detach(V){
  I sp,i;
  if(TOPICS){
    for(i= 0; i < TOPICS->n; i++)
      if(!(((S)0) == kS(TOPICS)[i]))
        delete_topic(ki(i));
    r0(TOPICS);
  }
  if(CLIENTS){
    for(i= 0; i < CLIENTS->n; i++){
      if(!(((S)0) == kS(CLIENTS)[i]))
        delete_client(ki(i));
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

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Initializer %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

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

//%% Client %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Create a client based on a given client type (producer or consumer) and a given configuration.
 * @param client_type:
 * - "p": Producer
 * - "c": Consumer
 * @param q_config: Dictionary containing a configuration.
 * @return 
 * - error: If passing client type which is neither of "p" or "c". 
 * - int: Client index.
 */
EXP K new_client(K client_type, K q_config){

  // Buffer for error message
  char error_message[512];

  if(!check_qtype("c!", client_type, q_config)){
    // Argument type does not match char and dictionary
    return krr("client type and config must be (char; dictionary) type.");
  }
    
  if('p' != client_type->g && 'c' != client_type->g){
    // Neither of producer nor consumer
    char wrongtype[2]={client_type->g, '\0'};
    return krr(strcat("type: unknown client type: ", wrongtype));
  }

  // Set client type
  rd_kafka_type_t type=('p' == client_type->g)? RD_KAFKA_PRODUCER: RD_KAFKA_CONSUMER;
  
  rd_kafka_conf_t *conf=rd_kafka_conf_new();
  K res=load_config(conf, q_config);
  if(!res){
    // Null result. Error in loading the q configuration.
    return (K) res;
  }
  
  // Set callback functions
  if(type == RD_KAFKA_PRODUCER){
    // Set delivery report callback for producer
    rd_kafka_conf_set_dr_msg_cb(conf, dr_msg_cb);
  }
  else{
    // Set offset commit callback for consumer
    rd_kafka_conf_set_offset_commit_cb(conf, offset_commit_cb);
  }
  rd_kafka_conf_set_stats_cb(conf, stats_cb);
  rd_kafka_conf_set_log_cb(conf, log_cb);
  rd_kafka_conf_set_throttle_cb(conf, throttle_cb);
  rd_kafka_conf_set_error_cb(conf, error_cb);

  // Set `log.queue` property true
  if(RD_KAFKA_CONF_OK != rd_kafka_conf_set(conf, "log.queue", "true", error_message, sizeof(error_message))){
    // Error in set `log.queue` property
    return krr((S) error_message);
  }

  // Create handle from the configuration
  rd_kafka_t *handle=rd_kafka_new(type, conf, error_message, sizeof(error_message));
  if(!handle){
    // Error in creating a client
    return krr(error_message);
  }

  // Redirect logs to main queue
  rd_kafka_set_log_queue(handle, NULL);

  if(type == RD_KAFKA_CONSUMER){
    // Redirect `rd_kafka_poll()` to `consumer_poll()`
    rd_kafka_poll_set_consumer(handle);
    // create a separate file-descriptor to which librdkafka will write payload (of size size) whenever a new element is enqueued on a previously empty queue.
    // Consumer gets from consumer queue
    rd_kafka_queue_io_event_enable(rd_kafka_queue_get_consumer(handle), spair[1], "X", 1);
  }
  else{
    // Producer gets from main queue
    rd_kafka_queue_io_event_enable(rd_kafka_queue_get_main(handle), spair[1], "X", 1);
  }

  // Store client hande as symbol
  // IS THIS SAFE? Use `ss`?
  // Why symbol rather than integer?
  // Must reuse 0 hole instead of appending tpo the tail
  js(&CLIENTS, (S) handle);

  // Return client index as int
  return ki(CLIENTS->n - 1);
}

/**
 * @brief Destroy client handle and remove from `CLIENTS`.
 * @param client_idx: Index of client in `CLIENTS`.
 */
EXP K delete_client(K client_idx){
  
  if(!check_qtype("i", client_idx)){
    // argument type is not int
    return krr("client index must be int type.");
  }
  rd_kafka_t *handle=index_to_handle(client_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  if(rd_kafka_type(handle) == RD_KAFKA_CONSUMER){
    // For consumer, close first.
    rd_kafka_consumer_close(handle);
  }
  // Destroy cient handle
  rd_kafka_destroy(handle);

  // Fill hole with 0
  // This hole must be resused.
  kS(CLIENTS)[client_idx->i]= (S) 0;

  return KNULL;
}

/**
 * @brief Get a name of client from client index.
 * @param client_index: Index of client in `CLIENTS`.
 * @return 
 * - symbol: Handle name of the client denoted by the given index.
 */
EXP K get_client_name(K client_index){
  
  if(!check_qtype("i", client_index)){
    // client_index is not int
    return krr("client index must be int type.");
  }
  
  // Get cient hande from index
  rd_kafka_t *handle = index_to_handle(client_index);
  if(!handle){
    // Null pointer (`krr`). Error in `index_to_client()`.
    return (K) handle;
  }

  //Return handle name
  return ks((S) rd_kafka_name(handle));
  
}

/**
 * @brief Get the broker-assigned group member ID of the client (consumer).
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @return 
 * - symbol: Broker-assigned group member ID.
 */
EXP K get_consumer_group_member_id(K consumer_idx){
  
  if(!check_qtype("i", consumer_idx)){
    // client_index is not int
    return krr("client index must be int type.");
  }

  rd_kafka_t *handle=index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error in `index_to_client()`.
    return (K) handle;
  }
  
  if(rd_kafka_type(handle) == RD_KAFKA_CONSUMER){
    // Return the consumer's broker-assigned group member ID.
    return ks(rd_kafka_memberid(handle));
  }
  else{
    // Producer is not supported. Return error.
    return krr("nyi - producer memberID is not feasible.");
  }
}


//%% Poll %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Poll client manually.
 * @param client_idx: Client index in `CLIENTS`.
 * @param timeout: The maximum amount of time (in milliseconds) that the call will block waiting for events.
 * - 0: non-blocking
 * - -1: wait indefinitely
 * - others: wait for this period
 * @param max_poll_cnt: The maximum number of polls, in turn the number of messages to get.
 * @return 
 * - long: The number of messages retrieved (poll count).
 */
EXP K manual_poll(K client_idx, K timeout, K max_poll_cnt){
  
  if(!check_qtype("ijj", client_idx, timeout, max_poll_cnt)){
    // The argument types do not match (int; long; long)
    return krr("cient index, timeout and maximum poll count must be (int; long; long) type.");
  }
  
  rd_kafka_t *handle=index_to_handle(client_idx);
  if(!handle){
    // Null pointer from `krr`. Error happened in `index_to_handle`.
    // Return the error.
    return (K) handle;
  }
    
  // Poll producer or consumer
  J n=poll_client(handle, timeout->j, max_poll_cnt->j);
  // Return the number of messages (poll count)
  return kj(n);
}

/**
 * @brief Set a new number on `MAXIMUM_NUMBER_OF_POLLING`.
 * @param n: The maximum number of polling at execution of `poll_client()` or `manual_poll()`.
 */
EXP K set_maximum_number_of_polling(K n){
  if(!check_qtype("j", n)){
    // Return error for non-long type
    return krr("limit must be long type.");
  }
  // Set new upper limit
  MAXIMUM_NUMBER_OF_POLLING=n->j;
  // Return the new value
  return kj(MAXIMUM_NUMBER_OF_POLLING);
}

//%% Assign %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/* 
 * The following set of functions define interactions with the assign functionality with Kafka.
 * This provides more control to the user over where data can be consumed from.
 * Note the differences between Kafka Assign vs Subscribe functionality, summarised in part
 * https://github.com/confluentinc/confluent-kafka-dotnet/issues/278#issuecomment-318858243
 */

/**
 * @brief Assign a new map from topic to partition for consumption of message to a client.
 *  Client will consume from the specified partition for the specified topic.
 * @param consumer_idx: Index of client in `CLIENTS`.
 * @param topic_to_partiton: Dictionary mapping from topic to partition.
 * @note
 * This function will replace existing mapping.
 */
EXP K assign_new_topic_partition(K consumer_idx, K topic_to_partiton){
  
  if(!check_qtype("i", consumer_idx)){
    // consumer_idx is not int.
    return krr("consumer index must be int type.");
  }
  
  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  // Create a new topic-partition map.
  rd_kafka_topic_partition_list_t * new_topic_partitions = rd_kafka_topic_partition_list_new(topic_to_partiton->n);
  // Extend the new map with the given pairs of topics and partitions
  extend_topic_partition_list(topic_to_partiton, new_topic_partitions);

  // Assign the new topic-partiton map. 
  rd_kafka_resp_err_t error=rd_kafka_assign(handle, new_topic_partitions);
  if(KFK_OK != error){
    // Error happened in assign. Return error.
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Destroy the allocated map no longer necessary
  rd_kafka_topic_partition_list_destroy(new_topic_partitions);

  return KNULL;
}

/** 
 * @brief Return the current consumption assignment for a specified client
 * @param consumer_idx: Index of client (consumer) in `CLIENTS`.
 * @return 
 * - list of dictionaries: List of information of topic-partitions.
 */
EXP K get_current_assignment(K consumer_idx){

  if(!check_qtype("i", consumer_idx)){
    // consumer_idx is not int.
    return krr("consumer index must be int type.");
  }

  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  // Holder of current topic-partitions
  rd_kafka_topic_partition_list_t *topic_partitions;
  // Get current assignment information into `topic_partitions`
  rd_kafka_resp_err_t error=rd_kafka_assignment(handle, &topic_partitions);
  if(KFK_OK != error){
    // Error happened in getting information. Return error.
    return krr((S)rd_kafka_err2str(error));
  }
  // Convert into q dictionary
  K current_assignment = decode_topic_partition_list(topic_partitions);

  // Destroy the allocated map no longer necessary
  rd_kafka_topic_partition_list_destroy(topic_partitions);

  return current_assignment;
}

/**
 * @brief Add pairs of topic and partition to the current assignment for a given lient.
 * @param consumer_idx: Index of cient (consumer) in `CLIENTS`.
 * @param topic_to_part: Dictionary mapping from topic to partition to add (s -> i).
 */
EXP K add_topic_partion(K consumer_idx, K topic_to_part){

  rd_kafka_resp_err_t err;
  if(!check_qtype("i", consumer_idx)){
    // consumer_idx is not int.
    return krr("consumer index must be int type.");
  }

  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_cient`.
    return (K) handle;
  }

  // Holder of current topic-partitions
  rd_kafka_topic_partition_list_t *topic_partitions;
  // Get current assignment information into `topic_partitions`
  rd_kafka_resp_err_t error=rd_kafka_assignment(handle, &topic_partitions);
  if(KFK_OK !=error){
    // Error happened in getting information. Return error.
    return krr((S)rd_kafka_err2str(error));
  }

  // Add new pairs of topic and partition to current list
  extend_topic_partition_list(topic_to_part, topic_partitions);

  // Assign the new topic-partiton map. 
  error=rd_kafka_assign(handle, topic_partitions);
  if(KFK_OK != error){
    // Error happened in assign. Return error.
    return krr((S) rd_kafka_err2str(error));
  }

  // Destroy the allocated map no longer necessary
  rd_kafka_topic_partition_list_destroy(topic_partitions);

  return KNULL;
}

/**
 * @brief Delete pairs of topic and partition from the current assignment for a client.
 * @param consumer_idx: Index of cient (consumer) in `CLIENTS`.
 * @param topic_to_part: Dictionary mapping from topic to partition to delete (s -> i).
 */
EXP K delete_topic_partition(K consumer_idx, K topic_to_part){

  if(!check_qtype("i", consumer_idx)){
    // consumer_idx is not int.
    return krr("consumer index must be int type.");
  }

  rd_kafka_t *handle = index_to_handle(consumer_idx);
  if(!handle){
    // Null pointer (`krr`). Error happened in `index_to_handle`.
    return (K) handle;
  }

  // Holder of current topic-partitions
  rd_kafka_topic_partition_list_t *topic_partitions;
  // Get current assignment information into `topic_partitions`
  rd_kafka_resp_err_t error=rd_kafka_assignment(handle, &topic_partitions);
  if(KFK_OK !=error){
    // Error happened in getting information. Return error.
    return krr((S)rd_kafka_err2str(error));
  }

  // Delete given pairs of topic and partition from current list
  delete_elems_from_topic_partition_list(topic_to_part, topic_partitions);

  // Assign the new topic-partiton map. 
  error=rd_kafka_assign(handle, topic_partitions);
  if(KFK_OK != error){
    // Error happened in assign. Return error.
    return krr((S) rd_kafka_err2str(error));
  }

  // Destroy the allocated map no longer necessary
  rd_kafka_topic_partition_list_destroy(topic_partitions);

  return KNULL;
}

//%% Topic %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Create a new topic.
 * @param client_idx: index of client in `CLIENTS`.
 * @param topic: New topic to create.
 * @param q_config: q dictionary storing configuration of the new topic (symbol -> symbol).
 * @return 
 * - int: Topic handle assigned by kafka.
 */
EXP new_topic(K client_idx, K topic, K q_config){

  if(!check_qtype("is!", client_idx, topic, q_config)){
    // Argument types do not match expected types
    return krr("client index, topic and configuration must be (int; symbol; dictionary)");
  }

  rd_kafka_t *handle=index_to_handle(client_idx);
  if(!handle){
    // Null pointer (`krr`). Error in `index_to_handle()`.
    return (K) handle;
  }

  // Holder of kafka configuration object
  rd_kafka_topic_conf_t *config= rd_kafka_topic_conf_new();
  // Load configuration from q configuration object to the holder
  load_topic_config(config, q_config);

  rd_kafka_topic_t *new_topic = rd_kafka_topic_new(handle, topic->s, config);

  // Store new topic handle at the tail of `TOPICS`
  // Why symbol rather than int?
  js(&TOPICS, (S) new_topic);

  // Return topic handle as int
  return ki(TOPICS->n - 1);
}

/**
 * @brief Delete the given topic.
 * @param topic_idx: Index of topic in `TOPICS`.
 */
EXP K delete_topic(K topic_idx){
  
  if(!check_qtype("i", topic_idx)){
    // topic index is not int
    return krr("topic index must be int type.");
  }

  rd_kafka_topic_t *topic_handle=index_to_topic_handle(topic_idx);
  if(!topic_handle){
    // Nul pointer (`krr`). Error happened in `index_to_topic_handle()`.
    return (K) topic_handle;
  }

  // Delete topic
  rd_kafka_topic_destroy(topic_handle);

  // Fill the hole with 0.
  // This hole must be resused.
  kS(TOPICS)[topic_idx->i]= (S) 0;

  return KNULL;
}

/**
 * @brief Get a name of topic from topic index.
 * @param topic_idx: Index of topic in `TOPICS`.
 * @return 
 * - symbol: Topic name.
 */
EXP K get_topic_name(K topic_idx){
  rd_kafka_topic_t *rkt;
  if(!check_qtype("i", topic_idx)){
    // topic index is not int
    return krr("topic index must be int type.");
  }

  rd_kafka_topic_t *topic_handle=index_to_topic_handle(topic_idx);
  if(!topic_handle){
    // Null pointer `krr`. Error happened in `index_to_topic_handle()`.
    return (K) topic_handle;
  }
  
  // Return topic name from the handle
  return ks((S) rd_kafka_topic_name(topic_handle));
}

//%% Configuration %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Get configuration of topic and broker for a given client index.
 * @param client_idx: Index of client in `CLIENTS`.
 * @return 
 * - dictionary: Informaition of originating broker, brokers and topics.
 *   - orig_broker_id: int | Broker originating this meta data
 *   - orig_broker_name | symbol | Name of originating broker
 *   - brokers: list of dictionary | Information of brokers
 *   - topics: list of dictionary | Infomation of topics
 */
EXP K get_broker_topic_config(K client_idx){
  const struct rd_kafka_metadata *meta;

  if(!check_qtype("i", client_idx)){
    // index must be int
    return krr((S) "client index must be int type.");
  }
    
  rd_kafka_t *handle=index_to_handle(client_idx);
  if(!handle){
    // Null pointer `krr`. Error in `index_to_handle()`.
    return handle;
  }
    
  rd_kafka_resp_err_t error= rd_kafka_metadata(handle, 1, NULL, &meta, 5000);
  if(KFK_OK != error){
    // Error in getting metadata
    return krr((S) rd_kafka_err2str(error));
  }
  
  // Store configuration
  K config= decode_metadata(meta);
  // Destroy metadata pointer no longer necessary
  rd_kafka_metadata_destroy(meta);
  return config;
}

//%% Producer %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Flush a handle of a producer.
 * @param producer_idx: Index of a client (producer) in `CLIENTS`.
 * @param q_timeout: Timeout (milliseconds) for waiting for flush.
 */
EXP K flush_producer_handle(K producer_idx, K q_timeout){
  
  if(!check_qtype("i[hij]", producer_idx, q_timeout)){
    // Error in type check.
    return krr((S) "producer_idx and q_timeout must be (int; short|int|long) type.");
  }

  rd_kafka_t *handle=index_to_handle(producer_idx);
  if(!handle){
    // Null pointer (`krr`). Error in `index_to_handle()`.
    return (K) handle;
  }

  I timeout=0;
  switch(q_timeout->t){
    case -KH:
      timeout=q_timeout->h;
      break;
    case -KI:
      timeout=q_timeout->i;
      break;
    default:
      timeout=q_timeout->j;
      break;
  }

  // Flush the handle of the producer
  rd_kafka_resp_err_t err= rd_kafka_flush(handle, timeout);
  if(KFK_OK != err){
    // Timeout
    return krr((S) rd_kafka_err2str(err));
  }
    
  return KNULL;
 }

// Support only if rdkafka version >= 0.11.4
#if (RD_KAFKA_VERSION >= 0x000b04ff)

/**
 * @brief Publish message with custom headers.
 * @param producer_idx: Index of client (producer) in `CLIENTS`.
 * @param topic_idx: Index of topic in `TOPICS`.
 * @param partition: Topic partition.
 * @param payload: Payload to be sent.
 * @param key: Message key.
 * @param headers: Message headers expressed in a map between header keys to header values (symbol -> string).
 */
EXP K publish_with_headers(K producer_idx, K topic_idx, K partition, K payload, K key, K headers){
  
  if(!check_qtype("iii[CG][CG]!", producer_idx, topic_idx, partition, payload, key, headers)){
    // Error in check type.
    return krr((S) "producer_idx, topic_idx, partition, payload, key and headers must be (int; int; int; string; string; dictionary) type.");
  }
    
  rd_kafka_t *handle=index_to_handle(producer_idx);
  if(!handle){
    // Null pointer (`krr`). Error in `index_to_handle()`.
    return (K) handle;
  }
    
  rd_kafka_topic_t *topic_handle=index_to_topic_handle(topic_idx);
  if(!topic_handle){
    // Null pointer (`krr`). Error in `index_to_topic_handle()`.
    return (K) topic_handle;
  }
    
  K hdr_keys = (kK(headers)[0]);
  K hdr_values = (kK(headers)[1]);
  // Type check of headers
  if (hdr_keys->t != KS || hdr_values->t != 0){
    // headers contain wrong type
    return krr((S) "header keys and header values must be (list of symbol; compound list) type.");
  }
  for(int idx=0; idx < hdr_values->n; ++idx){
    K hdrval = kK(hdr_values)[idx];
    if (hdrval->t != KG && hdrval->t != KC){
      // Header value is not string
      return krr((S) "header value must be string type.");
    }
  }

  rd_kafka_headers_t* message_headers = rd_kafka_headers_new((int) hdr_keys->n);
  for (int idx=0; idx < hdr_keys->n; ++idx){
    K hdrval = kK(hdr_values)[idx];
    if (hdrval->t == KG || hdrval->t == KC){
      // Add a pair of header key and value to headers
      rd_kafka_header_add(message_headers, kS(hdr_keys)[idx], -1, kG(hdrval), hdrval->n);
    }
  }

  rd_kafka_resp_err_t err = rd_kafka_producev(
                        handle,
                        RD_KAFKA_V_RKT(topic_handle),
                        RD_KAFKA_V_PARTITION(partition->i),
                        RD_KAFKA_V_MSGFLAGS(RD_KAFKA_MSG_F_COPY),
                        RD_KAFKA_V_VALUE(kG(payload), payload->n),
                        RD_KAFKA_V_KEY(kG(key), key->n),
                        RD_KAFKA_V_HEADERS(message_headers),
                        RD_KAFKA_V_END);
  if(err!=KFK_OK){
    // Error in sending message
    return krr((S) rd_kafka_err2str(err));
  }
    
  return KNULL;
}

#else
EXP K publish_with_headers(K UNUSED(client_idx),K UNUSED(topic_idx),K UNUSED(partition),K UNUSED(value),K UNUSED(key),K UNUSED(headers)) {
  return krr(".kafka.PublishWithHeaders is not supported for current rdkafka version. please update to librdkafka >= 0.11.4");
}
#endif
