#import <Foundation/Foundation.h>

#ifndef IMUT_IMUTLibVideoEncoderFunctions_H
#define IMUT_IMUTLibVideoEncoderFunctions_H



// Frame timing -->

typedef struct IMFrameTiming {
    double frameTime;          // The time of the frame in the media in seconds with at least milliseond precision
    unsigned long frameNumber; // Frame number in the generated media file
} IMFrameTiming;

typedef IMFrameTiming *IMFrameTimingRef;

IMFrameTimingRef IMFrameTimingCreate(unsigned long frameNumber, double frameTimeInterval);

IMFrameTimingRef IMFrameTimingCopy(IMFrameTimingRef sourceFrameTiming);

void IMFrameTimingRelease(IMFrameTimingRef *frameTiming);



// Input frame and stack -->

#define MAX_FRAME_STACK_SIZE 20

typedef struct IMInputFrame *IMInputFrameRef;

typedef struct IMInputFrameStack *IMInputFrameStackRef;

typedef struct IMInputFrame {
    IMFrameTimingRef timing;               // Timing of the frame
    CVPixelBufferRef const pixelBuffer;    // The pixel data
    IMInputFrameRef nextInputFrame;        // The next input frame in the chain
    const IMInputFrameStackRef frameStack; // Pointer to the frame stack that contains this input frame
} IMInputFrame;

BOOL IMInputFrameStackCreate(unsigned int stackSize, CVPixelBufferPoolRef pixelBufferPool, IMInputFrameStackRef *frameStackPtr);

void IMInputFrameStackRelease(IMInputFrameStackRef *frameStack);

BOOL IMInputFrameStackCreateInputFrame(IMInputFrameStackRef frameStack, IMFrameTimingRef frameTiming, IMInputFrameRef *inputFramePtr);

IMInputFrameRef IMInputFrameStackGetOldestInputFrame(IMInputFrameStackRef frameStack);

void IMInputFrameStackReleaseInputFrame(IMInputFrameRef *frame);

#endif
