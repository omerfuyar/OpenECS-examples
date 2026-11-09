// A 2D vector, in C. A struct type is plain data with fixed fields: functions take and give it by value, and Lua gets it as a table of its fields.
// A handle is an object that a plugin owns and frees (example 5); a struct is a value that anyone can make, copy and keep.

#include "OpenECS.h"

#include <math.h>

// the plugin declares the struct as its signature's fields say: the core lays out the fields as C does, in their order
// the definition header that OpenECS --definitions writes declares it too, as GeometryVec2, for other plugins in C
typedef struct
{
    f32 x;
    f32 y;
} GeometryVec2;

// C gets a struct by pointer: "struct<...>" is a const pointer, valid only during the call, and "out struct<...>" a pointer to fill
static void GeometryAdd(const GeometryVec2 *first, const GeometryVec2 *second, GeometryVec2 *retSum)
{
    *retSum = (GeometryVec2){first->x + second->x, first->y + second->y};
}

static void GeometrySub(const GeometryVec2 *first, const GeometryVec2 *second, GeometryVec2 *retDifference)
{
    *retDifference = (GeometryVec2){first->x - second->x, first->y - second->y};
}

static void GeometryScale(const GeometryVec2 *vector, f32 factor, GeometryVec2 *retScaled)
{
    *retScaled = (GeometryVec2){vector->x * factor, vector->y * factor};
}

static f32 GeometryLength(const GeometryVec2 *vector)
{
    return sqrtf((vector->x * vector->x) + (vector->y * vector->y));
}

static bool GeometryEqual(const GeometryVec2 *first, const GeometryVec2 *second)
{
    return first->x == second->x && first->y == second->y;
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    const ECSPluginDesc desc = {0};
    SHU_ReturnResult(ECSPlugin_Register(plugin, &desc));

    // the type is registered before the functions whose signatures name it; the core adds the plugin's name, so it is geometry.vec2
    SHU_ReturnResult(ECSStruct_Register(plugin, "vec2", "float x, float y"));

    // a struct cannot be a function's result, as C would return it in registers that differ on each system; an out parameter gives it
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "add", (ECSFunction)GeometryAdd, "void(struct<geometry.vec2> first, struct<geometry.vec2> second, out struct<geometry.vec2> sum)", "Adds two vectors"));
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "sub", (ECSFunction)GeometrySub, "void(struct<geometry.vec2> first, struct<geometry.vec2> second, out struct<geometry.vec2> difference)", "Subtracts the second vector from the first"));
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "scale", (ECSFunction)GeometryScale, "void(struct<geometry.vec2> vector, float factor, out struct<geometry.vec2> scaled)", "Multiplies a vector by a number"));
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "length", (ECSFunction)GeometryLength, "float(struct<geometry.vec2> vector)", "Gives a vector's length"));
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "equal", (ECSFunction)GeometryEqual, "bool(struct<geometry.vec2> first, struct<geometry.vec2> second)", "Tells whether two vectors are the same"));

    // a method is a function whose first parameter is the struct: Lua calls it as a:length()
    // a method named as one of Lua's operators is that operator too: add is a + b, sub a - b, and eq a == b
    const char *methods[][2] = {{"add", "add"}, {"sub", "sub"}, {"scale", "scale"}, {"length", "length"}, {"eq", "equal"}};

    for (usz i = 0; i < sizeof(methods) / sizeof(methods[0]); i++)
    {
        SHU_ReturnResult(ECSStruct_AddMethod(plugin, "vec2", methods[i][0], methods[i][1]));
    }

    return SHUResult_Ok;
}
