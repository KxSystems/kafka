//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include "kafkakdb_utility.h"
#include "kafkakdb_info.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Returns the number of threads currently being used by librdkafka.
 * @return The number of thread used by rdkafka.
 */
EXP K get_kafka_thread_count(K UNUSED(unused)){
  return ki(rd_kafka_thread_cnt());
}

/**
 * @brief Get librdkafka version.
 * @return Version of librdkafka.
 */
EXP K version(K UNUSED(x)){
  return ki(rd_kafka_version());
}

/**
 * @brief Returns the human readable librdkafka version.
 * @return String version of librdkafka.
 */
EXP K version_string(K UNUSED(x)){
  return kp((S) rd_kafka_version_str());
}

/**
 * @brief Display error description for each error code.
 * @return Error description table of librdkafka.
 */
EXP K kafka_error_description_table(K UNUSED(unused)){
  
  K error_code= ktn(0, 0), error_name= ktn(0, 0), description= ktn(0, 0);

  // Holder of registered errors
  const struct rd_kafka_err_desc *error_descriptions;
  // Holder of teh number of registered errors
  size_t n;
  // Contain reigistered error information
  rd_kafka_get_err_descs(&error_descriptions, &n);

  for(size_t i= 0; i < n; ++i){
    // Contain error code, name and description of each error
    if(error_descriptions[i].code) {
      jk(&error_code, ki(error_descriptions[i].code));
      jk(&error_name, ks((S)(error_descriptions[i].name ? error_descriptions[i].name : "")));
      jk(&description, kp((S)(error_descriptions[i].desc ? error_descriptions[i].desc : "")));
    }
  }
    
  return xT(build_dictionary("code", error_code, "name", error_name, "description", description));
}
