#include "ch32v30x_spi.h"
#include "ch32v30x_spi_device.h"

uint8_t pending_format = 0;

uint8_t SPI_SendData(uint8_t data)
{
    uint8_t res = 0;
    GPIO_WriteBit(GPIOA, GPIO_Pin_5, Bit_RESET);

    GPIO_WriteBit(GPIOA, GPIO_Pin_4, Bit_RESET);
    Delay_Us(100);
    for (int i = 7; i >= 0; i--)
    {
        GPIO_WriteBit(GPIOA, GPIO_Pin_7, (data >> i) & 1);
        Delay_Us(100);
        GPIO_WriteBit(GPIOA, GPIO_Pin_5, Bit_SET);
        Delay_Us(50);
        res = (res << 1) | GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_6);
        Delay_Us(100);
        GPIO_WriteBit(GPIOA, GPIO_Pin_5, Bit_RESET);
    }
    Delay_Us(100);
    GPIO_WriteBit(GPIOA, GPIO_Pin_4, Bit_SET);
    Delay_Us(100);

    return res;
}

uint8_t CPLD_GetStatus(uint8_t *version)
{
    SPI_SendData(CPLD_INST_GET_STATUS);
    uint8_t data = SPI_SendData(0);
    *version = data & 0x7F;
    return CPLD_GET_READY(data);
}

uint8_t CPLD_SetFormat(uint8_t format)
{
    SPI_SendData(CPLD_INST_SET_FORMAT | format);
    return CPLD_GET_READY(SPI_SendData(0));
}

uint8_t CPLD_GetFormat(uint8_t *format)
{
    SPI_SendData(CPLD_INST_GET_FORMAT);
    uint8_t data = SPI_SendData(0);
    *format = data & 0x07;
    return CPLD_GET_READY(SPI_SendData(0));
}

void CPLD_RequestFormat(uint32_t freq)
{
    switch (freq)
    {
    case 384000U:
        pending_format = CPLD_FORMAT_2;
        break;
    case 192000U:
        pending_format = CPLD_FORMAT_1;
        break;
    case 96000U:
        pending_format = CPLD_FORMAT_D2;
        break;
    case 48000U:
        pending_format = CPLD_FORMAT_D4;
        break;
    case 176400U:
        pending_format = CPLD_FORMAT_SUB_1;
        break;
    case 88200U:
        pending_format = CPLD_FORMAT_SUB_D2;
        break;
    case 44100U:
        pending_format = CPLD_FORMAT_SUB_D4;
        break;
    default:
        pending_format = 0;
    }
}

void CPLD_ChangeFormat()
{
    if (pending_format)
    {
        if (CPLD_SetFormat(pending_format))
        {
            pending_format = 0;
        }
    }
}

void SPI_Device_Init()
{
    GPIO_InitTypeDef GPIO_InitStructure = {0};

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);

    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_5; // SCK
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOA, &GPIO_InitStructure);

    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6; // MISO
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOA, &GPIO_InitStructure);

    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_7; // MOSI
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOA, &GPIO_InitStructure);

    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4; // NSS
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOA, &GPIO_InitStructure);

    GPIO_WriteBit(GPIOA, GPIO_Pin_4, Bit_SET);
}
