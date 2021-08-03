#ifndef __QTFM_H__
#define __QTFM_H__

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include "k.h"

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#ifdef __cplusplus
extern "C"{
#endif

//%% Export as Library %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/**
 * @brief Execute conversion with the specifed pipeline.
 * @param pipeline_name_: Name of pipeline to use.
 * @param message: Message to convert.
 * @return Converted message.
 */
K transform(K pipeline_name_, K message);

#ifdef __cplusplus
}
#endif

// __QTFM_H__
#endif
