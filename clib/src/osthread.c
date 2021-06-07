#include <osthread.h>

int osthread_attr_init (osthread_attr_t* attr) {
    attr->stack_size = 0;
    return 0;
}

#ifdef _WIN32

int osthread_create (osthread_t* thread, osthread_attr_t* attr, void (*main)(void*), void* arg) {
    osthread_attr_t opts;

    if (attr == NULL) {
        if (osthread_attr_init(&opts)) { return -1; }
    } else {
        opts = *attr;
    }

    thread->handle = CreateThread(
        NULL,                           // default security attributes
        opts.stack_size,                // default stack size if 0
        (LPTHREAD_START_ROUTINE)main,   // thread function
        arg,                            // function argument
        0,                              // default creation flags
        &thread->id                     // thread id
    );
    return thread->handle == NULL ? -1 : 0;
}

int osthread_detach (osthread_t* thread) {
    CloseHandle(thread->handle);
    return 0;
}

int osthread_kill (osthread_t* thread) {
#pragma warning(disable : 6258 6387 6001)
    // terminate the thread
    // https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-terminatethread
    if(!TerminateThread(thread->handle, 0x0)){
        // Failed to terminate thread
        return 1;
    }

#pragma warning(disable : 6387)
    // this is required as TerminateThread does not perform proper thread clean-up
    if(!CloseHandle(thread->handle)){
        // Failed to close the handle
        return 1;
    }
    else{
        return 0;
    }
}

void osthread_exit () { ExitThread(0); }

int osthread_join (osthread_t* thread) {
    DWORD result = WaitForSingleObject(thread->handle, INFINITE);
    CloseHandle(thread->handle);
    return result == WAIT_OBJECT_0 ? 0 : -1;
}

int osthread_mutex_create (osthread_mutex_t* mutex) {
    *mutex = CreateMutex(
        NULL,       // default security attributes
        FALSE,      // not initially owned
        NULL        // unnamed mutex
    );
    return *mutex == NULL ? -1 : 0;
}

int osthread_mutex_destroy (osthread_mutex_t* mutex) {
    CloseHandle(*mutex);
    return 0;
}

int osthread_mutex_lock (osthread_mutex_t* mutex) {
    DWORD result = WaitForSingleObject(*mutex, INFINITE);
    return result == WAIT_OBJECT_0 ? 0 : -1;
}

int osthread_mutex_unlock (osthread_mutex_t* mutex) {
    return ReleaseMutex(*mutex) ? 0 : -1;
}

#else

int osthread_create (osthread_t* thread, osthread_attr_t* attr, void (*main)(void*), void* args) {
    pthread_attr_t pt_attr;
    osthread_attr_t opts;
    int ptid;

    if (attr == NULL) {
        if (osthread_attr_init(&opts)) { return -1; }
    } else {
        opts = *attr;
    }

    if (pthread_attr_init(&pt_attr)) { return -1; }
    if (opts.stack_size > 0 && pthread_attr_setstacksize(&pt_attr, opts.stack_size)) { return -1; }

    ptid = pthread_create(thread, &pt_attr, (void*)main, args);
    pthread_attr_destroy(&pt_attr);
    return ptid;
}

int osthread_detach (osthread_t* thread) { (void) thread; return 0; }

int osthread_kill (osthread_t* thread) {
    // Fail value is non-zero.
    return pthread_kill(*thread, SIGTERM); //SIGKILL?
}

void osthread_exit () { pthread_exit(NULL); }

int osthread_join (osthread_t* thread) {
    return pthread_join(*thread, NULL);
}

int osthread_mutex_create (osthread_mutex_t* mutex) {
    return pthread_mutex_init(mutex, NULL);
}

int osthread_mutex_destroy (osthread_mutex_t* mutex) {
    return pthread_mutex_destroy(mutex);
}

int osthread_mutex_lock (osthread_mutex_t* mutex) {
    return pthread_mutex_lock(mutex);
}

int osthread_mutex_unlock (osthread_mutex_t* mutex) {
    return pthread_mutex_unlock(mutex);
}

#endif
