/*
 * osthread was originally versioned @ https://gitlab.com/kxdev/analyst/qcommon
 * Its inclusion here could be made a dependancy, its generally useful for all sorts of projects
 * It is duplicated here for POC.
 * */
#ifndef SRC_OSTHREAD_H_
#define SRC_OSTHREAD_H_

#ifdef _WIN32
#include <windows.h>
#include <processthreadsapi.h>

struct osthread {
    HANDLE handle;
    DWORD id;
};

typedef struct osthread osthread_t;
typedef HANDLE osthread_mutex_t;

#else // IS NOT _WIN32
#include <pthread.h>
#include <signal.h>

typedef pthread_t osthread_t;
typedef pthread_mutex_t osthread_mutex_t;
#endif

struct osthread_attr {
    int stack_size;
};

typedef struct osthread_attr osthread_attr_t;

int osthread_attr_init (osthread_attr_t* attr);
int osthread_create (osthread_t* thread, osthread_attr_t* attr, void(*main)(void*), void* args);
int osthread_detach (osthread_t* thread);
int osthread_kill(osthread_t* thread);
void osthread_exit ();
int osthread_join (osthread_t* thread);
int osthread_mutex_create (osthread_mutex_t* mutex);
int osthread_mutex_lock (osthread_mutex_t* mutex);
int osthread_mutex_unlock (osthread_mutex_t* mutex);
int osthread_mutex_destroy (osthread_mutex_t* mutex);

#endif // SRC_OSTHREAD_H_
