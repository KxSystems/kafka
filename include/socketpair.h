/*
 * socketpair.h
 * Header file of socketpair.c
 * Created to ensure defining functions only once.
 */

#ifndef __SOCKETPAIR_H__
#define __SOCKETPAIR_H__

#include <string.h>

#ifdef _WIN32

# include <winsock2.h>
# include <ws2tcpip.h>
# include <windows.h>
# include <io.h>
#else
# include <sys/types.h>
# include <sys/socket.h>

#endif

#ifdef _WIN32

/**
 * @brief If make_overlapped is nonzero, both sockets created will be usable for
 *  "overlapped" operations via WSASend etc.  If make_overlapped is zero,
 *  socks[0] (only) will be usable with regular ReadFile etc., and thus 
 *  suitable for use as stdin or stdout of a child process.  Note that the
 *  sockets must be closed with closesocket() regardless.
 */
int dumb_socketpair(SOCKET socks[2], int make_overlapped);

#else
int dumb_socketpair(int socks[2], int dummy);
#endif

// __SOCKETPAIR_H__
#endif