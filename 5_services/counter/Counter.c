// Named counters, in C. Other plugins, in any language, call its functions by name and signature.
// A function registered by name is a service: keys, menus, presets and other plugins can run it.

#include "OpenECS.h"

#include <string.h>

#define COUNTER_MAX 16
#define COUNTER_NAME_SIZE 32
#define COUNTER_WATCHERS 8

/// @brief A function that hears each change of a counter: void(string name, int value).
typedef void (*CounterWatchFunction)(const char *name, i32 value);

static struct
{
    char names[COUNTER_MAX][COUNTER_NAME_SIZE];
    i64 values[COUNTER_MAX];
    usz count;
    CounterWatchFunction watchers[COUNTER_WATCHERS];
    usz watcherCount;
} COUNTERS = {0};

/// @brief Finds a counter, and makes it if it is new; nullptr if there is no room.
static i64 *CounterFind(const char *name)
{
    for (usz i = 0; i < COUNTERS.count; i++)
    {
        if (strcmp(COUNTERS.names[i], name) == 0)
        {
            return &COUNTERS.values[i];
        }
    }

    if (COUNTERS.count == COUNTER_MAX || strlen(name) >= COUNTER_NAME_SIZE)
    {
        return nullptr;
    }

    strcpy(COUNTERS.names[COUNTERS.count], name);
    return &COUNTERS.values[COUNTERS.count++];
}

// the string is valid only during the call, so it is copied if kept
static i32 CounterAdd(const char *name, i32 amount)
{
    i64 *value = CounterFind(name);

    if (value == nullptr)
    {
        return 0;
    }

    *value += amount;

    for (usz i = 0; i < COUNTERS.watcherCount; i++)
    {
        COUNTERS.watchers[i](name, (i32)*value);
    }

    return (i32)*value;
}

static i32 CounterGet(const char *name)
{
    i64 *value = CounterFind(name);
    return value == nullptr ? 0 : (i32)*value;
}

// a callback of type "keep fn<...>" stays valid after the call, so the plugin can call it later; a plain "fn<...>" is valid only during the call
static bool CounterWatch(CounterWatchFunction watcher)
{
    // a watcher that is not stored is released at once, as nothing calls it later
    if (watcher == nullptr || COUNTERS.watcherCount == COUNTER_WATCHERS)
    {
        ECSService_ReleaseCallback((ECSFunction)watcher);
        return false;
    }

    COUNTERS.watchers[COUNTERS.watcherCount++] = watcher;
    return true;
}

// a kept callback is released once it is no longer called: one that a Lua function gave is freed then
static void CounterDestroy(void *data)
{
    (void)data;

    for (usz i = 0; i < COUNTERS.watcherCount; i++)
    {
        ECSService_ReleaseCallback((ECSFunction)COUNTERS.watchers[i]);
    }

    COUNTERS.watcherCount = 0;
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    const ECSPluginDesc desc = {.Destroy = CounterDestroy};
    SHU_ReturnResult(ECSPlugin_Register(plugin, &desc));

    // the signature tells the core how to pass the arguments: the result's type, then each parameter's type and name
    // the function is cast to ECSFunction, the type of any function; the signature says its real type
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "add", (ECSFunction)CounterAdd, "int(string name, int amount)", "Adds to a named counter, and gives its new value"));
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "get", (ECSFunction)CounterGet, "int(string name)", "Gives a named counter's value"));
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "watch", (ECSFunction)CounterWatch, "bool(keep fn<void(string name, int value)> watcher)", "Calls a function with each change of a counter, until the program exits"));
    return SHUResult_Ok;
}
