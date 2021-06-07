#ifndef __KAFKAKDB_UTILITY_H__
#define __KAFKAKDB_UTILITY_H__

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <errno.h>
#include <stdarg.h>
#include <rdkafka.h>
#include "k.h"

//%% Socket Library %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

#ifdef _WIN32
#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "librdkafka.lib")
#define EXP __declspec(dllexport)
#else
#include <unistd.h>
#define EXP
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
extern const I KR;

/**
 * @brief Offset between UNIX epoch (1970.01.01) and kdb+ epoch (2000.01.01) in day.
 */
extern const J KDB_DAY_OFFSET;

/**
 * @brief Milliseconds in a day
 */
extern const J ONEDAY_MILLIS;

/**
 * @brief Type indicators sorted in ascending order by underlying integer values.
 * @note
 * - By adding 20 to `arg->t`, the value matches the position in this letters. For example, 't' isnidcates time type whose
 *  integer indicator is -19. Adding 20 to -19 equals 1 and `QTYPE_INDICATORS[1]` matches 't'. Additionally, '+' denotes table
 *  and '!' denotes dictionary.
 * - Don't erase spaces!! This is not a mistake!!
 */
static const C QTYPE_INDICATORS[256];

//%% Interface %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief WHAT IS THIS??
 */
K S0;

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
K build_dictionary_n(I n, ...);

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
I check_qtype(const C* types, ...);

/**
 * @brief Convert millisecond timestamp to kdb+ nanosecond timestamp.
 * @param timestamp_millis: Timestamp expressed in milliseconds.
 * @return 
 * - long: kdb+ timestamp (nanoseconds)
 */
J millis_to_kdb_nanos(J timestamp_millis);

//%% Topic Partition Utility Functions %%//vvvvvvvvvvvvvvv/

K decode_topic_partition(rd_kafka_topic_partition_t *topic_partition);

/**
 * @brief Build a list of topic-partition information dictionaries
 * @param topic_partition_list: Pointer to topic-partition list
 * @return 
 * compound list: A list of topic-partition information dictionaries
 */
K decode_topic_partition_list(rd_kafka_topic_partition_list_t *topic_partition_list);

/**
 * @brief Add a list of pairs of topic and partition to a topic-partition list.
 * @param topic_to_part: Dictionary mapping from topic to partition (s -> i).
 */
void extend_topic_partition_list(K topic_to_part, rd_kafka_topic_partition_list_t *t_partition);

/**
 * @brief Add pairs of specific topic and given partitions for the topic to a given topic-partition list and set given offsets on sepcified partitions.
 * @param topic: Topic of partitions to which offsets are set.
 * @param partition_to_offset: q dictionary (map) from partition to offset (i -> j).
 * @param topic_partitions: A list of pairs of topic and partition.
 */
void extend_topic_partition_list_and_set_offset_for_topic(S topic, K partition_to_offset, rd_kafka_topic_partition_list_t *topic_partitions);

/**
 * @brief Delete given pairs of topic and partition from the given topic-partitions.
 * @param topic_to_part: q dictionary mapping from topic to partition (s -> i).
 * @param topic_partitions: list of topic-partitons.
 */
void delete_elems_from_topic_partition_list(K topic_to_part, rd_kafka_topic_partition_list_t *topic_partitions);

//%% Callback Functions %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Print error if any and release K object.
 * @note
 * Return 0 to indicate mem free to kafka where needed in callback
 */
I printr0(K response);

// #define __KAFKAKDB_UTILITY_H__
#endif
