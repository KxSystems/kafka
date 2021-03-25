//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <fcntl.h>
#include "kafkakdb_utility.h"
#include "kafkakdb_client.h"
#include "kafkakdb_init.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Trigger callback of client when mesage was sent from worker thread..
 * @param socket: Socket to read.
 */
K trigger_callback(I socket){
  static K data[16]; //! worth experimenting with since this will affect performance, probably longer than 512 is a waste 512*8 = 4096 (1page)
  int received;
  if((received=recv(socket, data, sizeof(data), MSG_DONTWAIT)) > 0) {
    // convert `received` to length (number of poitners)
    received /= sizeof(K);
    for(int i = 0; i < received; ++i){
      r0(k(0, ".kafka.consume_topic_cb .", data[i], KNULL));
    }
  }
  return KNULL;
}

/**
 * @brief Clean up internal state of interface.
 */
static void detach(void){

  if(CLIENTS){
    for(int i= 0; i < CLIENTS->n; i++){
      // TODO
      // 0 hole must be reused at generating a new client
      if(((S)0) != kS(CLIENTS)[i]){
        // Delete if the client is not null pointer
        delete_client(ki(i));
      }    
    }
    // Delete the client fron kafka broker. Wait for 1 second until the client is destroyed.
    rd_kafka_wait_destroyed(1000);
  }

  if(spair[0] > -1){
    // Unfook from q network event loop
    sd0x(spair[0], 0);
    closesocket(spair[0]);
  }
  if(spair[1] > -1){
    closesocket(spair[1]);
  }
  
  // Set null pointer
  spair[0]= -1;
  spair[1]= -1;

}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Safely unhook sockets and store them for reloading a library.
 * @return
 * - list of int: Stashed pair of sockets. 
 */
EXP K stash_sockets(K UNUSED(unused)){
  // Unhook from event loop and Stash socket pair.
  sd0(*spair);
  K stored_spair=ktn(KI, 2);
  for(int i=0; i!=2; ++i){
    kI(stored_spair)[i]=spair[i];
    spair[i]=-1;
  };
  return stored_spair;
}

/**
 * @brief Initialize internal state of interface.
 * @note
 * This function should be executed only once by user. For reloading the library, use `reload`.
 */
EXP K init(K probably_spair){

  //K is_reload=k(0, ".kafka.LOADING_VERSION", KNULL);

  if(!CLIENTS){
    // Initialized client handle list.
    CLIENTS=ktn(KS, 0);
  }
  if(!TOPICS){
    // Initialize topic handle list.
    TOPICS=ktn(KS, 0);
  }
  if(!S0){
    // WHAT IS THIS??
    // I don't know why null string must be kept as global...
    S0=ks("");
  }
  
  if(probably_spair->t == KI && probably_spair->n == 2 && kI(probably_spair)[0] > -1 && kI(probably_spair)[1] > -1){
    // Reload
    for(int i=0; i!=2; ++i){
      spair[i]=kI(probably_spair)[i];
    }
  }
  else{
    // Create socket pair
    if(dumb_socketpair(spair, 1) == SOCKET_ERROR){
      // Error in creating socket pair
      fprintf(stderr, "creation of socketpair failed: %s\n", strerror(errno));
    }
  }

  // Fook callback functions to event loop
  K ok=sd1(spair[0], trigger_callback);
  if(!ok){
    fprintf(stderr, "adding callback failed\n");
    closesocket(spair[0]);
    closesocket(spair[1]);
    spair[0]=-1;
    spair[1]=-1;
    return 0;
  }
  r0(ok);

  atexit(detach);

  return KNULL;
}
