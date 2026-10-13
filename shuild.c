// The build of OpenECS's examples. It runs inside a checkout of OpenECS, in its examples/ folder: OpenECS's shuild.c compiles this file with shu and shuild
// from OpenECS's dependencies/ into shuild.ignore here, and runs it with the build type and OpenECS's build folder (README.md).
// Each numbered folder is copied whole into bin/examples/, its sources and tests too, and the C files of each of its plugin folders are built into the copy.
#define SHU_IMPLEMENTATION
#define SHUC_ENABLE_INCREMENTAL
#define SHUC_NO_RUN_LOG
#include "shuild/shuild.h"

#include <ctype.h>
#include <dirent.h>

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
    const char *output; // OpenECS's build folder, such as ../build/Debug/
} CONFIG = {BuildType_Debug, NULL};

#pragma endregion Setup

#pragma region Declarations

/// @brief Runs a shell command, and stops the build if it fails.
#define RunCheck(cmd, ...) SHU_Assert(!SHU_UtilRun(cmd, ##__VA_ARGS__), "Running " SHUM_COLOR_RED("'%s'") " failed", cmd)

static void SetupConfiguration(int argc, char **argv);
static void ForEachFolder(const char *path, bool numbered, void (*function)(const char *path, const char *name));
static void BuildExample(const char *path, const char *name);

#pragma endregion Declarations

int main(int argc, char **argv)
{
    SHU_CompilerTryConfigure("gcc");
    SetupConfiguration(argc, argv);

    // the copies keep their files' times, and the plugins are built from these folders into the copies, so a second build compiles only what changed
    SHUI_String folder;
    SHUI_SFormat(&folder, "%sbin/examples/", CONFIG.output);
    RunCheck("mkdir -p %s && cp -rp [0-9]* %s", folder.data, folder.data);
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
           "  -h, --help           Show this help\n");
    exit(status);
}

/// @brief Stops the build with what is wrong, the argument, and the usage.
static void Refuse(const char *what, const char *argument)
{
    SHU_LogError(0, "%s: " SHUM_COLOR_RED("'%s'"), what, argument);
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

    SHUI_String cache;
    SHUI_SFormat(&cache, ".shu/%s/", BUILD_TYPE_STRINGS[CONFIG.type]);
    SHU_CacheConfigure(cache.data);
}

// the examples' plugins get OpenECS's warnings, and in Debug its static analyzer and sanitizers, as OpenECS's own code does
static void SetBuildFlags(void)
{
    SHU_CompilerClearFlags();
    SHU_CompilerAddFlags(SHUM_FLAGS_STANDARD_C23 " -fvisibility=hidden");

    switch (CONFIG.type)
    {
    case BuildType_Debug:
        SHU_CompilerAddFlags(SHUM_FLAGS_WARNING_MID " -fanalyzer -fsanitize=address,undefined -fno-omit-frame-pointer" SHUM_FLAGS_DEBUG SHUM_FLAGS_OPTIMIZATION_DEBUG);
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

static bool EndsWith(const char *name, const char *suffix)
{
    size_t nameLength = strlen(name);
    size_t suffixLength = strlen(suffix);
    return nameLength >= suffixLength && strcmp(name + nameLength - suffixLength, suffix) == 0;
}

/// @brief Calls a function for each folder in a folder, in no order; names starting with a dot are left out, and, with numbered, names that do not start with a digit.
static void ForEachFolder(const char *path, bool numbered, void (*function)(const char *path, const char *name))
{
    DIR *folder = opendir(path);
    struct dirent *entry = NULL;

    while (folder != NULL && (entry = readdir(folder)) != NULL)
    {
        if (entry->d_type == DT_DIR && entry->d_name[0] != '.' && (!numbered || isdigit((unsigned char)entry->d_name[0])))
        {
            function(path, entry->d_name);
        }
    }

    if (folder != NULL)
    {
        closedir(folder);
    }
}

/// @brief Compiles the C files of a plugin folder of an example into its native library, in the folder's copy in bin/examples/. Does nothing if the folder has no C file.
static void BuildPlugin(const char *path, const char *name)
{
    SHUI_String root;
    SHUI_SFormat(&root, "%s%s/", path, name);

    bool code = false;
    DIR *folder = opendir(root.data);
    struct dirent *entry = NULL;

    while (folder != NULL && (entry = readdir(folder)) != NULL)
    {
        code = code || EndsWith(entry->d_name, ".c");
    }

    if (folder != NULL)
    {
        closedir(folder);
    }

    if (!code)
    {
        return;
    }

    // the plugin sees only OpenECS's plugin interface and SDL, from the build's include/ folder, named from the plugin's folder
    SHUI_String include;
    SHUI_String output;
    SHUI_SFormat(&include, "../../%sinclude/", CONFIG.output);
    SHUI_SFormat(&output, "%sbin/examples/%s", CONFIG.output, root.data);

    // shuild compiles only the files that changed, so a library that is missing, such as after a clean copy, is built from all of them
    SHUI_String library;
    SHUI_SFormat(&library, "%slib%s.so", output.data, name);

    if (SHU_UtilFileExists(library.data) != SHUFileType_Regular)
    {
        SHU_CacheClearModule(name);
    }

    SHU_ModuleBegin(name, root.data);
    SetBuildFlags();
    SHU_ModuleAddSourceFile("./");
    SHU_ModuleAddIncludeDirectory(include.data);
    SHU_ModuleCompile(output.data, SHUModuleType_LibraryDynamic);
}

/// @brief Builds the plugin folders of an example.
static void BuildExample(const char *path, const char *name)
{
    SHUI_String root;
    SHUI_SFormat(&root, "%s%s/", path, name);
    ForEachFolder(root.data, false, BuildPlugin);
}
