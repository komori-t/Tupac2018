#ifndef __InterruptIn__
#define __InterruptIn__

#include "DigitalIn.hpp"
#include <pthread.h>
#include <functional>
#include <mutex>

class InterruptIn : public DigitalIn
{
    static void *threadRoutine(void *arg) {
        InterruptIn *self = reinterpret_cast<InterruptIn *>(arg);
        self->pollAndNotify();
        return NULL;
    }
    pthread_t thread;
    std::mutex mutex;
    std::function<void ()> riseCallback;
    std::function<void ()> fallCallback;
    void pollAndNotify() {
        while (1) {
            value.poll();
            std::lock_guard<std::mutex> lock(mutex);
            if (read()) {
                if (riseCallback) riseCallback();
            } else {
                if (fallCallback) fallCallback();
            }
        }
    }

public:
    InterruptIn(uint8_t pin) : DigitalIn(pin) {
        SysfsGPIO edge(pin, "edge", O_WRONLY);
        const char mode[] = "both";
        edge.pwrite(mode, 4);
        pthread_create(&thread, NULL, InterruptIn::threadRoutine, this);
    }
    void rise(std::function<void ()> callback) {
        std::lock_guard<std::mutex> lock(mutex);
        riseCallback = callback;
    }
    void fall(std::function<void ()> callback) {
        std::lock_guard<std::mutex> lock(mutex);
        fallCallback = callback;
    }
    ~InterruptIn() {
        pthread_cancel(thread);
    }
};

#endif
