
#include "xparameters.h"
#include "xgpio.h"
#include "xil_printf.h"
#include "sleep.h"

XGpio Gpio;

int main()
{
    int Status;
    u32 counter_value;

    xil_printf("\r\n=== P0 AXI GPIO Test ===\r\n");

    Status = XGpio_Initialize(&Gpio, XPAR_AXI_GPIO_0_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        xil_printf("ERROR: AXI GPIO initialization failed\r\n");
        return XST_FAILURE;
    }

    xil_printf("AXI GPIO initialized\r\n");
    xil_printf("Base address: 0x%08X\r\n", XPAR_AXI_GPIO_0_BASEADDR);

    /* Channel 1: output -> Counter CE */
    XGpio_SetDataDirection(&Gpio, 1, 0x00000000);

    /* Channel 2: input <- Counter Q[15:0] */
    XGpio_SetDataDirection(&Gpio, 2, 0x0000FFFF);

    /* Enable counter */
    XGpio_DiscreteWrite(&Gpio, 1, 1);

    xil_printf("Counter enabled\r\n");

    for (int i = 0; i < 10; i++) {
        counter_value = XGpio_DiscreteRead(&Gpio, 2);

        xil_printf("Counter = %lu\r\n", counter_value);

        sleep(1);
    }

    /* Disable counter */
    XGpio_DiscreteWrite(&Gpio, 1, 0);

    xil_printf("Counter disabled\r\n");
    xil_printf("=== Test complete ===\r\n");

    return XST_SUCCESS;
}
