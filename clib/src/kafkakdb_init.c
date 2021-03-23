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
 * @brief Trigger callback of client.
 * @param socket: Socket to read.
 */
K trigger_callback(I socket){

  // Read buffer from socket
  char buf[1024];
  J read_bytes;
  J consumed=0;
  // MSG_DONTWAIT - set in sd1(-h,...)
  while(0 < (read_bytes=recv(socket, buf, sizeof(buf), 0))){
    // Read until end or error
    consumed+=read_bytes;
  }
    
  for(J i= 0; i < CLIENTS->n; i++){
    if(((S) 0)!=kS(CLIENTS)[i]){
      // Poll if the client is not a null pointer
      poll_client((rd_kafka_t*) kS(CLIENTS)[i], 0, 0);
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
    close(spair[0]);
  }
  if(spair[1] > -1){
    close(spair[1]);
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
    printf("FD?: %d\n", spair[0]);
    printf("Current status: %d\n", fcntl(spair[0], F_GETFL));
  }
  else{
    // Create socket pair
    if(dumb_socketpair(spair, 1) == SOCKET_ERROR){
      // Error in creating socket pair
      fprintf(stderr, "creation of socketpair failed: %s\n", strerror(errno));
    }
  }

  #ifdef WIN32
  u_long iMode = 1;
  if (ioctlsocket(spair[0], FIONBIO, &iMode) != NO_ERROR){
    // Failure in setting pair[0]
    close(spair[0]);
    close(spair[1]);
    spair[0]=-1;
    spair[1]=-1;
    return krr((S) "failed to set socket to non-blocking");
  }
  if (ioctlsocket(spair[1], FIONBIO, &iMode) != NO_ERROR){
    // Failure in setting pair[1]
    close(spair[0]);
    close(spair[1]);
    spair[0]=-1;
    spair[1]=-1;
    return krr((S) "failed to set socket1] to non-blocking");
  }

#else
  if (fcntl(spair[0], F_SETFL, O_NONBLOCK) == -1){
    // Failure in setting pair[0]
    close(spair[0]);
    close(spair[1]);
    spair[0]=-1;
    spair[1]=-1;
    return krr((S) "failed to set socket[0] to non-blocking");
  } 
  if (fcntl(spair[1], F_SETFL, O_NONBLOCK) == -1){
    // Failure in setting pair[1]
    close(spair[0]);
    close(spair[1]);
    spair[0]=-1;
    spair[1]=-1;
    return krr((S) "failed to set socket[1] to non-blocking");
  }
#endif

  // Fook callback functions to event loop
  K ok=sd1(spair[0], &trigger_callback);
  if(!ok){
    fprintf(stderr, "adding callback failed\n");
    close(spair[0]);
    close(spair[1]);
    spair[0]=-1;
    spair[1]=-1;
    return 0;
  }
  r0(ok);

  return KNULL;
}
