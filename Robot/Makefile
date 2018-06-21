INCLUDE_PATHS = -I. -I../sysfs-mbed
LIBRARY_PATHS =
LIBRARIES =
OBJECTS = $(shell find . -regextype gnu-awk -regex '^.*\.c(pp)?$$' | sed -E -e 's/\.c(pp)?$$/.o/g')
TARGET = robot

CC = gcc
CPP = g++
LD = g++ -pthread
CC_FLAGS = -c -Wall -Wextra -MMD -MP -pthread
CXX_FLAGS = -std=gnu++14

ifeq ($(DEBUG), 1)
  CC_FLAGS += -O0 -g
else
  CC_FLAGS += -Os
endif

all: $(TARGET)

clean:
	rm -f *.o *.d $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) $(LIBRARY_PATHS) -o $@ $^ -Wl,--start-group $(LIBRARIES) -Wl,--end-group

%.o: %.c
	@echo "Compile $<"
	$(CC) $(CC_FLAGS) $(INCLUDE_PATHS) -o $@ $<

%.o: %.cpp
	@echo "Compile $<"
	$(CPP) $(CC_FLAGS) $(CXX_FLAGS) $(INCLUDE_PATHS) -o $@ $<

-include $(OBJECTS:.o=.d)
