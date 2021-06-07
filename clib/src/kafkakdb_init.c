//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <fcntl.h>
#include <stdlib.h>
#include <kafkakdb_utility.h>
#include <kafkakdb_client.h>
#include <kafkakdb_topic.h>

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
  // If buffer is implemented for `poll_client` the flag must be MSG_DONTWAIT for Linux/Mac.
  // Then 0 for Windows. This change must corrspond to setting sockets non-blocking in `init` function.
  if((received=recv(socket, data, sizeof(data), 0)) > 0) {
    // convert `received` to length (number of poitners)
    received /= sizeof(K);
    for(int i = 0; i < received; ++i){
      S function=kC(kK(data[i])[0]);
      J length=kK(data[i])[0]->n;
      if((!strncmp(function, ".kafka.stats_cb", length)) || (!strncmp(function, ".kafka.log_cb", length)) || (!strncmp(function, ".kafka.offset_commit_cb", length)) || (!strncmp(function, ".kafka.dr_msg_cb", length)) || (!strncmp(function, ".kafka.error_cb", length)) || (!strncmp(function, ".kafka.throttle_cb", length))){
        printr0(k(0, "value", data[i], KNULL));
      }
      else{
        printr0(k(0, ".kafka.consume_topic_cb .", data[i], KNULL));
      }
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
      // If detached after delete_client there is a 0 hole.
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
 * @brief Initialize internal state of interface.
 * @note
 * This function should be executed only once by user. For reloading the library, use `reload`.
 */
EXP K init(K probably_spair){

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

#ifdef WIN32
    u_long iMode = 1;
    if (ioctlsocket(spair[0], FIONBIO, &iMode) != NO_ERROR) {
        // Failure in setting pair[0]
        return krr((S)"failed to set socket to non-blocking");
    }
    if (ioctlsocket(spair[1], FIONBIO, &iMode) != NO_ERROR) {
        // Failure in setting pair[1]
        return krr((S)"failed to set socket1] to non-blocking");
    }

#else
    if (fcntl(spair[0], F_SETFL, O_NONBLOCK) == -1) {
        // Failure in setting pair[0]
        return krr((S)"failed to set socket[0] to non-blocking");
    }
    if (fcntl(spair[1], F_SETFL, O_NONBLOCK) == -1) {
        // Failure in setting pair[1]
        return krr((S)"failed to set socket[1] to non-blocking");
    }
#endif
    
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
