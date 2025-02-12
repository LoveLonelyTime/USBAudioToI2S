#include "ch32v30x_i2s_device.h"
#include "ch32v30x_tim.h"
#include "string.h"

uint32_t feedback = 48 << 16;
uint32_t audio_bits = 32;
uint8_t audio_buffer[512];
// uint32_t buffer_addr = 0;
// uint32_t buffer_num = 0;

void Audio_ResetFeedback(uint32_t freq)
{
    switch (freq)
    {
    case 384000U:
        feedback = 48 << 16;
        break;
    case 192000U:
        feedback = 24 << 16;
        break;
    case 96000U:
        feedback = 12 << 16;
        break;
    case 48000U:
        feedback = 6 << 16;
        break;
    case 176400U:
        feedback = 0x160CCD; // 1445068.8
        break;
    case 88200U:
        feedback = 0xB0666; // 722534.4
        break;
    case 44100U:
        feedback = 0x58333; // 361267.2
        break;
    default:
        feedback = 48 << 16;
    }
}

uint32_t Audio_GetFeedback()
{
    return feedback;
}

uint16_t Audio_CountFull()
{ // A12
    static uint16_t last;
    uint16_t curr = TIM_GetCounter(TIM1);
    uint16_t diff = curr - last;
    last = curr;
    return diff;
}

uint16_t Audio_CountEmpty()
{ // A0
    static uint16_t last;
    uint16_t curr = TIM_GetCounter(TIM8);
    uint16_t diff = curr - last;
    last = curr;
    return diff;
}

void Audio_Sync(uint8_t frame)
{
    //    uint16_t full_cnt = Audio_full_cnt();
    //    uint16_t empty_cnt = Audio_empty_cnt();
    //    if (buffer_addr != 0) {
    //        DMA_Cmd( DMA2_Channel2, DISABLE);
    //        DMA2_Channel2->CNTR = buffer_num / 2; // Data = 16Bits
    //        DMA2_Channel2->MADDR = (uint32_t) buffer_addr;
    //        DMA_Cmd( DMA2_Channel2, ENABLE);
    //        buffer_addr = 0;
    //
    //        if (full_cnt > empty_cnt) {
    //            feedback -= 1;
    //        } else if (full_cnt < empty_cnt) {
    //            feedback += 1;
    //        }
    //    }
}

void Audio_FillBuffer(uint8_t *src, uint32_t num)
{
    //    buffer_addr = (uint32_t) src;
    //    buffer_num = num;

    uint16_t full_cnt = Audio_CountFull();
    uint16_t empty_cnt = Audio_CountEmpty();
    uint32_t samples = 0;

    // Feedback
    if (full_cnt > empty_cnt)
    {
        feedback -= 1;
    }
    else if (full_cnt < empty_cnt)
    {
        feedback += 1;
    }

    if (audio_bits == 32)
    {
        samples = num / 8;
        for (int i = 0; i < samples; i++)
        {
            audio_buffer[i * 8] = src[i * 8];
            audio_buffer[i * 8 + 1] = src[i * 8 + 1];
            audio_buffer[i * 8 + 2] = src[i * 8 + 2];
            audio_buffer[i * 8 + 3] = src[i * 8 + 3];
            audio_buffer[i * 8 + 4] = src[i * 8 + 4];
            audio_buffer[i * 8 + 5] = src[i * 8 + 5];
            audio_buffer[i * 8 + 6] = src[i * 8 + 6];
            audio_buffer[i * 8 + 7] = src[i * 8 + 7];
        }
    }
    else if (audio_bits == 24)
    {
        samples = num / 6;
        for (int i = 0; i < samples; i++)
        {
            audio_buffer[i * 8] = 0;
            audio_buffer[i * 8 + 1] = src[i * 6];
            audio_buffer[i * 8 + 2] = src[i * 6 + 1];
            audio_buffer[i * 8 + 3] = src[i * 6 + 2];
            audio_buffer[i * 8 + 4] = 0;
            audio_buffer[i * 8 + 5] = src[i * 6 + 3];
            audio_buffer[i * 8 + 6] = src[i * 6 + 4];
            audio_buffer[i * 8 + 7] = src[i * 6 + 5];
        }
    }
    else if (audio_bits == 16)
    {
        samples = num / 4;
        for (int i = 0; i < samples; i++)
        {
            audio_buffer[i * 8] = 0;
            audio_buffer[i * 8 + 1] = 0;
            audio_buffer[i * 8 + 2] = src[i * 4];
            audio_buffer[i * 8 + 3] = src[i * 4 + 1];
            audio_buffer[i * 8 + 4] = 0;
            audio_buffer[i * 8 + 5] = 0;
            audio_buffer[i * 8 + 6] = src[i * 4 + 2];
            audio_buffer[i * 8 + 7] = src[i * 4 + 3];
        }
    }

    DMA_Cmd(DMA1_Channel5, DISABLE);
    DMA1_Channel5->CNTR = samples * 4; // Data = 16Bits
    DMA1_Channel5->MADDR = (uint32_t)audio_buffer;
    DMA_Cmd(DMA1_Channel5, ENABLE);
}

void Audio_SetBits(uint32_t bits)
{
    audio_bits = bits;
}

void Audio_SetUnmute(BitAction unmute)
{
    GPIO_WriteBit(GPIOA, GPIO_Pin_2, unmute);
}

void I2S_Device_Init()
{
    GPIO_InitTypeDef GPIO_InitStructure = {0};
    I2S_InitTypeDef I2S_InitStructure = {0};
    DMA_InitTypeDef DMA_InitStructure = {0};

    RCC_I2S2CLKConfig(RCC_I2S2CLKSource_SYSCLK); // 144MHz
    RCC_APB1PeriphClockCmd(RCC_APB1Periph_SPI2, ENABLE);
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOB | RCC_APB2Periph_GPIOC, ENABLE);

    SPI_I2S_DeInit(SPI2);

    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_12 | GPIO_Pin_13 | GPIO_Pin_15; // WS CK SD
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOB, &GPIO_InitStructure);

    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_2; // MUTE
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOA, &GPIO_InitStructure);

    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0 | GPIO_Pin_12; // TIM8 TIM1
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPD;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOA, &GPIO_InitStructure);

    I2S_InitStructure.I2S_Mode = I2S_Mode_MasterTx;
    I2S_InitStructure.I2S_Standard = I2S_Standard_Phillips;
    I2S_InitStructure.I2S_DataFormat = I2S_DataFormat_32b;
    I2S_InitStructure.I2S_MCLKOutput = I2S_MCLKOutput_Disable;
    I2S_InitStructure.I2S_AudioFreq = 430000;
    I2S_InitStructure.I2S_CPOL = I2S_CPOL_Low;
    I2S_Init(SPI2, &I2S_InitStructure);
    I2S_Cmd(SPI2, ENABLE);

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM1 | RCC_APB2Periph_TIM8, ENABLE);

    TIM_CounterModeConfig(TIM1, TIM_CounterMode_Up);
    TIM_ARRPreloadConfig(TIM1, DISABLE);
    TIM_ETRClockMode2Config(TIM1, TIM_ExtTRGPSC_OFF, TIM_ExtTRGPolarity_NonInverted, 0x0);

    TIM_CounterModeConfig(TIM8, TIM_CounterMode_Up);
    TIM_ARRPreloadConfig(TIM8, DISABLE);
    TIM_ETRClockMode2Config(TIM8, TIM_ExtTRGPSC_OFF, TIM_ExtTRGPolarity_NonInverted, 0x0);

    TIM_Cmd(TIM1, ENABLE);
    TIM_Cmd(TIM8, ENABLE);

    RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1, ENABLE);

    DMA_DeInit(DMA1_Channel5);

    DMA_InitStructure.DMA_PeripheralBaseAddr = (u32)&SPI2->DATAR;
    DMA_InitStructure.DMA_MemoryBaseAddr = 0;
    DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralDST;
    DMA_InitStructure.DMA_BufferSize = 0;
    DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
    DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
    DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord;
    DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;
    DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;
    DMA_InitStructure.DMA_Priority = DMA_Priority_VeryHigh;
    DMA_InitStructure.DMA_M2M = DMA_M2M_Disable;
    DMA_Init(DMA1_Channel5, &DMA_InitStructure);

    DMA_Cmd(DMA1_Channel5, ENABLE);
    SPI_I2S_DMACmd(SPI2, SPI_I2S_DMAReq_Tx, ENABLE);

    // Unmute
    GPIO_WriteBit(GPIOA, GPIO_Pin_2, Bit_SET);
}
