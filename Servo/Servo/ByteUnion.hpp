#ifndef __ByteUnion__
#define __ByteUnion__

template <typename T>
union ByteUnion {
    T value;
    uint8_t array[sizeof(T)];
    ByteUnion(T _value) : value(_value) {}
    const std::array<uint8_t, sizeof(T)> arrayObj() {
        std::array<uint8_t, sizeof(T)> obj;
        std::copy(std::begin(array), std::end(array), obj.begin());
        return obj;
    }
};

#endif
