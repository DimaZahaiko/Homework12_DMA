#include "xparameters.h"
#include "xgpio.h"
#include "xaxidma.h"
#include "xstatus.h"
#include "xil_types.h"


#define GPIO_BASEADDR XPAR_AXI_GPIO_0_BASEADDR
#define DMA_BASEADDR XPAR_AXI_DMA_0_BASEADDR
#define RAM_BASE XPAR_AXI4_FULL_RAM_0_BASEADDR

#define BUTTON_CHANNEL      1
#define START_CHANNEL       2

#define FRAME_WIDTH         320U
#define FRAME_HEIGHT        200U

#define FRAME_BYTES         (FRAME_WIDTH * FRAME_HEIGHT)

static XGpio   gpio;
static XAxiDma dma;

int main(void)
{
    XGpio_Config   *gpio_cfg;
    XAxiDma_Config *dma_cfg;

    u32 button;
    u32 prev_button = 0;
    u32 pressed;

    gpio_cfg = XGpio_LookupConfig(GPIO_BASEADDR);
    
    XGpio_CfgInitialize(&gpio, gpio_cfg, gpio_cfg->BaseAddress);

    XGpio_SetDataDirection(&gpio, BUTTON_CHANNEL, 1);

    XGpio_SetDataDirection(&gpio, START_CHANNEL, 0);

    XGpio_DiscreteWrite(&gpio, START_CHANNEL, 0);

    dma_cfg = XAxiDma_LookupConfig(DMA_BASEADDR);

    XAxiDma_CfgInitialize(&dma, dma_cfg);

    XAxiDma_IntrDisable(&dma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);


    while (1)
    {
        button = XGpio_DiscreteRead(&gpio, BUTTON_CHANNEL);
        pressed = button & ~prev_button;

        prev_button = button;
        if (pressed)
        {
            XAxiDma_SimpleTransfer(&dma, 
                (UINTPTR)RAM_BASE, 
                FRAME_BYTES, 
                XAXIDMA_DEVICE_TO_DMA);
            
            XGpio_DiscreteWrite(&gpio, START_CHANNEL, 1);

            while (XAxiDma_Busy(&dma, XAXIDMA_DEVICE_TO_DMA));

            XGpio_DiscreteWrite(&gpio, START_CHANNEL, 0);
            
            do {
                button = XGpio_DiscreteRead(&gpio,BUTTON_CHANNEL);
            }
            while (button);

            prev_button = 0;
        }
    }

    return 0;
}