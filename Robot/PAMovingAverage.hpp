#ifndef __PAMovingAverage__
#define __PAMovingAverage__

#include <stdint.h>

template <typename T, uint32_t numOfMovingValues>
class PAMovingAverage {
    float movingValues[numOfMovingValues];
    float *movingValuesPoint = movingValues;
    float *movingValuesLimit = movingValues + numOfMovingValues;
    float movingAverage;
    
public:
    PAMovingAverage() {
        while (movingValuesPoint != movingValuesLimit) {
            *movingValuesPoint++ = 0;
        }
        movingValuesPoint = movingValues;
        movingAverage = 0;
    }
    T addValue(T value) {
        if (++movingValuesPoint == movingValuesLimit) {
            movingValuesPoint = movingValues;
        }
        movingAverage += (-*movingValuesPoint + static_cast<float>(value)) / numOfMovingValues;
        *movingValuesPoint = value;
        return static_cast<T>(movingAverage);
    }
};

#endif
