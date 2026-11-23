// Calls a Lua plugin's function from C. C gets a Lua function as a C function pointer of its signature.

#include "OpenECS.h"

/// @brief tally.addTo, in C: int(string name, int amount, out string error).
typedef i32 (*BonusAddToFunction)(const char *name, i32 amount, const char **retError);

static struct
{
    ECSPlugin plugin;
    BonusAddToFunction addTo;
} BONUS = {0};

static void BonusGive(void)
{
    const char *error = nullptr;

    // the Lua function fails as a C one does: when it works, error is nullptr
    if (BONUS.addTo("clicks", 10, &error) == 0 && error != nullptr)
    {
        ECS_Log(BONUS.plugin, ECSLogLevel_Warning, "No bonus: %s", error);
    }
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    BONUS.plugin = plugin;
    const ECSPluginDesc desc = {0};
    SHU_ReturnResult(ECSPlugin_Register(plugin, &desc));

    // a plugin looks up the functions of the plugins its manifest depends on, by name and the signature it expects
    SHU_ReturnResult(ECSService_GetFunction(plugin, (ECSFunction *)&BONUS.addTo, "tally.addTo", "int(string, int, out string)"));
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "give", (ECSFunction)BonusGive, "void()", "Adds 10 clicks"));
    return SHUResult_Ok;
}
