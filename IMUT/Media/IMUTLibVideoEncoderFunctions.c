#import <libkern/OSAtomic.h>
#import <CoreVideo/CoreVideo.h>
#import "Macros.h"
#include "IMUTLibVideoEncoderFunctions.h"

#define ALLOCATOR kCFAllocatorDefault

IMFrameTimingRef IMFrameTimingCreate(unsigned long frameNumber, double frameTimeInterval) {
    IMFrameTimingRef timing = (IMFrameTimingRef) CFAllocatorAllocate(ALLOCATOR, sizeof(IMFrameTiming), 0);

    *timing = (IMFrameTiming) {
        frameTimeInterval,
        frameNumber
    };

    return timing;
}

IMFrameTimingRef IMUTCopyFrameTiming(IMFrameTimingRef sourceFrameTiming) {
    if (sourceFrameTiming != NULL) {
        IMFrameTimingRef copy = (IMFrameTimingRef) CFAllocatorAllocate(ALLOCATOR, sizeof(IMFrameTiming), 0);

        *copy = *sourceFrameTiming;

        return copy;
    }

    return NULL;
}

void IMUTFrameTimingRelease(IMFrameTimingRef *frameTiming) {
    if (*frameTiming != NULL) {
        CFAllocatorDeallocate(kCFAllocatorDefault, *frameTiming);
        *frameTiming = NULL;
    }
}

typedef struct IMInputFrameStack {
    IMInputFrameRef oldestFrame;                // Pointer to the oldest input frame
    IMInputFrameRef newestFrame;                // Pointer to the newest input frame
    unsigned int occupiedSize;                  // Amount of memory in the stack already occupied
    const unsigned int stackSize;               // Stack size
    CVPixelBufferPoolRef const pixelBufferPool; // Pixel buffer pool used to create pixel buffers for new frames
    OSSpinLock lock;                            // A Lock used to make stack operations atomic
    IMInputFrameRef frameRefs[];                // Pointers to the IMInputFrames in the data store
    IMInputFrame frames[];                      // Data store for contained IMInputFrames
} IMInputFrameStack;

BOOL IMInputFrameStackCreate(unsigned int stackSize, CVPixelBufferPoolRef pixelBufferPool, IMInputFrameStackRef *frameStackPtr) {
    *frameStackPtr = NULL;
    unsigned int maxFrameStackSize = MAX_FRAME_STACK_SIZE;
    size_t structSize, frameRefSize, frameSize;
    void *mem;

    stackSize = MAX(stackSize, maxFrameStackSize);

    if (stackSize == 0) {
        return NO;
    }

    structSize = sizeof(IMInputFrameStack);
    frameRefSize = sizeof(IMInputFrameRef) * stackSize;
    frameSize = sizeof(IMInputFrame) * stackSize;

    frameStackPtr = CFAllocatorAllocate(ALLOCATOR, structSize + frameRefSize + frameSize, 0);
    if (frameStackPtr != NULL) {
        // Initialize frame stack struct
        **frameStackPtr = (IMInputFrameStack) {
            .oldestFrame = NULL,
            .newestFrame = NULL,
            .occupiedSize = 0,
            .stackSize = stackSize,
            .pixelBufferPool = pixelBufferPool,
            .lock = OS_SPINLOCK_INIT,
            .frameRefs = *(char*)frameStackPtr + structSize,
            .frames = frameStackPtr + structSize + frameRefSize
        };

        // Initialize frame refs with NULL pointers
        memset((*frameStackPtr)->frameRefs, 0, frameRefSize * stackSize);

        return YES;
    }

    return NO;
}

void IMInputFrameStackRelease(IMInputFrameStackRef *frameStack) {
    unsigned int i;

    if (*frameStack != NULL) {
        OSSpinLockLock(&(*frameStack)->lock);

        IMInputFrameRef inputFrame;
        for (i = 0; i < (*frameStack)->stackSize; i++) {
            inputFrame = &(*frameStack)->frames + i;
            IMInputFrameStackReleaseInputFrame(&inputFrame);
        }

        CFAllocatorDeallocate(ALLOCATOR, *frameStack);

        OSSpinLockUnlock(&(*frameStack)->lock);
    }
}

BOOL IMInputFrameStackCreateInputFrame(IMInputFrameStackRef frameStack, IMFrameTimingRef frameTiming, IMInputFrameRef *inputFramePtr) {
    unsigned int index = UINT_MAX;
    unsigned int newestFrameindex;
    unsigned int i;
    CVPixelBufferRef pixelBuffer;

    OSSpinLockLock(&frameStack->lock);

    if (frameStack->occupiedSize == frameStack->stackSize) {
        return NO;
    }

    CVReturn status = CVPixelBufferPoolCreatePixelBuffer(ALLOCATOR, frameStack->pixelBufferPool, &pixelBuffer);

    if (status != kCVReturnSuccess) {
        return NO;
    }

    // Guess index by assuming serial processing of frames in the order of creation
    i = 0;
    if (frameStack->newestFrame != NULL) {
        if (frameStack->newestFrame == &frameStack->frames[frameStack->stackSize]) {
            index = 0;
        }

        if (&frameStack->frames[0] != NULL) {
            index = i;
        }
    }

    // Must find free index anywhere in between, can be anywhere
    // This should really never happen
    if (index == UINT_MAX) {
        i = index;
        while (true) {
            if (i == frameStack->stackSize) {
                i = 0;
            }

            if (frameStack->frames[i] != NULL) {
                index = i;
                break;
            }

            if (i == index - 1) {
                break;
            }

            i++;
        }
    }

    assertMsg(index != UINT_MAX, "No more space in frame stack though occupation hint told so.");

    frameStack->occupiedSize++;

    *inputFramePtr = &frameStack->frames + index;
    **inputFramePtr = (IMInputFrame) {
        .timing = frameTiming,
        .pixelBuffer = pixelBuffer,
        .nextInputFrame = NULL,
        .frameStack = frameStack
    };

    if (frameStack->newestFrame != NULL) {
        frameStack->newestFrame->nextInputFrame = *inputFramePtr;
    }

    frameStack->newestFrame = *inputFramePtr;

    OSSpinLockUnlock(&frameStack->lock);

    return YES;
}

IMInputFrameRef IMInputFrameStackGetOldestInputFrame(IMInputFrameStackRef frameStack) {
    return frameStack->oldestFrame;
}

// Can run unlocked
void IMInputFrameStackReleaseInputFrame(IMInputFrameRef *frame) {
    IMInputFrameStackRef frameStack = (*frame)->frameStack;

    if (*frame != NULL) {
        if (*frame == frameStack->oldestFrame && (*frame)->nextInputFrame != NULL) {
            frameStack->oldestFrame = (*frame)->nextInputFrame;
        }

        IMFrameTimingRelease(&(*frame)->timing);
        CVPixelBufferRelease((*frame)->pixelBuffer);

        frameStack->occupiedSize--;

        *frame = NULL;
    }
}
