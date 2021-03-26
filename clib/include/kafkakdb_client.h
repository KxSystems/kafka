#ifndef __KAFKAKDB_CLIENT_H__
#define __KAFKAKDB_CLIENT_H__

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include "kafkakdb_utility.h"
#include <signal.h>
#ifndef _WIN32
#include <pthread.h>
#else
#include <process.h>
#endif

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Interface %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Thread pool for polling client.
 */
static K ALL_THREADS;

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
static K load_config(rd_kafka_conf_t* conf, K q_config);

//%% Message %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Build dictionary from message pointer returned from `rd_kafka_consume*()` family of functions
 *  for the given client handle.
 * @param handle: Client handle
 * @param msg: Message pointer returned from `rd_kafka_consume*()` family of functions.
 * @return 
 * - dictionary: Information contained in the message.
 */
K decode_message(const rd_kafka_t* handle, const rd_kafka_message_t* msg);

//%% Callback Functions %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Callback function for statistics set by `rd_kafka_conf_set_stats_cb` and triggered from `rd_kafka_poll()` every `statistics.interval.ms`.
 *  Deigate to q function `.kfk.stats_cb`.
 * @param json: String statistics in JSON format
 * @param joson_len: Length of the statistics string.
 */
static I stats_cb(rd_kafka_t* UNUSED(handle), S json, size_t json_len, V* UNUSED(opaque));

/**
 * @brief Callback function to print log set by `rd_kafka_conf_set_log_cb`. Deligate to q function `.kfk.logcb`.
 * @param level: Log level
 * @param fac: WHAT IS THIS??
 * @param buf: WHAT IS THIS??
 */
static void log_cb(const rd_kafka_t* UNUSED(handle), int level, const char* fac, const char* buf);

/**
 * @brief Callback function for offset commit set by `rd_kafka_conf_set_offset_commit_cb` and triggered by `rd_kafka_consumer_poll()`
 *  for use with consumer groups. Deligate to q function `.kfk.offset_commit_cb`.
 * @param handle Consumer handle.
 * @param error_code: Error code for commit error
 * @param offsets Topic-partiton list
 */
static void offset_commit_cb(rd_kafka_t* handle, rd_kafka_resp_err_t error_code, rd_kafka_topic_partition_list_t* offsets, V* UNUSED(opaque));

/**
 * @brief Callback function for delivery report set by `rd_kafka_conf_set_dr_msg_cb`. Deligate to q function `.kfk.dr_msg_cb`.
 * @param handle: Producer handle.
 * @param msg: Message pointer to a delivery report.
 * @note
 * - The callback is called when a message is succesfully produced or if librdkafka encountered a permanent failure, or the retry counter
 *  for temporary errors has been exhausted.
 * - Triggered by `rd_kafka_poll()` at regular intervals.
 */
static V dr_msg_cb(rd_kafka_t* handle, const rd_kafka_message_t* msg, V* UNUSED(opaque));

/**
 * @brief Callback function for error or warning. Deligate to q function `.kfk.error_cb`.
 * @param handle: Client handle.
 * @param error_code: Error code.
 * @param reason: reason for the error.
 * @todo
 * Address this statement? "This function will be triggered with `err` set to `RD_KAFKA_RESP_ERR__FATAL` if a fatal error has been raised.
 *  In this case use rd_kafka_fatal_error() to retrieve the fatal error code and error string, and then begin terminating the client instance."
 */
static V error_cb(rd_kafka_t* handle, int error_code, const char* reason, V* UNUSED(opaque));

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
static V throttle_cb(rd_kafka_t* handle, const char* brokername, int32_t brokerid, int throttle_time_ms, V* UNUSED(opaque));

//%% Poll %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

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
J poll_client(rd_kafka_t *handle, I timeout);

/**
 * @brief Poller executed in the background.
 * @param handle: Kafka client handle.
 */
static void*background_thread(void* handle);

/**
 * @brief Generate thread ID from a memory location for controlling.
 * @param 
 */
static J make_thread_id(pthread_t thread);

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
EXP K new_client(K client_type, K q_config, K timeout);

/**
 * @brief Destroy client handle and remove from `CLIENTS`.
 * @param client_idx: Index of client in `CLIENTS`.
 */
EXP K delete_client(K client_idx);

//%% Poll %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Set a new number on `MAXIMUM_NUMBER_OF_POLLING`.
 * @param n: The maximum number of polling at execution of `poll_client()` or `manual_poll()`.
 */
EXP K set_maximum_number_of_polling(K n);

/**
 * @brief Return the current out queue length for a given client.
 * @param client_idx: Index of client in `CLIENTS`.
 */
EXP K get_out_queue_length(K client_idx);

//%% Setting %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Get a name of client from client index.
 * @param client_index: Index of client in `CLIENTS`.
 * @return 
 * - symbol: Handle name of the client denoted by the given index.
 */
EXP K get_client_name(K client_index);

/**
 * @brief Set log level for a given client.
 * @param client_idx: Index of client in `CLIENTS`.
 * @param level: Severity levels in syslog.
 * @note 
 * For level setting, see https://en.wikipedia.org/wiki/Syslog#Severity_level
 */
EXP K set_log_level(K client_idx, K level);


// __KAFKAKDB_CIENT_H__
#endif
