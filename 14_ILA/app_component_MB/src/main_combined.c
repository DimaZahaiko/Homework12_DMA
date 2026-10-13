// main.c – бігаючий світлодіод.


#include "xparameters.h"  // адреси переферії FPGA 
#include "xil_io.h"       // низькорівневі функції доступу MMIO
#include "xgpio.h"        // API драйвера AXI GPIO
#include "xtmrctr.h"      // драйвер таймера
#include "xil_printf.h"
#include "xstatus.h"      

#define LED_BASEADDR   XPAR_AXI_GPIO_0_BASEADDR   // адреса LED-ів
#define BTN_BASEADDR   XPAR_AXI_GPIO_1_BASEADDR   // адреса кнопок
#define SW_BASEADDR    XPAR_AXI_GPIO_2_BASEADDR   // адреса перемикач
#define TIMER_BASEADDR XPAR_AXI_TIMER_0_BASEADDR  // адреса таймера
#define TIMER_NUMBER 0                            // номер таймера
#define MAX_SPEED_DIVIDER 10                      // будемо ділити затримку світлодіода на 2, 3, 4...10
XGpio led_gpio, btn_gpio, sw_gpio;  // змінні типу XGpio – структури данних
XTmrCtr timer;

int main() {
    XGpio_Config *cfg_ptr;  // вказівник на структуру конфігурації GPIO 
                            // (cfg_ptr зберігатиме адресу об'єкта XGPIO_Config)
    
    
    cfg_ptr = XGpio_LookupConfig(LED_BASEADDR);  // конфігурація GPIO of LED
    XGpio_CfgInitialize(&led_gpio, cfg_ptr, cfg_ptr->BaseAddress); // ініціалізація led_gpio
                    //  &led_gpio – адреса змінної; 
    cfg_ptr = XGpio_LookupConfig(BTN_BASEADDR);
    XGpio_CfgInitialize(&btn_gpio, cfg_ptr, cfg_ptr->BaseAddress);

    cfg_ptr = XGpio_LookupConfig(SW_BASEADDR);
    XGpio_CfgInitialize(&sw_gpio, cfg_ptr, cfg_ptr->BaseAddress);

    XGpio_SetDataDirection(&led_gpio, 1, 0x0); // перший канал, 4 виходи
    XGpio_SetDataDirection(&btn_gpio, 1, 0xF); // 4 входи
    XGpio_SetDataDirection(&sw_gpio,  1, 0x3); // 2 входи
    
    // +++++++++++++ TIMER +++++++++
    XTmrCtr_Initialize(&timer, TIMER_BASEADDR);

    u32 timer_freq = timer.Config.SysClockFreqHz;
    
    u32 interval_ticks = timer_freq / 100000U; // базова швидкість 100КГц

    XTmrCtr_Reset(&timer, TIMER_NUMBER);
    XTmrCtr_Start(&timer, TIMER_NUMBER);
    
    u32 previous_time = XTmrCtr_GetValue(&timer, TIMER_NUMBER); 
    
    //=========== LEDs ========
    u32 led_value = 0x1;

    XGpio_DiscreteWrite(&led_gpio, 1, led_value);
    
    //===========BUTTONS=======
    u32 prev_btn = 0;
    //----------speed----------
    u32 speed_divider = 1;    //для регулювання швидкості
    //----------pause----------
    int paused = 0;
    xil_printf("FREQUENCY: %d", timer_freq);
    while (1) {
        
        u32 current_time = XTmrCtr_GetValue(&timer, TIMER_NUMBER);

        if(!paused && (u32)(current_time - previous_time) >= interval_ticks / speed_divider){
            previous_time = current_time;

            
            u32 sw_value = XGpio_DiscreteRead(&sw_gpio, 1);
            
            // напрямок
            if((sw_value & 0x1) == 0){
                led_value <<= 1;
            }
            else{
               led_value >>= 1;
            }
            // перехід на інший кінець
            if(led_value > 0x8){
                led_value = 0x1;
            }
            else if(led_value < 0x1){
                led_value = 0x8;
            }

            XGpio_DiscreteWrite(&led_gpio, 1, led_value);
        }

        u32 btn_value = XGpio_DiscreteRead(&btn_gpio, 1);
        
        u32 pressed = btn_value & ~prev_btn; // маска для відстежування зміни кнопки

        prev_btn = btn_value;    // третя кнопка pause/resume
        if (pressed & 0x4){               
            paused = !paused;         
        }
        if ((pressed & 0x1) && !paused){        // перша кнопка збільшує дільник
            if(speed_divider < MAX_SPEED_DIVIDER){
                speed_divider++;    
            } 
        }
        if((pressed & 0x2) && !paused){          // друга кнопка зменшує дільник
            if(speed_divider > 1){
                speed_divider--;    
            } 
        }
        
    }

    return 0;
}