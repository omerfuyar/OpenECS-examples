// The build of OpenECS's examples. It runs inside a checkout of OpenECS, in its examples/ folder: OpenECS's shuild.c compiles this file with shu and shuild
// from OpenECS's dependencies/ into shuild.ignore here, and runs it with the build type and OpenECS's build folder (README.md).
// Each numbered folder is copied whole into bin/examples/, its sources and tests too, and the C files of each of its plugin folders are built into the copy.
#define SHU_IMPLEMENTATION
#define SHUC_ENABLE_INCREMENTAL
#include "shuild/shuild.h"

#include <ctype.h>

#pragma region Setup

typedef enum BuildType
{
    BuildType_Debug,
    BuildType_Release,
    BuildType_RelWithDebInfo,
    BuildType_MinSizeRel,
} BuildType;

static const char *const BUILD_TYPE_STRINGS[] = {"Debug", "Release", "RelWithDebInfo", "MinSizeRel"};
#define BuildType_String(buildType) BUILD_TYPE_STRINGS[(buildType)]

/// @brief What the flags choose.
static struct
{
    BuildType type;
    const char *output;   // OpenECS's build folder, such as ../build/Debug/
    const char *compiler; // OpenECS's compiler, such as gcc, or x86_64-w64-mingw32-clang for Windows
    bool windows;         // the compiler compiles for Windows
} CONFIG = {BuildType_Debug, NULL, "gcc", false};

#pragma endregion Setup

#pragma region Declarations

static void SetupConfiguration(int argc, char **argv);
static void ForEachFolder(const char *path, bool numbered, void (*function)(const char *path, const char *name));
static void BuildExample(const char *path, const char *name);

#pragma endregion Declarations

/// @brief The compiler that the flags name, or gcc.
static const char *CompilerArgument(int argc, char **argv)
{
    for (int i = 1; i + 1 < argc; i++)
    {
        if (!strcmp(argv[i], "-c") || !strcmp(argv[i], "--compiler"))
        {
            return argv[i + 1];
        }
    }

    return CONFIG.compiler;
}

int main(int argc, char **argv)
{
    CONFIG.compiler = CompilerArgument(argc, argv);
    SHU_CompilerConfigureTry(CONFIG.compiler);
    CONFIG.windows = SHU_CompilerGetTarget() == SHUPlatform_Windows;
    SetupConfiguration(argc, argv);

    ForEachFolder("./", true, BuildExample);
    return 0;
}

static void PrintUsageAndExit(int status)
{
    printf("Usage: ./shuild.ignore -o FOLDER [FLAG...]\n\n"
           "OpenECS's shuild.c runs this build with its --examples flag; see OpenECS's README.md.\n\n"
           "Flags:\n"
           "  -o, --output FOLDER  OpenECS's build folder, named from this folder, such as ../build/Debug/\n"
           "  -b, --build TYPE     Build type: debug (the default), release, relwithdebinfo or minsizerel\n"
           "  -c, --compiler CC    OpenECS's compiler: gcc (the default), clang, or one for Windows, such as x86_64-w64-mingw32-clang\n"
           "  -h, --help           Show this help\n");
    exit(status);
}

/// @brief Stops the build with what is wrong, the argument, and the usage.
static void Refuse(const char *what, const char *argument)
{
    SHU_UtilFail(0, "%s: " SHUM_LOG_VALUE("%s"), what, argument);
    PrintUsageAndExit(1);
}

static void SetupConfiguration(int argc, char **argv)
{
    for (int i = 1; i < argc; i++)
    {
        const char *flag = argv[i];

        if (!strcmp(flag, "-b") || !strcmp(flag, "--build"))
        {
            const char *name = i + 1 < argc ? argv[++i] : "";
            usz type = 0;

            while (type < sizeof(BUILD_TYPE_STRINGS) / sizeof(*BUILD_TYPE_STRINGS) && strcasecmp(name, BuildType_String(type)) != 0)
            {
                type++;
            }

            if (type == sizeof(BUILD_TYPE_STRINGS) / sizeof(*BUILD_TYPE_STRINGS))
            {
                Refuse("Unknown build type", name);
            }

            CONFIG.type = (BuildType)type;
        }
        else if (!strcmp(flag, "-o") || !strcmp(flag, "--output"))
        {
            CONFIG.output = i + 1 < argc ? argv[++i] : NULL;
        }
        else if (!strcmp(flag, "-c") || !strcmp(flag, "--compiler"))
        {
            // main configured the compiler already
            i++;
        }
        else if (!strcmp(flag, "-h") || !strcmp(flag, "--help"))
        {
            PrintUsageAndExit(0);
        }
        else
        {
            Refuse(flag[0] == '-' ? "Unknown flag" : "Unknown argument", flag);
        }
    }

    if (CONFIG.output == NULL || CONFIG.output[0] == '\0' || CONFIG.output[strlen(CONFIG.output) - 1] != '/')
    {
        Refuse("The output folder is missing, or does not end with /", CONFIG.output == NULL ? "" : CONFIG.output);
    }

    // a build for another system has a cache of its own, as OpenECS's build has a folder of its own
    SHUPlatform target = SHU_CompilerGetTarget();
    char *cache = SHU_UtilFormat(".shu/%s%s%s/", BUILD_TYPE_STRINGS[CONFIG.type], SHUM_PLATFORM_IS_HOST(target) ? "" : "-", SHUM_PLATFORM_IS_HOST(target) ? "" : SHUPlatform_GetString(target));
    SHU_CacheConfigure(cache);
}

// the examples' plugins get OpenECS's warnings, and in Debug gcc's static analyzer and the sanitizers, as OpenECS's own code does, except where MinGW has no sanitizers
static void SetBuildFlags(void)
{
    SHU_CompilerClearFlags();
    SHU_CompilerAddFlags(SHUM_FLAGS_STANDARD_C23 " -fvisibility=hidden");

    switch (CONFIG.type)
    {
    case BuildType_Debug:
        SHU_CompilerAddFlags(SHUM_FLAGS_WARNING_MID SHUM_FLAGS_DEBUG SHUM_FLAGS_OPTIMIZATION_DEBUG);

        if (SHU_CompilerGetFamily() == SHUCompiler_GCC)
        {
            SHU_CompilerAddFlags(" -fanalyzer");
        }

        if (!CONFIG.windows)
        {
            SHU_CompilerAddFlags(" -fsanitize=address,undefined -fno-omit-frame-pointer");
        }

        SHU_CompilerAddDefinitions("DEBUG", NULL, "SDL_ASSERT_LEVEL", "2");
        break;
    case BuildType_Release:
        SHU_CompilerAddFlags(SHUM_FLAGS_OPTIMIZATION_HIGH);
        SHU_CompilerAddDefinitions("NDEBUG", NULL, "SDL_ASSERT_LEVEL", "0");
        break;
    case BuildType_RelWithDebInfo:
        SHU_CompilerAddFlags(SHUM_FLAGS_WARNING_LOW SHUM_FLAGS_DEBUG SHUM_FLAGS_OPTIMIZATION_MID);
        SHU_CompilerAddDefinitions("NDEBUG", NULL, "SDL_ASSERT_LEVEL", "0");
        break;
    case BuildType_MinSizeRel:
        SHU_CompilerAddFlags(SHUM_FLAGS_OPTIMIZATION_SIZE);
        SHU_CompilerAddDefinitions("NDEBUG", NULL, "SDL_ASSERT_LEVEL", "0");
        break;
    }
}

/// @brief A folder that ForEachFolder lists, and what it calls for each folder in it.
typedef struct FolderVisit
{
    const char *path;
    bool numbered;
    void (*function)(const char *path, const char *name);
} FolderVisit;

static void VisitFolder(const char *entry, SHUFileType type, void *data)
{
    const FolderVisit *visit = (const FolderVisit *)data;

    // the entry is the folder's path, with a separator at its end; the function gets its name alone
    char *name = SHU_UtilFormat("%.*s", (int)(strlen(entry) - strlen(visit->path) - 1), entry + strlen(visit->path));

    if (type == SHUFileType_Directory && (!visit->numbered || isdigit((unsigned char)name[0])))
    {
        visit->function(visit->path, name);
    }
}

/// @brief Calls a function for each folder in a folder, sorted by name; names starting with a dot are left out, and, with numbered, names that do not start with a digit.
static void ForEachFolder(const char *path, bool numbered, void (*function)(const char *path, const char *name))
{
    FolderVisit visit = {path, numbered, function};
    SHU_UtilListDirectory(path, false, VisitFolder, &visit);
}

static void FindCode(const char *path, SHUFileType type, void *data)
{
    *(bool *)data = *(bool *)data || (type == SHUFileType_Regular && SHU_UtilMatch(path, "*.c"));
}

/// @brief Compiles the C files of a plugin folder of an example into its native library, in the folder's copy in bin/examples/. Does nothing if the folder has no C file.
static void BuildPlugin(const char *path, const char *name)
{
    char *root = SHU_UtilFormat("%s%s/", path, name);

    bool code = false;
    SHU_UtilListDirectory(root, false, FindCode, &code);

    if (!code)
    {
        return;
    }

    // the plugin sees only OpenECS's plugin interface and SDL, from the build's include/ folder, and the standard plugins' headers, such as ui.h,
    // from its definitions/ folder, both named from the plugin's folder (OpenECS DESIGN 17.6)
    char *include = SHU_UtilFormat("../../%sinclude/", CONFIG.output);
    char *definitions = SHU_UtilFormat("../../%sdefinitions/", CONFIG.output);
    char *output = SHU_UtilFormat("%sbin/examples/%s", CONFIG.output, strncmp(root, "./", 2) ? root : root + 2);

    SHU_ModuleBegin(name, root);
    SetBuildFlags();
    SHU_ModuleAddSourceFile("./");
    SHU_ModuleAddIncludeDirectory(include);
    SHU_ModuleAddIncludeDirectory(definitions);

    // a DLL calls OpenECS and SDL through their import libraries, in OpenECS's lib/ (OpenECS DESIGN 17.2); elsewhere the calls are resolved when it is loaded
    if (CONFIG.windows)
    {
        SHU_ModuleAddLibraryDirectory(SHU_UtilFormat("%slib/", CONFIG.output));
        SHU_ModuleLinkLibrary("OpenECS");
        SHU_ModuleLinkLibrary("SDL3_ttf");
        SHU_ModuleLinkLibrary("SDL3");
    }

    SHU_ModuleCompile(output, SHUModuleType_LibraryDynamic);
}

/// @brief Copies an example's folder whole into bin/examples/, and builds its plugin folders into the copy.
/// Shuild leaves a copied file that has not changed as is, and the plugins are built from the example's folders, so a second build compiles only what changed.
static void BuildExample(const char *path, const char *name)
{
    char *root = SHU_UtilFormat("%s%s/", path, name);
    char *copy = SHU_UtilFormat("%sbin/examples/%s/", CONFIG.output, name);
    SHU_UtilCopyFile(root, copy);
    ForEachFolder(root, false, BuildPlugin);
}
