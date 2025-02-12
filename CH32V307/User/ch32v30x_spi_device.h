#ifndef __CH32V30X_SPI_DEVICE_H__
#define __CH32V30X_SPI_DEVICE_H__

#include "debug.h"

void SPI_Device_Init();

#define CPLD_GET_READY(x) ((x >> 7) & 1)

// Inst
#define CPLD_INST_GET_STATUS 0x20
#define CPLD_INST_SET_FORMAT 0x40
#define CPLD_INST_GET_FORMAT 0x60

#define CPLD_FORMAT_2 0x01
#define CPLD_FORMAT_1 0x02
#define CPLD_FORMAT_D2 0x03
#define CPLD_FORMAT_D4 0x04
#define CPLD_FORMAT_SUB_1 0x05
#define CPLD_FORMAT_SUB_D2 0x06
#define CPLD_FORMAT_SUB_D4 0x07

uint8_t CPLD_GetStatus(uint8_t *version);
uint8_t CPLD_SetFormat(uint8_t format);
uint8_t CPLD_GetFormat(uint8_t *format);

void CPLD_ChangeFormat();
void CPLD_RequestFormat();

#endif
