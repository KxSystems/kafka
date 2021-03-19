//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include "kafkakdb_utility.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Utility %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Offset between UNIX epoch (1970.01.01) and kdb+ epoch (2000.01.01) in day.
 */
const J KDB_DAY_OFFSET = 10957;

/**
 * @brief Milliseconds in a day
 */
const J ONEDAY_MILLIS = 86400000;

/**
 * @brief Type indicators sorted in ascending order by underlying integer values.
 * @note
 * - By adding 20 to `arg->t`, the value matches the position in this letters. For example, 't' isnidcates time type whose
 *  integer indicator is -19. Adding 20 to -19 equals 1 and `QTYPE_INDICATORS[1]` matches 't'. Additionally, '+' denotes table
 *  and '!' denotes dictionary.
 * - Don't erase spaces!! This is not a mistake!!
 */
static const C QTYPE_INDICATORS[256]= " tvunzdmpscfejihg xb*BX GHIJEFCSPMDZNUVT                                                                              +!";

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
I check_qtype(const C* types, ...){

  // Holder of variadic
  va_list args;
  // Receiver of K object to test its type
  K obj;
  // Head of `types`
  const char* start= types;
  // Holder of true-false
  I match;

  va_start(args, types);
  while(*start){
    match= 0;
    obj= va_arg(args, K);

    if(!obj){
      // Null K object. Unexpected end of variables.
      // Return 0 rather than error.
      // This failure will be propagated to q as error by the caller of this function.
      break;
    };

    if('[' == *start){
      // Check if it is any type in [].
      while(*start && ']' != *start){
        match= match || QTYPE_INDICATORS[20 + (obj -> t)] == *start;
        // Progress pointer of type array
        ++start;
      }
    }
    else{
      // Specific type indicator 
      match= QTYPE_INDICATORS[20 + (obj -> t)] == *start;
    }

    // Break in case of type mismatch  
    if(!match){
      // Return 0 rather than error.
      // This failure will be propagated to q as error by the caller of this function.
      break;
    };

    // Progress pointer of type array
    ++start;
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
J millis_to_kdb_nanos(J timestamp_millis){return 1000000LL*(timestamp_millis - KDB_DAY_OFFSET * ONEDAY_MILLIS);}

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

//%% Topic Partition Utility Functions %%//vvvvvvvvvvvvvvv/

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

  // Actually this is a table.
  list=k(0, "{[dicts] -1 _ dicts, (::)}", list, KNULL);
  
  return list;
}

/**
 * @brief Add a list of pairs of topic and partition to a topic-partition list.
 * @param topic_to_part: Dictionary mapping from topic to partition (s -> i).
 */
void extend_topic_partition_list(K topic_to_part, rd_kafka_topic_partition_list_t *t_partition){

  // Length of keys
  J n=kK(topic_to_part)[0]->n;
  S *topics=kS(kK(topic_to_part)[0]);
  I *partitions=kI(kK(topic_to_part)[1]);
  for(J i = 0; i < n; i++){
    // Add a pair of topic and partition to the given list
    rd_kafka_topic_partition_list_add(t_partition, topics[i], partitions[i]);
  } 
}

/**
 * @brief Add pairs of specific topic and given partitions for the topic to a given topic-partition list and set given offsets on sepcified partitions.
 * @param topic: Topic of partitions to which offsets are set.
 * @param partition_to_offset: q dictionary (map) from partition to offset (i -> j).
 * @param topic_partitions: A list of pairs of topic and partition.
 */
void extend_topic_partition_list_and_set_offset_for_topic(S topic, K partition_to_offset, rd_kafka_topic_partition_list_t *topic_partitions){
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
 * @brief Delete given pairs of topic and partition from the given topic-partitions.
 * @param topic_to_part: q dictionary mapping from topic to partition (s -> i).
 * @param topic_partitions: list of topic-partitons.
 */
void delete_elems_from_topic_partition_list(K topic_to_part, rd_kafka_topic_partition_list_t *topic_partitions){
  // Length of keys
  J n=kK(topic_to_part)[0]->n;
  S* topics= kS(kK(topic_to_part)[0]);
  J* partitions=kJ(kK(topic_to_part)[1]);
  for(J i = 0; i < n; i++){
    // Delete a pair of topic and partition from the given list
    rd_kafka_topic_partition_list_del(topic_partitions, topics[i], partitions[i]);
  }
}
