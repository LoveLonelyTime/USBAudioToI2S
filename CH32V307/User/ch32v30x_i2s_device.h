#ifndef __CH32V30X_I2S_DEVICE_H__
#define __CH32V30X_I2S_DEVICE_H__

#include "debug.h"

void I2S_Device_Init();

void Audio_Sync(uint8_t frame);
void Audio_FillBuffer(uint8_t *src, uint32_t num);

void Audio_SetBits(uint32_t bits);
void Audio_ResetFeedback(uint32_t freq);
uint32_t Audio_GetFeedback();

void Audio_SetUnmute(BitAction unmute);
#endif
