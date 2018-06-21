INCLUDE_PATHS = -I. -I../Robot $(shell pkg-config opencv zbar --cflags-only-I)
LIBRARY_PATHS = $(shell pkg-config opencv zbar --libs-only-L)
LIBRARIES = $(shell pkg-config opencv zbar --libs-only-l)
OBJECTS = qrcodereader.o ../Robot/UDPClient.o
TARGET = qrcodereader

CC = gcc
CPP = g++
LD = g++
CC_FLAGS = -c -Wall -Wextra -MMD -MP
CXX_FLAGS = -std=gnu++14

ifeq ($(DEBUG), 1)
  CC_FLAGS += -O0 -g
else
  CC_FLAGS += -Os
endif

all: $(TARGET)

clean:
	rm -f qrcodereader.o qrcodereader.d ../Robot/UDPClient.o ../Robot/UDPClient.d $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) $(LIBRARY_PATHS) -o $@ $^ -Wl,--start-group $(LIBRARIES) -Wl,--end-group

%.o: %.c
	@echo "Compile $<"
	$(CC) $(CC_FLAGS) $(INCLUDE_PATHS) -o $@ $<

%.o: %.cpp
	@echo "Compile $<"
	$(CPP) $(CC_FLAGS) $(CXX_FLAGS) $(INCLUDE_PATHS) -o $@ $<

-include $(OBJECTS:.o=.d)
