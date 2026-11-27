// A panel that draws, with the GPU and in C, the picture that the Lua plugin shapes draws: gpu's shapes, which take draw's arguments, two clips, one
// inside the other, and text in a font and in its bold style, which draw gives and gpu draws.

#include "draw.h" // draw's functions, for the fonts; it includes OpenECS.h
#include "gpu.h"  // gpu's functions

#include <stdlib.h>

static struct
{
    ECSPlugin plugin;
    DrawFunctions draw;
    GpuFunctions gpu;
    void *regular;
    void *bold;
    ECSSurface *surface; // the surface that the clips' functions draw into, while the panel draws
} SHAPES = {0};

static SHUResult ShapesCreate(ECSPanel panel, const ECSValue *savedState, u32 version, void **retState)
{
    (void)panel;
    (void)savedState;
    (void)version;
    *retState = nullptr;
    return SHUResult_Ok;
}

static void ShapesDestroy(void *data)
{
    (void)data;
}

// a clip's function takes nothing, so the surface is kept while the panel draws
static void ShapesInner(void)
{
    SHAPES.gpu.clear(SHAPES.surface, 0xFFD08770);
}

static void ShapesOuter(void)
{
    SHAPES.gpu.fill(SHAPES.surface, 150.0f, 60.0f, 40.0f, 40.0f, 0xFFB48EAD);
    SHAPES.gpu.clip(SHAPES.surface, 150.0f, 60.0f, 40.0f, 10.0f, ShapesInner);
}

static void ShapesDraw(void *data, ECSSurface *surface, f64 seconds)
{
    (void)data;
    (void)seconds;
    GpuFunctions *gpu = &SHAPES.gpu;
    gpu->clear(surface, 0xFF1B2A4A);
    gpu->rounded(surface, 10.0f, 10.0f, 60.0f, 40.0f, 12.0f, 0xFFBF616A);
    gpu->roundedOutline(surface, 80.0f, 10.0f, 60.0f, 40.0f, 12.0f, 4.0f, 0xFFA3BE8C);
    gpu->circle(surface, 40.0f, 80.0f, 20.0f, 0.0f, 0xFFEBCB8B);
    gpu->circle(surface, 110.0f, 80.0f, 20.0f, 4.0f, 0xFF5E81AC);
    gpu->outline(surface, 150.0f, 10.0f, 40.0f, 40.0f, 3.0f, 0xFF88C0D0);

    SHAPES.surface = surface;
    gpu->clip(surface, 150.0f, 60.0f, 20.0f, 40.0f, ShapesOuter);
    SHAPES.surface = nullptr;

    gpu->text(surface, SHAPES.regular, "Wide", 10.0f, 110.0f, 16.0f, 0xFFECEFF4);
    gpu->text(surface, SHAPES.bold, "Wide", 10.0f, 130.0f, 16.0f, 0xFFECEFF4);
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    SHAPES.plugin = plugin;
    SHU_ReturnResult(DrawFunctions_Get(plugin, &SHAPES.draw));
    SHU_ReturnResult(GpuFunctions_Get(plugin, &SHAPES.gpu));
    // an out argument is always given; the error stays nothing when there is a font
    const char *error = nullptr;
    SHAPES.regular = SHAPES.draw.font("ui", &error);
    SHAPES.bold = SHAPES.draw.styledFont("ui", "bold", &error);

    if (SHAPES.regular == nullptr || SHAPES.bold == nullptr)
    {
        ECS_LogError(plugin, "Cannot make the fonts: %s", error);
        return SHUResult_ErrAllocation;
    }

    const ECSPanelTypeDesc panel = {
        .name = "panel",
        .title = "Shapes in C",
        .surface = ECSSurfaceType_Gpu,
        .Create = ShapesCreate,
        .Destroy = ShapesDestroy,
        .Draw = ShapesDraw,
    };

    return ECSPanelType_Register(plugin, &panel);
}
