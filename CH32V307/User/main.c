#include "debug.h"
#include "ch32v30x_usbhs_device.h"
#include "ch32v30x_i2s_device.h"
#include "ch32v30x_spi_device.h"
#include "ch32v30x_led_device.h"

#define PROGRAM_VERSION 1

void hang(const char *str)
{
    printf("Error: %s\r\n", str);

    LED_SetPWM(0);
    Delay_Ms(1000);
    LED_SetPWM(100);
    Delay_Ms(1000);
    LED_SetPWM(0);
    Delay_Ms(1000);
    LED_SetPWM(100);
    Delay_Ms(1000);
    LED_SetPWM(0);
    Delay_Ms(1000);
    LED_SetPWM(100);
    Delay_Ms(1000);
    LED_SetPWM(0);

    while (1)
    {
    }
}

void init()
{
    NVIC_PriorityGroupConfig(NVIC_PriorityGroup_2);
    SystemCoreClockUpdate();
    Delay_Init();
    USART_Printf_Init(9600);
    LED_Device_Init();

    printf("LLT USB Audio To I2S\r\n");
    printf("Firmware version: %d, Datetime: %s-%s\r\n", PROGRAM_VERSION, __DATE__, __TIME__);
    printf("System clk:%d\r\n", SystemCoreClock);
    printf("Chip ID:%08x\r\n", DBGMCU_GetCHIPID());

    // Init SPI
    SPI_Device_Init();

    // Init CPLD
    uint8_t cpld_version;
    if (!CPLD_GetStatus(&cpld_version))
    {
        hang("CPLD initialization failed!");
    }
    printf("CPLD firmware version:%d\r\n", cpld_version);
    printf("==================READY==================\r\n");

    // Init I2S
    I2S_Device_Init();

    // Blink
    LED_SetPWM(0);
    Delay_Ms(100);
    LED_SetPWM(100);
    Delay_Ms(100);
    LED_SetPWM(0);
    Delay_Ms(100);
    LED_SetPWM(100);
    Delay_Ms(100);
    LED_SetPWM(0);
    Delay_Ms(100);
    LED_SetPWM(100);

    // Init USB
    USBHS_RCC_Init();
    USBHS_Device_Init(ENABLE);
}

int main(void)
{
    init();

    uint32_t pwm = 0;
    uint8_t up = 1;
    while (1)
    {
        CPLD_ChangeFormat();
        Delay_Ms(10);
        LED_SetPWM(pwm);
        if (up)
        {
            pwm++;
            if (pwm == 100)
            {
                up = 0;
            }
        }
        else
        {
            pwm--;
            if (pwm == 0)
            {
                up = 1;
            }
        }
    }
}
