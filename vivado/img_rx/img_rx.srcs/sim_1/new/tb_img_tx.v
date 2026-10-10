`timescale 1ns / 1ps

module tb_img_tx;

    reg diff_clock_rtl_clk_p = 1'b0;
    reg diff_clock_rtl_clk_n = 1'b1;

    always #4 begin
        diff_clock_rtl_clk_p = ~diff_clock_rtl_clk_p;
        diff_clock_rtl_clk_n = ~diff_clock_rtl_clk_n;
    end

    reg reset_rtl = 1'b0;
    reg [3:0] btns_4bits_tri_i = 4'b0000;
    reg        in_clk_0   = 1'b0;
    reg [7:0]  in_data_0  = 8'h00;
    reg        in_valid_0 = 1'b0;

    wire       in_ready_0;

    always #10 in_clk_0 = ~in_clk_0;


    img_rx_wrapper dut (
        .diff_clock_rtl_clk_n (diff_clock_rtl_clk_n),
        .diff_clock_rtl_clk_p (diff_clock_rtl_clk_p),

        .reset_rtl            (reset_rtl),

        .btns_4bits_tri_i     (btns_4bits_tri_i),

        .in_clk_0             (in_clk_0),
        .in_data_0            (in_data_0),
        .in_valid_0           (in_valid_0),
        .in_ready_0           (in_ready_0)
    );

    localparam integer FRAME_WIDTH  = 320;
    localparam integer FRAME_HEIGHT = 200;

    localparam integer FRAME_BYTES =
        FRAME_WIDTH * FRAME_HEIGHT;       // 64000

    task send_frame;
        integer pixel;
        begin
            $display("[%0t] Starting frame transmission", $time);
            pixel = 0;

            while (pixel < FRAME_BYTES) begin
                @(negedge in_clk_0);

                in_valid_0 = 1'b1;
                in_data_0  = pixel[7:0];

                @(posedge in_clk_0);

                if (in_ready_0) begin
                    pixel = pixel + 1;
                end
            end

            @(negedge in_clk_0);

            in_valid_0 = 1'b0;
            in_data_0  = 8'h00;

            $display("[%0t] Frame transmission finished: %0d bytes", $time, FRAME_BYTES);

        end
    endtask

    initial begin

        reset_rtl        = 1'b0;
        btns_4bits_tri_i = 4'b0000;
        in_valid_0       = 1'b0;
        in_data_0        = 8'h00;

        #500;

        reset_rtl = 1'b1;

        $display("[%0t] Reset released", $time);
        #100_000;


        $display("[%0t] Pressing button", $time);
        btns_4bits_tri_i[0] = 1'b1;


        wait (in_ready_0 === 1'b1);

        $display("[%0t] frame_rx_axis is ready", $time);

        btns_4bits_tri_i[0] = 1'b0;

        send_frame();
        #100_000;

        $display("[%0t] Simulation finished", $time);

        $finish;

    end

    initial begin
        #2_000_000;
        $display(
            "[%0t] ERROR: simulation timeout",
            $time);
        $finish;
    end

endmodule