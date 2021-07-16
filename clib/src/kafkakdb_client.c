//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <string.h>
#include <stdlib.h>
#include <signal.h>
#include <osthread.h>
#include <kafkakdb_utility.h>
#include <kafkakdb_client.h>
#ifdef USE_TRANSFORMER
#include <qtfm.h>
#endif

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Interface %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Thread pool for polling client.
 */
static K ALL_THREADS = 0;

/**
 * @brief Client handles expressed in symbol list
 */
K CLIENTS = 0;

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

//%% Message %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Build dictionary from message pointer returned from `rd_kafka_consume*()` family of functions
 *  for the given client handle.
 * @param handle: Client handle
 * @param msg: Message pointer returned from `rd_kafka_consume*()` family of functions.
 * @param client_idx: Client index within `CLIENTS`.
 * @return 
 * - dictionary: Information contained in the message.
 */
K decode_message(const rd_kafka_t* handle, const rd_kafka_message_t *msg, int client_idx) {

#if (RD_KAFKA_VERSION >= 0x000b04ff)
  // Retrieve message headers
  rd_kafka_headers_t* hdrs = NULL;
  rd_kafka_message_headers(msg, &hdrs);
  K k_headers = NULL;

  if (hdrs==NULL){
    // Empty header. Empty dictionary
    k_headers = xD(ktn(KS, 0), ktn(KC, 0));
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

  // Retrieve `key`
  K key=ktn(KG, msg->key_len);
  K payload=0;

#ifdef USE_TRANSFORMER

  // Deserialize if schemaregistry message comes.
  // Retrieve `payload`
  G *byte_payload=(G*) msg->payload;
  if(byte_payload[0] == 0){
    // Schema registry message
    payload=ktn(KG, msg->len-5);
    memcpy(kG(payload), byte_payload+5, msg->len-5);
    // Schema ID
    int schema_id = (unsigned char)(byte_payload+1) << 24 |
      (unsigned char)(byte_payload+2) << 16 |
      (unsigned char)(byte_payload+3) << 8 |
      (unsigned char)(byte_payload+4);

    sprintf(NUMBER, "%d", schema_id);
    K pipeline_name=ks(NUMBER);
    payload=transform(pipeline_name, payload);
    if(!payload){
      // Error happenned in transformation
      r0(pipeline_name);
      return payload;
    }
    // Delete pipeline no longer used.
    r0(pipeline_name);
  }
  else{
    // Plain message
    payload=ktn(KG, msg->len);
    memcpy(kG(payload), msg->payload, msg->len);
  }

#else

  // Does nothing for all messages.
  // Retrieve `payload`
  payload= ktn(KG, msg->len);
  memmove(kG(payload), msg->payload, msg->len);

#endif

  memmove(kG(key), msg->key, msg->key_len);

  // Millisecond timestamp from epoch
  J timestamp= rd_kafka_message_timestamp(msg, NULL);
  // Convert it to kdb+ timestamp
  K msgtime= ktj(-KP, (timestamp > 0)? millis_to_kdb_nanos(timestamp): nj);

  K error=msg->err? kp((S) rd_kafka_err2str(msg->err)): kp("");

  return build_dictionary_n(10,
            "mtype", msg->err? ks((S) rd_kafka_err2name(msg->err)): r1(S0), 
            "topic", msg->rkt? ks((S) rd_kafka_topic_name(msg->rkt)): r1(S0),
            "client", ki(handle_to_index(handle)),
            "partition", ki(msg->partition),
            "offset", kj(msg->offset),
            "msgtime", msgtime,
            "data", payload,
            "key", key,
            "headers", k_headers,
            "error", error,
            (S) 0);
}

//%% Callback Functions %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Callback function for statistics set by `rd_kafka_conf_set_stats_cb` and triggered from `rd_kafka_poll()` every `statistics.interval.ms`.
 *  Deigate to q function `.kfk.stats_cb`.
 * @param json: String statistics in JSON format
 * @param joson_len: Length of the statistics string.
 */
static I stats_cb(rd_kafka_t *UNUSED(handle), S json, size_t json_len, V *UNUSED(opaque)){
  // Pass string statistics to q
  // Return 0 to indicate mem free to kafka
  K stats_message=knk(2, kp((S) ".kafka.stats_cb"), kpn(json, json_len), KNULL);
  // Must be processed in the main thread.
  // stats_message will be freed in the main thread.
  // If buffer is implemented for `poll_client` the flag must be MSG_DONTWAIT for Linux/Mac.
  // Then 0 for Windows. This change must corrspond to setting sockets non-blocking in `init` function.
  send(spair[1], &stats_message, sizeof(K), 0);
  return 0;
}

/**
 * @brief Callback function to print log set by `rd_kafka_conf_set_log_cb`. Deligate to q function `.kfk.logcb`.
 * @param level: Log level
 * @param fac: WHAT IS THIS??
 * @param buf: WHAT IS THIS??
 */
static void log_cb(const rd_kafka_t *UNUSED(handle), int level, const char *fac, const char *buf){
  K log_message=knk(4, kp((S) ".kafka.log_cb"), ki(level), kp((S) fac), kp((S) buf), KNULL);
  // Must be processed in the main thread.
  // stats_message will be freed in the main thread.
  // If buffer is implemented for `poll_client` the flag must be MSG_DONTWAIT for Linux/Mac.
  // Then 0 for Windows. This change must corrspond to setting sockets non-blocking in `init` function.
  send(spair[1], &log_message, sizeof(K), 0);
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
  K offset_commit_message=knk(4, kp((S) ".kafka.offset_commit_cb"), ki(handle_to_index(handle)), kp((S) rd_kafka_err2str(error_code)), decode_topic_partition_list(offsets), KNULL);
  // Must be processed in the main thread.
  // stats_message will be freed in the main thread.
  // If buffer is implemented for `poll_client` the flag must be MSG_DONTWAIT for Linux/Mac.
  // Then 0 for Windows. This change must corrspond to setting sockets non-blocking in `init` function.
  send(spair[1], &offset_commit_message, sizeof(K), 0);
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
  K dr_msg_message=knk(3, kp((S) ".kafka.dr_msg_cb"), ki(handle_to_index(handle)), decode_message(handle, msg, handle_to_index(handle)), KNULL);
  // Must be processed in the main thread.
  // stats_message will be freed in the main thread.
  // If buffer is implemented for `poll_client` the flag must be MSG_DONTWAIT for Linux/Mac.
  // Then 0 for Windows. This change must corrspond to setting sockets non-blocking in `init` function.
  send(spair[1], &dr_msg_message, sizeof(K), 0);
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
  K error_message=knk(4, kp((S) ".kafka.error_cb"), ki(handle_to_index(handle)), ki(error_code), kp((S)reason), KNULL);
  // Must be processed in the main thread.
  // stats_message will be freed in the main thread.
  // If buffer is implemented for `poll_client` the flag must be MSG_DONTWAIT for Linux/Mac.
  // Then 0 for Windows. This change must corrspond to setting sockets non-blocking in `init` function.
  send(spair[1], &error_message, sizeof(K), 0);
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
  K throttle_message=knk(5, kp((S) ".kafka.throttle_cb"), ki(handle_to_index(handle)), kp((S) brokername), ki(brokerid), ki(throttle_time_ms), KNULL);
  // Must be processed in the main thread.
  // stats_message will be freed in the main thread.
  // If buffer is implemented for `poll_client` the flag must be MSG_DONTWAIT for Linux/Mac.
  // Then 0 for Windows. This change must corrspond to setting sockets non-blocking in `init` function.
  send(spair[1], &throttle_message, sizeof(K), 0);
}

//%% Poll %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

static void flush(J socket, const void *ptr, J len_bytes) {
	J sent;
  while(sent = send(socket, ptr, len_bytes, 0)){
    if(sent < 0) {
      if(errno == EINTR){
        continue;
      }
      else{
        perror("send");
        exit(255);
      }
    }
    if(sent < len_bytes) {
      ptr = ((const char *)ptr) + sent;
      len_bytes -= sent;
      // keep going until everything is written
    }
  }
}

/**
 * @brief Poll producer or consumer with timeout (and a limitation of the number of polling for consumer).
 * @param handle: Client handle.
 * @param timeout: The maximum amount of time (in milliseconds) that the call will block waiting for events.
 * - 0: non-blocking
 * - -1: wait indefinitely
 * - others: wait for this period
 * @return 
 * - int: The number of messages retrieved (poll count).
 */
J poll_client(rd_kafka_t *handle, I timeout){
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

    while((message= rd_kafka_consumer_poll(handle, timeout))){
      // Poll and retrieve message while message is not empty
      // Store tuple of (client index; data) for invoking `.kafka.consume_topic_cb` in the main thread.
      K q_message=knk(2, ki(handle_to_index(handle)), decode_message(handle, message, handle_to_index(handle)), KNULL);
      // If buffer is implemented for `poll_client` the flag must be MSG_DONTWAIT for Linux/Mac.
      // Then 0 for Windows. This change must corrspond to setting sockets non-blocking in `init` function.
      send(spair[1], &q_message, sizeof(K), 0);
      
      // Discard message which is not necessary any more
      rd_kafka_message_destroy(message);

      // Increment the poll counter
      ++n;
    }

    // Return the number of mesasges
    return n;
  }
}

/**
 * @brief Poller executed in the background.
 * @param handle: Kafka client handle.
 */
static void background_thread(void* handle) {
  rd_kafka_t *client = handle;
  while(1){
    // Poll forever.
    poll_client(client, -1);
  }
}

/**
 * @brief Generate thread ID from a memory location for controlling.
 * @param 
 */
static J make_thread_id(osthread_t thread) {
	void *id = malloc(sizeof(osthread_t));
  // Use memory location as an ID.
	memcpy(id, &thread, sizeof(osthread_t));
  // works because sizeof(J) == sizeof(id)
	return (J) id;
}

//%% Create Client %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Set kafka client handle to a new client.
 * @param handle: Kafka client handle.
 */
K set_handle_to_client(rd_kafka_t *handle){

  // Store client hande as symbol
  // Why symbol rather than integer?
  if(!CLIENTS){
    // Initialize with the first pipeline.
    // The first one is assured to be 0 because pipeline is set at the creation of a client.
    CLIENTS=ktn(KS, 1);
    kS(CLIENTS)[0]=(S) handle;
    return ki(0);
  }
  else{
    int idx=0;
    while (idx!=CLIENTS->n){
      if(kS(CLIENTS)[idx] == 0){
        // Reuse 0 hole.
        kS(CLIENTS)[idx]=(S) handle;
        // Return client index as int
        return ki(idx);
      }
      ++idx;
    }

    // There is no 0 hole. Append a new one.
    js(&CLIENTS, (S) handle);
    // Return client index as int
    return ki(idx);
  }
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Create/Delete %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Create a client based on a given client type (producer or consumer) and a given configuration.
 * @param client_type:
 * - "p": Producer
 * - "c": Consumer
 * @param q_config: Dictionary containing a configuration.
 * @param timeout: Timeout (milliseconds) for querying.
 * @return 
 * - error: If passing client type which is neither of "p" or "c". 
 * - int: Client index.
 */
EXP K new_client(K client_type, K q_config, K timeout){

  // Buffer for error message
  char error_message[512];

  if(!check_qtype("c!i", client_type, q_config, timeout)){
    // Argument type does not match char and dictionary
    return krr("client type, config and timeout must be (char; dictionary; int) type.");
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

  // Check status with the new handle.
  // Holder of configuration
  const struct rd_kafka_metadata *meta;  
  rd_kafka_resp_err_t error= rd_kafka_metadata(handle, 1, NULL, &meta, timeout->i);
  if(error!=KFK_OK){
    // Error in getting metadata
    // Destroy the client handle
    rd_kafka_destroy(handle);
    return krr((S) rd_kafka_err2str(error));
  }

  // Redirect logs to main queue
  rd_kafka_set_log_queue(handle, NULL);

  if(type == RD_KAFKA_CONSUMER){
    // Redirect `rd_kafka_poll()` to `consumer_poll()`. (Producer gets from main queue).
    rd_kafka_poll_set_consumer(handle);
  }

  // Store client hande as symbol
  return set_handle_to_client(handle);
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
  // Destroy client handle
  rd_kafka_destroy(handle);

  // Fill hole with 0
  kS(CLIENTS)[client_idx->i]= (S) 0;

  return KNULL;
}

//%% Poll %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Start polling for a given client in background.
 * @param client_idx: Index of the client in `CLIENTS`.
 */
EXP K start_background_poll(K client_idx) {
  if(!check_qtype("i", client_idx)){
    // The argument type does not match int
    return krr("client index must be int type.");
  }

  rd_kafka_t *handle=index_to_handle(client_idx);
  osthread_t task;
  
  if(!ALL_THREADS){
    // Initialize threads
    ALL_THREADS=ktn(KJ, 1);
    kJ(ALL_THREADS)[client_idx->i]=make_thread_id(task);
  }
  else{
    J thread_id=make_thread_id(task);
    if(!kJ(ALL_THREADS)[client_idx->i]){
      // 0 hole
      // Reuse 0 hole and store the new thread ID
      kJ(ALL_THREADS)[client_idx->i] = thread_id;
    }
    else{
      // There was no 0 hole.
      // Append the new ID to the tail.
      ja(&ALL_THREADS, (V*) &thread_id);
    }
  }

  // Create a thread
  int ok=osthread_create(&task, NULL, background_thread, handle);
  if(ok){
    return krr("Failed to create a thread.");
  }
  else{
    return r1(client_idx);
  } 
}

/**
 * @brief Stop polling for a given client in background.
 * @param client_idx: Index of the client in `CLIENTS`.
 * @return
 * - bool: true for successful termination.
 */
EXP K stop_background_poll(K client_idx) {
  if(!check_qtype("i", client_idx)){
    // The argument type does not match
    return krr("cient index must be int type.");
  }
  if(ALL_THREADS && ALL_THREADS->n > client_idx->i) {
    // Thread ID
    J id = kJ(ALL_THREADS)[client_idx->i];
    if(!id){
      return krr("not running in background");
    }
    osthread_t task;
    memcpy(&task, (void*) id, sizeof(osthread_t));
    osthread_kill(&task);
    // Fill the box with 0.
    // This 0 hole is reused.
    kJ(ALL_THREADS)[client_idx->i] = 0;
  }
  return kb(1);
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

//%% Setting %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

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