//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include "kafkakdb_utility.h"
#include "kafkakdb_client.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//


//%% Utility %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Error type of K object
 */
static const I KR = -128;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Configuration %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

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

//%% Message %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

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
I printr0(K response){
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

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

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
  // TODO
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

  while(rd_kafka_outq_len(handle)){
    // Spin wait until it is confirmed that there is no remained message to this client.
  }

  if(rd_kafka_type(handle) == RD_KAFKA_CONSUMER){
    // For consumer, close first.
    rd_kafka_consumer_close(handle);
  }
  // Destroy client handle
  rd_kafka_destroy(handle);

  // Fill hole with 0
  // TODO
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
 * @brief Set log level for a given client.
 * @param client_idx: Index of client in `CLIENTS`.
 * @param level: Severity levels in syslog.
 * @note 
 * For level setting, see https://en.wikipedia.org/wiki/Syslog#Severity_level
 */
EXP K set_log_level(K client_idx, K level){

  if(!check_qtype("i[hij]", client_idx, level)){
    // Wrong argument types
    return krr((S) "client index and log level must be (int; short|int|long) type.");
  }

  rd_kafka_t *handle=index_to_handle(client_idx);
  if(!handle){
    // Null pointer (`krr`). Error in `index_to_handle()`.
    return (K) handle;
  }

  int log_level=0;
  switch(level->t){
    case -KH:
      log_level=level->h;
      break;
    case -KI:
      log_level=level->i;
      break;
    case -KJ:
      log_level=level->j;
  }

  // Set log level for the client
  rd_kafka_set_log_level(handle, log_level);

  return KNULL;
}

/**
 * @brief Return the current out queue length for a given client.
 * @param client_idx: Index of client in `CLIENTS`.
 */
EXP K get_out_queue_length(K client_idx){

  rd_kafka_t *handle=index_to_handle(client_idx);
  if(!handle){
    // Null pointer (`krr`). Error in `index_to_handle()`.
    return (K) handle;
  }

  // Get length out queue messages for this client
  return ki(rd_kafka_outq_len(handle));
}