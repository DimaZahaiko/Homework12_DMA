`timescale 1ns / 1ps

module tb_travelling_led;

    // ---- Такт і reset -- ПЕРЕВІРИТИ реальну назву порту такту у
    // вашій обгортці (залежить від джерела такту, обраного при
    // Block Automation) ----
    // ---- Диференційний такт -- ПЕРЕВІРИТИ реальні назви портів
    // (типово diff_clock_rtl_p/diff_clock_rtl_n чи sys_clk_p/sys_clk_n,
    // залежить від того, як саме назвали цей порт при Make External) ----
    reg diff_clock_rtl_0_clk_p = 0;
    wire diff_clock_rtl_0_clk_n = ~diff_clock_rtl_0_clk_p;   // завжди протифазний до clk_p

    reg reset_rtl_0 = 1;   // ПЕРЕВІРИТИ активний рівень (0 чи 1)

    // ---- Зовнішні GPIO-порти -- перевірені раніше через Make External ----
    tri  [3:0] btn_tri_io_bidir;
    reg  [3:0] btn_tri_io;
    assign btn_tri_io_bidir = btn_tri_io;
    tri  [1:0] sw_tri_io_bidir;
    reg  [1:0] sw_tri_io;
    assign sw_tri_io_bidir = sw_tri_io;
    tri  [3:0] led_tri_io_bidir;
    
    // ---- Інстанціювання ПОВНОЇ верхньої обгортки ----
    // ПЕРЕВІРИТИ точний список портів у вашому файлі design_1_wrapper.v
    design_1_wrapper dut (
        .diff_clock_rtl_clk_p (diff_clock_rtl_0_clk_p),   // ПЕРЕВІРИТИ реальну назву
        .diff_clock_rtl_clk_n (diff_clock_rtl_0_clk_n),   // ПЕРЕВІРИТИ реальну назву
        .reset_rtl      (reset_rtl_0),
        .btns_4bits_tri_i  (btn_tri_io_bidir),
        .sws_2bits_tri_i   (sw_tri_io_bidir),
        .leds_4bits_tri_io  (led_tri_io_bidir)
    );   

    // ---- Генерація такту (період залежить від реальної частоти
    // вашого проєкту; тут -- приклад для 100 МГц) ----
    always #5 diff_clock_rtl_0_clk_p = ~diff_clock_rtl_0_clk_p;

    // ---- Стимул: імітуємо реальні натискання кнопок ----
    initial begin
        reset_rtl_0 = 0;
        sw_tri_io  = 2'b00;
        btn_tri_io = 4'b0000;
        #200;
        reset_rtl_0 = 1;

        // Дати MicroBlaze час "прокинутись" і дійти до while(1) --
        // орієнтовний запас, скоригувати за спостереженням у Waveform
        #150000;

        $display("[%0t] Тест 1: btn=0011", $time);
        btn_tri_io = 4'b0100;   //павза
        #10000;
        btn_tri_io = 4'b0000;
        #20000;
        btn_tri_io = 4'b0100;   //відновлення
        #10000;
        btn_tri_io = 4'b0000;
        #20000;
        sw_tri_io = 2'b01;      //зміна напрямку
        #100000;
        btn_tri_io = 4'b0001;   //швидше
        #10000;
        btn_tri_io = 4'b0000;
        #20000;
        btn_tri_io = 4'b0001;   //ще швидше
        #10000;
        btn_tri_io = 4'b0000;
        #20000;
        btn_tri_io = 4'b0010;   //повільніше
        #10000;
        btn_tri_io = 4'b0000;
        #20000;
        
        
        $display("Симуляція завершена -- перевірте лог вище й Waveform Viewer");
        $finish;
    end



endmodule
