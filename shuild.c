// The build of OpenECS's examples. It runs inside a checkout of OpenECS, in its examples/ folder: OpenECS's shuild.c compiles this file with shu and shuild
// from OpenECS's dependencies/ into shuild.ignore here, and runs it with the build type and OpenECS's build folder (README.md).
// Each example's folder, named c or s and its number, such as c1_hello, is copied whole into bin/examples/, its sources and tests too, and the C files of each of its plugin folders are built into the copy.
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

static bool ReadArguments(int argc, char **argv);
static void Configure(void);
static void ForEachFolder(const char *path, bool examplesOnly, void (*function)(const char *path, const char *name));
static void BuildExample(const char *path, const char *name);
static void RemoveOldExample(const char *path, const char *name);

#pragma endregion Declarations

int main(int argc, char **argv)
{
    // the help stops the build here
    if (!ReadArguments(argc, argv))
    {
        return 0;
    }

    Configure();
    ForEachFolder("./", true, BuildExample);

    // a copy of an example that is gone, or was renamed, would still run its tests
    ForEachFolder(SHU_UtilFormat("%sbin/examples/", CONFIG.output), false, RemoveOldExample);
    return 0;
}

static void PrintUsage(void)
{
    printf("Usage: ./shuild.ignore -o FOLDER [FLAG...]\n\n"
           "OpenECS's shuild.c runs this build with its --examples flag; see OpenECS's README.md.\n\n"
           "Flags:\n"
           "  -o, --output FOLDER  OpenECS's build folder, named from this folder, such as ../build/Debug/\n"
           "  -b, --build TYPE     Build type: debug (the default), release, relwithdebinfo or minsizerel\n"
           "  -c, --compiler CC    OpenECS's compiler: gcc (the default), clang, or one for Windows, such as x86_64-w64-mingw32-clang\n"
           "  -h, --help           Show this help\n");
}

/// @brief Stops the build with the usage, what is wrong and the argument.
static void Refuse(const char *what, const char *argument)
{
    PrintUsage();
    SHU_UtilFail("%s: " SHUM_LOG_VALUE("%s"), what, argument);
}

/// @brief Reads every flag into CONFIG. Returns false when the flags ask for the help, which it prints.
static bool ReadArguments(int argc, char **argv)
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
            CONFIG.compiler = i + 1 < argc ? argv[++i] : CONFIG.compiler;
        }
        else if (!strcmp(flag, "-h") || !strcmp(flag, "--help"))
        {
            PrintUsage();
            return false;
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

    return true;
}

/// @brief Configures the compiler and shuild's cache.
static void Configure(void)
{
    SHU_CompilerConfigureTry(CONFIG.compiler);
    CONFIG.windows = SHU_CompilerGetTarget() == SHUPlatform_Windows;

    // a build for another system has a cache of its own, as OpenECS's build has a folder of its own
    SHUPlatform target = SHU_CompilerGetTarget();
    char *cache = SHU_UtilFormat(".shu/%s%s%s/", BUILD_TYPE_STRINGS[CONFIG.type], SHUM_PLATFORM_IS_HOST(target) ? "" : "-", SHUM_PLATFORM_IS_HOST(target) ? "" : SHUPlatform_GetString(target));
    SHU_CacheConfigure(cache);
}

// the examples' plugins get OpenECS's warnings, and in Debug gcc's static analyzer and the sanitizers, as OpenECS's own code does, except where MinGW has no sanitizers
static void SetBuildFlags(void)
{
    SHU_CompilerClearFlags();
    SHU_CompilerAddFlags(SHUM_FLAGS_STANDARD_C23, "-fvisibility=hidden");

    switch (CONFIG.type)
    {
    case BuildType_Debug:
        SHU_CompilerAddFlags(SHUM_FLAGS_WARNING_MID, SHUM_FLAGS_DEBUG, SHUM_FLAGS_OPTIMIZATION_DEBUG);

        if (SHU_CompilerGetFamily() == SHUCompiler_GCC)
        {
            SHU_CompilerAddFlags("-fanalyzer");
        }

        if (!CONFIG.windows)
        {
            SHU_CompilerAddFlags("-fsanitize=address,undefined", "-fno-omit-frame-pointer");
        }

        SHU_CompilerAddDefinitions("DEBUG", NULL);
        break;
    case BuildType_Release:
        SHU_CompilerAddFlags(SHUM_FLAGS_OPTIMIZATION_HIGH);
        SHU_CompilerAddDefinitions("NDEBUG", NULL);
        break;
    case BuildType_RelWithDebInfo:
        SHU_CompilerAddFlags(SHUM_FLAGS_WARNING_LOW, SHUM_FLAGS_DEBUG, SHUM_FLAGS_OPTIMIZATION_MID);
        SHU_CompilerAddDefinitions("NDEBUG", NULL);
        break;
    case BuildType_MinSizeRel:
        SHU_CompilerAddFlags(SHUM_FLAGS_OPTIMIZATION_SIZE);
        SHU_CompilerAddDefinitions("NDEBUG", NULL);
        break;
    }
}

/// @brief A folder that ForEachFolder lists, and what it calls for each folder in it.
typedef struct FolderVisit
{
    const char *path;
    bool examplesOnly;
    void (*function)(const char *path, const char *name);
} FolderVisit;

static void VisitFolder(const char *entry, SHUFileType type, void *data)
{
    const FolderVisit *visit = (const FolderVisit *)data;

    // the entry is the folder's path, with a separator at its end; the function gets its name alone
    char *name = SHU_UtilFormat("%.*s", (int)(strlen(entry) - strlen(visit->path) - 1), entry + strlen(visit->path));

    // an example's name is c, for the plugin interface, or s, for the standard plugins, then its number, such as c1_hello or s1_terminal
    bool example = (name[0] == 'c' || name[0] == 's') && isdigit((unsigned char)name[1]);

    if (type == SHUFileType_Directory && (!visit->examplesOnly || example))
    {
        visit->function(visit->path, name);
    }
}

/// @brief Calls a function for each folder in a folder, sorted by name; names starting with a dot are left out, and, with examplesOnly, the folders that are no example.
static void ForEachFolder(const char *path, bool examplesOnly, void (*function)(const char *path, const char *name))
{
    FolderVisit visit = {path, examplesOnly, function};
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

    // the plugin sees only the build's include/ folder, as any plugin's author does: OpenECS's plugin interface, and the standard plugins' headers,
    // such as ui.h, named from the plugin's folder (OpenECS DESIGN 17.6)
    char *include = SHU_UtilFormat("../../%sinclude/", CONFIG.output);
    char *output = SHU_UtilFormat("%sbin/examples/%s", CONFIG.output, strncmp(root, "./", 2) ? root : root + 2);

    SHU_MODULE(name, root, SHUModuleType_LibraryDynamic, output)
    {
        SetBuildFlags();
        SHU_ModuleAddSourceFiles("./");
        SHU_ModuleAddIncludeDirectories(include);

        // a DLL calls OpenECS through its import library, in OpenECS's lib/ (OpenECS DESIGN 17.2); elsewhere the calls are resolved when it is loaded
        if (CONFIG.windows)
        {
            SHU_ModuleAddLibraryDirectories(SHU_UtilFormat("%slib/", CONFIG.output));
            SHU_ModuleLinkLibraries("OpenECS");
        }
    }
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

/// @brief Deletes a folder of bin/examples/ whose example is no longer here.
static void RemoveOldExample(const char *path, const char *name)
{
    if (SHU_UtilFileExists(name) != SHUFileType_Directory)
    {
        SHU_UtilDeleteFile(SHU_UtilFormat("%s%s/", path, name));
    }
}
