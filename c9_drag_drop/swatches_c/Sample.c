// The sample of the swatches plugin in C: it takes colours dragged from the palette, and marks the pointer while one is over it.

#include "OpenECS.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/// @brief A sample's state.
typedef struct Sample
{
    ECSPanel panel;
    char color[16]; // the colour, such as "#4C566A"
    bool over;      // a colour is dragged over the sample
    f32 pointerX;   // where, in surface pixels
    f32 pointerY;
} Sample;

static SHUResult SampleCreate(ECSPanel panel, const ECSValue *savedState, u32 version, void **retState)
{
    (void)version;

    Sample *sample = calloc(1, sizeof(Sample));

    if (sample == nullptr)
    {
        return SHUResult_ErrAllocation;
    }

    sample->panel = panel;
    const char *color = savedState != nullptr ? ECSValue_GetString(ECSValue_GetTableField(savedState, "color"), "#4C566A") : "#4C566A";
    snprintf(sample->color, sizeof(sample->color), "%s", color);

    // the types the panel takes; panels that take the dragged type are outlined during a drag
    const char *const types[] = {"swatches.color"};
    SHUResult result = ECSPanel_AcceptDrops(panel, types, 1);

    if (result)
    {
        free(sample);
        return result;
    }

    *retState = sample;
    return SHUResult_Ok;
}

static void SampleDestroy(void *state)
{
    free(state);
}

static void SampleDraw(void *state, ECSSurface *surface, f64 seconds)
{
    (void)seconds;

    const Sample *sample = state;
    ECSColor color = 0;
    ECSColor text = 0;
    (void)ECSColor_Parse(sample->color, &color);
    (void)ECSColor_Parse("text", &text);
    ECSSurface_Fill(surface, 0, 0, surface->width, surface->height, color);

    if (sample->over)
    {
        i32 half = (i32)(4.0f * surface->scale);
        ECSSurface_Fill(surface, (i32)sample->pointerX - half, (i32)sample->pointerY - half, 2 * half, 2 * half, text);
    }
}

static void SampleEvent(void *state, const ECSPanelEvent *event)
{
    Sample *sample = state;

    switch (event->type)
    {
    // data of a type the panel takes is over it, at each move; its data is read as a Drop's is
    case ECSPanelEventType_DragOver:
        sample->over = true;
        sample->pointerX = event->drop.x;
        sample->pointerY = event->drop.y;
        ECSPanel_Redraw(sample->panel);
        break;

    // the data left the panel, was dropped or was cancelled
    case ECSPanelEventType_DragLeave:
        sample->over = false;
        ECSPanel_Redraw(sample->panel);
        break;

    case ECSPanelEventType_Drop:
    {
        const char *color = ECSValue_GetString(ECSDropData_GetValue(event->drop.data), nullptr);

        if (strcmp(ECSDropData_GetType(event->drop.data), "swatches.color") == 0 && color != nullptr)
        {
            snprintf(sample->color, sizeof(sample->color), "%s", color);
            ECSPanel_Redraw(sample->panel);
        }
        break;
    }

    default:
        break;
    }
}

static SHUResult SampleSaveState(void *state, ECSValue *retSavedState)
{
    const Sample *sample = state;
    ECSValue *field = nullptr;
    ECSValue_SetTable(retSavedState);
    SHUResult result = ECSValue_SetTableField(retSavedState, "color", &field);
    return result ? result : ECSValue_SetString(field, sample->color);
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    const ECSPanelTypeDesc sample = {
        .name = "sample",
        .title = "Sample in C",
        .stateVersion = 1,
        .Create = SampleCreate,
        .Destroy = SampleDestroy,
        .Draw = SampleDraw,
        .Event = SampleEvent,
        .SaveState = SampleSaveState,
    };

    return ECSPanelType_Register(plugin, &sample);
}
