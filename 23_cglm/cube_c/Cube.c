// The cube of the cube plugin, in C. cglm.h and draw.h, which OpenECS --definitions writes (OpenECS DESIGN 10.10), give the functions of the cglm and
// draw plugins: C makes its matrices with the same cglm functions as Lua, with vectors and matrices as buffers of floats, and draw draws the edges.

#include "cglm.h" // the cglm plugin's functions
#include "draw.h" // draw's functions; it includes OpenECS.h

#include <stdlib.h>
#include <string.h>

/// @brief The functions of cglm and draw, which CglmFunctions_Get and DrawFunctions_Get look up.
static CglmFunctions CGLM;
static DrawFunctions DRAW;

/// @brief The edges of the cube, as pairs of corners from 0, the same as the Lua plugin's.
static const u32 EDGES[24] = {0, 1, 2, 3, 4, 5, 6, 7, 0, 2, 1, 3, 4, 6, 5, 7, 0, 4, 1, 5, 2, 6, 3, 7};

typedef struct Cube
{
    ECSPanel panel;
    f32 turn;
    f32 scale; // the surface's at the last draw, as events give positions in its pixels
    bool dragging;
    f32 dragX; // where the drag was at its last event, in layout units
} Cube;

/// @brief Floats as the buffer that cglm's functions take: a vector of 3 or 4, or a matrix of 16, column by column.
static SHUSlice CubeBuffer(const f32 *floats, usz count)
{
    return cs((void *)floats, count * sizeof(f32));
}

/// @brief Copies a result of cglm's functions, which lasts until the next call, into floats of its own; an empty result, after a wrong buffer, gives zeros.
static void CubeKeep(SHUSlice result, f32 *retFloats, usz count)
{
    memset(retFloats, 0, count * sizeof(f32));

    if (result.data != nullptr && result.size == count * sizeof(f32))
    {
        memcpy(retFloats, result.data, result.size);
    }
}

/// @brief The matrix that takes a corner to the view: the cube turns around the vertical axis and leans, then the camera and the perspective see it.
static void CubeMatrix(f32 turn, f32 *retMatrix)
{
    const f32 upAxis[3] = {0.0f, 1.0f, 0.0f}, acrossAxis[3] = {1.0f, 0.0f, 0.0f};
    const f32 eye[3] = {0.0f, 2.0f, 5.0f}, center[3] = {0.0f, 0.0f, 0.0f};
    f32 lean[16], model[16], camera[16], projection[16];

    CubeKeep(CGLM.rotateMake(turn, CubeBuffer(upAxis, 3)), model, 16);
    CubeKeep(CGLM.rotateMake(0.4f, CubeBuffer(acrossAxis, 3)), lean, 16);
    CubeKeep(CGLM.mat4Mul(CubeBuffer(model, 16), CubeBuffer(lean, 16)), model, 16);
    CubeKeep(CGLM.lookat(CubeBuffer(eye, 3), CubeBuffer(center, 3), CubeBuffer(upAxis, 3)), camera, 16);

    // 45 degrees, in radians
    CubeKeep(CGLM.perspective(0.7853982f, 1.0f, 0.1f, 50.0f), projection, 16);

    CubeKeep(CGLM.mat4Mul(CubeBuffer(camera, 16), CubeBuffer(model, 16)), retMatrix, 16);
    CubeKeep(CGLM.mat4Mul(CubeBuffer(projection, 16), CubeBuffer(retMatrix, 16)), retMatrix, 16);
}

/// @brief A corner of the cube, from 0, in a view from 0 to 1 each way, from its bottom left, as cglm's project gives it. Each bit of the corner's
/// number picks -1 or 1 on one axis.
static void CubeProject(const f32 *matrix, usz i, f32 *retPoint)
{
    const f32 corner[3] = {(i & 1) ? 1.0f : -1.0f, (i & 2) ? 1.0f : -1.0f, (i & 4) ? 1.0f : -1.0f};
    const f32 viewport[4] = {0.0f, 0.0f, 1.0f, 1.0f};
    CubeKeep(CGLM.project(CubeBuffer(corner, 3), CubeBuffer(matrix, 16), CubeBuffer(viewport, 4)), retPoint, 3);
}

static SHUResult CubeCreate(ECSPanel panel, const ECSValue *savedState, u32 version, void **retState)
{
    (void)savedState;
    (void)version;

    Cube *state = calloc(1, sizeof(Cube));

    if (state == nullptr)
    {
        return SHUResult_ErrAllocation;
    }

    *state = (Cube){.panel = panel, .turn = 0.6f, .scale = 1.0f};
    *retState = state;
    return SHUResult_Ok;
}

static void CubeDestroy(void *state)
{
    free(state);
}

static void CubeDraw(void *data, ECSSurface *surface, f64 seconds)
{
    (void)seconds;
    Cube *state = data;
    state->scale = surface->scale;

    f32 width = (f32)surface->width / surface->scale, height = (f32)surface->height / surface->scale;
    ECSColor background = 0, accent = 0;
    ECSColor_Parse("#101418", &background);
    ECSColor_Parse("accent", &accent);
    DRAW.fill(surface, 0.0f, 0.0f, width, height, background);

    // the square view in the middle of the panel, whose y goes down
    f32 side = width < height ? width : height;
    f32 left = (width - side) / 2.0f, top = (height - side) / 2.0f;
    f32 matrix[16];
    f32 points[16];
    CubeMatrix(state->turn, matrix);

    for (usz i = 0; i < 8; i++)
    {
        f32 point[3];
        CubeProject(matrix, i, point);
        points[i * 2] = left + point[0] * side;
        points[i * 2 + 1] = top + (1.0f - point[1]) * side;
    }

    DRAW.lines(surface, cs(points, sizeof(points)), cs((void *)EDGES, sizeof(EDGES)), 2.0f, accent);
}

// a drag across turns the cube
static void CubeEvent(void *data, const ECSPanelEvent *event)
{
    Cube *state = data;
    f32 x = event->pointer.x / state->scale;

    if (event->type == ECSPanelEventType_PointerDown && event->pointer.button == 1)
    {
        state->dragging = true;
        state->dragX = x;
    }
    else if (event->type == ECSPanelEventType_PointerUp)
    {
        state->dragging = false;
    }
    else if (event->type == ECSPanelEventType_PointerMove && state->dragging)
    {
        state->turn += (x - state->dragX) * 0.01f;
        state->dragX = x;
        ECSPanel_Redraw(state->panel);
    }
}

/// @brief Sets a field of a table to a number.
static SHUResult SetNumber(ECSValue *table, const char *name, f64 number)
{
    ECSValue *field = nullptr;
    SHU_ReturnResult(ECSValue_SetTableField(table, name, &field));
    ECSValue_SetNumber(field, number);
    return SHUResult_Ok;
}

// the turn, and where the last corner is in the view, as the Lua plugin saves them, so the test compares the two
static SHUResult CubeSaveState(void *data, ECSValue *retSavedState)
{
    Cube *state = data;
    f32 matrix[16];
    f32 corner[3];
    CubeMatrix(state->turn, matrix);
    CubeProject(matrix, 7, corner);

    ECSValue_SetTable(retSavedState);
    SHU_ReturnResult(SetNumber(retSavedState, "turn", state->turn));

    ECSValue *saved = nullptr;
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "corner", &saved));
    ECSValue_SetTable(saved);
    SHU_ReturnResult(SetNumber(saved, "x", corner[0]));
    SHU_ReturnResult(SetNumber(saved, "y", corner[1]));
    return SHUResult_Ok;
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    // the manifest's dependencies on cglm and draw make sure their functions exist
    SHU_ReturnResult(CglmFunctions_Get(plugin, &CGLM));
    SHU_ReturnResult(DrawFunctions_Get(plugin, &DRAW));

    const ECSPanelTypeDesc cube = {
        .name = "panel",
        .title = "Cube in C",
        .Create = CubeCreate,
        .Destroy = CubeDestroy,
        .Draw = CubeDraw,
        .Event = CubeEvent,
        .SaveState = CubeSaveState,
    };

    return ECSPanelType_Register(plugin, &cube);
}
