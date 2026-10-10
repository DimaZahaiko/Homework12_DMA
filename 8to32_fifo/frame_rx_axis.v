module frame_rx_axis #(
    parameter integer FRAME_BYTES = 64000,
    parameter integer FIFO_DEPTH  = 1024
)(
    // External input clock domain
    input  wire        in_clk,
    input  wire [7:0]  in_data,
    input  wire        in_valid,
    output wire        in_ready,

    // Start from MicroBlaze / AXI GPIO
    input  wire        start,

    // AXI4-Stream clock domain
    input  wire        m_axis_aclk,
    input  wire        m_axis_aresetn,

    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [3:0]  m_axis_tkeep,
    output reg         m_axis_tlast
);

    localparam integer FRAME_WORDS = FRAME_BYTES / 4;

    // ============================================================
    // Synchronise START to external clock domain
    // ============================================================

    reg [1:0] start_sync;
    reg       start_sync_d;

    reg       input_active;
    reg [15:0] byte_count;
    
    wire fifo_wr_en;

    always @(posedge in_clk or negedge m_axis_aresetn) begin
        if (!m_axis_aresetn) begin
            start_sync   <= 2'b00;
            start_sync_d <= 1'b0;
            input_active <= 1'b0;
            byte_count   <= 16'd0;
        end
        else begin

            start_sync   <= {start_sync[0], start};
            start_sync_d <= start_sync[1];

            // Rising edge of start
            if (start_sync[1] && !start_sync_d) begin
                input_active <= 1'b1;
                byte_count   <= 16'd0;
            end

            else if (fifo_wr_en) begin

                if (byte_count == FRAME_BYTES - 1) begin
                    input_active <= 1'b0;
                end
                else begin
                    byte_count <= byte_count + 1'b1;
                end
            end
        end
    end


    // ============================================================
    // Async FIFO: 8-bit input
    // ============================================================

    wire [7:0] fifo_dout;
    wire       fifo_full;
    wire       fifo_empty;

    
    wire fifo_rd_en;

    assign in_ready   = input_active && !fifo_full;
    assign fifo_wr_en = in_valid && in_ready;


    xpm_fifo_async #(
        .FIFO_MEMORY_TYPE   ("auto"),
        .FIFO_WRITE_DEPTH   (FIFO_DEPTH),

        .WRITE_DATA_WIDTH   (8),
        .READ_DATA_WIDTH    (8),

        .READ_MODE          ("fwft"),
        .FIFO_READ_LATENCY  (0),

        .CDC_SYNC_STAGES    (2),
        .USE_ADV_FEATURES   ("0000")
    )
    fifo_inst (
        .rst        (~m_axis_aresetn),

        .wr_clk     (in_clk),
        .wr_en      (fifo_wr_en),
        .din        (in_data),
        .full       (fifo_full),

        .rd_clk     (m_axis_aclk),
        .rd_en      (fifo_rd_en),
        .dout       (fifo_dout),
        .empty      (fifo_empty),

        .sleep      (1'b0),
        .injectsbiterr(1'b0),
        .injectdbiterr(1'b0)
    );


    // ============================================================
    // 8 bit -> 32 bit packer + AXI4 Stream
    // ============================================================

    reg [31:0] pack_reg;
    reg [1:0]  byte_index;

    reg [13:0] word_count;

    reg start_d;
    reg stream_active;


    assign m_axis_tkeep = 4'b1111;

    assign fifo_rd_en =
        stream_active &&
        !m_axis_tvalid &&
        !fifo_empty;


    always @(posedge m_axis_aclk) begin

        if (!m_axis_aresetn) begin

            pack_reg       <= 32'd0;
            byte_index     <= 2'd0;

            word_count     <= 14'd0;

            m_axis_tdata   <= 32'd0;
            m_axis_tvalid  <= 1'b0;
            m_axis_tlast   <= 1'b0;

            start_d        <= 1'b0;
            stream_active  <= 1'b0;
        end

        else begin

            start_d <= start;

            // New frame
            if (start && !start_d) begin

                word_count     <= 14'd0;
                byte_index     <= 2'd0;

                m_axis_tvalid  <= 1'b0;
                m_axis_tlast   <= 1'b0;

                stream_active  <= 1'b1;
            end


            // Current AXI word accepted by DMA
            else if (m_axis_tvalid && m_axis_tready) begin

                m_axis_tvalid <= 1'b0;

                if (m_axis_tlast) begin
                    m_axis_tlast  <= 1'b0;
                    stream_active <= 1'b0;
                end
            end


            // Take next byte from FIFO
            if (fifo_rd_en) begin

                case (byte_index)

                    2'd0: begin
                        pack_reg[7:0] <= fifo_dout;
                        byte_index <= 2'd1;
                    end

                    2'd1: begin
                        pack_reg[15:8] <= fifo_dout;
                        byte_index <= 2'd2;
                    end

                    2'd2: begin
                        pack_reg[23:16] <= fifo_dout;
                        byte_index <= 2'd3;
                    end

                    2'd3: begin

                        m_axis_tdata <= {
                            fifo_dout,
                            pack_reg[23:0]
                        };

                        m_axis_tvalid <= 1'b1;

                        if (word_count == FRAME_WORDS - 1)
                            m_axis_tlast <= 1'b1;

                        word_count <= word_count + 1'b1;

                        byte_index <= 2'd0;
                    end

                endcase
            end
        end
    end

endmodule