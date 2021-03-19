//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <fcntl.h>
#include "kafkakdb_utility.h"
#include "kafkakdb_client.h"
#include "kafkakdb_init.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Indicate if internal state is initial state. Used to protect from being re-intialized at corruption.
 */
static I CLEAN_STATE=1;

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

  if(TOPICS){
    // `TOPICS` is not empty. Destroy.
    for(int i= 0; i < TOPICS->n; i++){
      // TODO
      // 0 hole must be reused at generating a new topic
      if(((S) 0) != kS(TOPICS)[i]){
        // Delete if the topic is not null pointer
        delete_topic(ki(i));
      }      
    }
    // Set ready for free
    r0(TOPICS);
  }
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
    // Set ready for free
    r0(CLIENTS);
  }

  int socketpair;
  if(socketpair=spair[0]){
    // Unfook from q network event loop
    sd0x(socketpair, 0);
    close(socketpair);
  }
  if(socketpair=spair[1]){
    close(socketpair);
  }
  
  // Set null pointer
  spair[0]= 0;
  spair[1]= 0;

  // Set initializable true
  CLEAN_STATE = 1;
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Initialize internal state of interface.
 */
EXP K init(K UNUSED(unused)){

  if(CLEAN_STATE!=1){
    // Guard from being initialized twice.
    return krr((S) "data is remained or corruption in internal state. cannot be initialized");
  }

  // Initialized client handle list.
  CLIENTS=ktn(KS, 0);
  // Initialize topic handle list.
  TOPICS=ktn(KS, 0);

  // WHAT IS THIS??
  // I don't know why null string must be kept as global...
  S0=ks("");

  // Create socket pair
  if(dumb_socketpair(spair, 1) == SOCKET_ERROR){
    // Error in creating socket pair
    fprintf(stderr, "creation of socketpair failed: %s\n", strerror(errno));
  }
    
#ifdef WIN32
  u_long iMode = 1;
  if (ioctlsocket(spair[0], FIONBIO, &iMode) != NO_ERROR){
    // Failure in setting pair[0]
    return krr((S) "failed to set socket to non-blocking");
  }
  if (ioctlsocket(spair[1], FIONBIO, &iMode) != NO_ERROR){
    // Failure in setting pair[1]
    return krr((S) "failed to set socket1] to non-blocking");
  }
    
#else
  if (fcntl(spair[0], F_SETFL, O_NONBLOCK) == -1){
    // Failure in setting pair[0]
    return krr((S) "failed to set socket[0] to non-blocking");
  } 
  if (fcntl(spair[1], F_SETFL, O_NONBLOCK) == -1){
    // Failure in setting pair[1]
    return krr((S) "failed to set socket[1] to non-blocking");
  }
#endif

  // Fook callback functions to event loop
  K ok=sd1(-spair[0], &trigger_callback);
  if(ok==0){
    fprintf(stderr, "adding callback failed\n");
    spair[0]=0;
    spair[1]=0;
    return 0;
  }
  r0(ok);

  // Set protect mode
  CLEAN_STATE=0;

  // Register `detach` functoin to be called at exit
  atexit(detach);

  return KNULL;
}
