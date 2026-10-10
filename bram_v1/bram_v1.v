module axi4_full_ram #(
    parameter integer DATA_WIDTH = 32,
    parameter integer ADDR_WIDTH = 16,
    parameter integer MEM_DEPTH  = 16384
)(
    input  wire                     s_axi_aclk,
    input  wire                     s_axi_aresetn,

    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [7:0]               s_axi_awlen,
    input  wire [2:0]               s_axi_awsize,
    input  wire [1:0]               s_axi_awburst,
    input  wire                     s_axi_awvalid,
    output wire                     s_axi_awready,

    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                     s_axi_wlast,
    input  wire                     s_axi_wvalid,
    output wire                     s_axi_wready,


    output reg  [1:0]               s_axi_bresp,
    output reg                      s_axi_bvalid,
    input  wire                     s_axi_bready,


    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [7:0]               s_axi_arlen,
    input  wire [2:0]               s_axi_arsize,
    input  wire [1:0]               s_axi_arburst,
    input  wire                     s_axi_arvalid,
    output wire                     s_axi_arready,

    output reg  [DATA_WIDTH-1:0]    s_axi_rdata,
    output reg  [1:0]               s_axi_rresp,
    output reg                      s_axi_rlast,
    output reg                      s_axi_rvalid,
    input  wire                     s_axi_rready
);
    // використовую бокову пам'ять
    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];


    // -----------  write state machine -----------

    localparam [1:0]
        WR_IDLE = 2'd0,
        WR_DATA = 2'd1,
        WR_RESP = 2'd2;

    reg [1:0] wr_state;

    reg [ADDR_WIDTH-1:0] wr_addr;
    reg [7:0]            wr_count;
    reg [2:0]            wr_size;
    reg [1:0]            wr_burst;

    assign s_axi_awready = (wr_state == WR_IDLE);
    assign s_axi_wready  = (wr_state == WR_DATA);

    // AXI write handshake
    wire mem_we;

    assign mem_we =
        s_axi_wvalid &&
        s_axi_wready;

    integer byte_index;

    always @(posedge s_axi_aclk) begin

        if (mem_we) begin

            for (byte_index = 0;
                 byte_index < DATA_WIDTH/8;
                 byte_index = byte_index + 1) begin

                if (s_axi_wstrb[byte_index]) begin

                    mem[wr_addr[ADDR_WIDTH-1:2]]
                        [byte_index*8 +: 8]
                    <=
                    s_axi_wdata
                        [byte_index*8 +: 8];

                end
            end
        end
    end

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin

        if (!s_axi_aresetn) begin

            wr_state     <= WR_IDLE;

            wr_addr      <= {ADDR_WIDTH{1'b0}};
            wr_count     <= 8'd0;
            wr_size      <= 3'd0;
            wr_burst     <= 2'd0;

            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;

        end

        else begin

            case (wr_state)
            
                // чекаємо на адресу
                WR_IDLE: begin

                    s_axi_bvalid <= 1'b0;

                    if (s_axi_awvalid && s_axi_awready) begin

                        wr_addr  <= s_axi_awaddr;
                        wr_count <= s_axi_awlen;
                        wr_size  <= s_axi_awsize;
                        wr_burst <= s_axi_awburst;

                        wr_state <= WR_DATA;
                    end
                end

                // інкрементуємо адресу
                WR_DATA: begin

                    if (s_axi_wvalid && s_axi_wready) begin

                        if (wr_count == 0) 
                            wr_state <= WR_RESP;
                        else begin
                            wr_count <= wr_count - 1'b1;

                            if (wr_burst == 2'b01) begin  // якщо барст типу increment
                                wr_addr <= wr_addr +
                                    ({{(ADDR_WIDTH-1){1'b0}},1'b1} << wr_size);
                            end
                        end
                    end
                end

                // пишемо відповідь
                WR_RESP: begin

                    s_axi_bvalid <= 1'b1;
                    s_axi_bresp  <= 2'b00;

                    if (s_axi_bvalid &&
                        s_axi_bready) begin

                        s_axi_bvalid <= 1'b0;
                        wr_state     <= WR_IDLE;

                    end
                end

                default:
                    wr_state <= WR_IDLE;

            endcase
        end
    end

    // ---------- read state machine ----------- 
    localparam [1:0]
        RD_IDLE  = 2'd0,
        RD_FETCH = 2'd1,
        RD_SEND  = 2'd2;

    reg [1:0] rd_state;

    reg [ADDR_WIDTH-1:0] rd_addr;
    reg [7:0]            rd_count;
    reg [2:0]            rd_size;
    reg [1:0]            rd_burst;

    reg [DATA_WIDTH-1:0] mem_rdata;


    assign s_axi_arready = (rd_state == RD_IDLE);

    wire mem_re;
    assign mem_re = (rd_state == RD_FETCH);

    always @(posedge s_axi_aclk) begin
        if (mem_re) begin
            mem_rdata <= mem[rd_addr[ADDR_WIDTH-1:2]];
        end
    end

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin

        if (!s_axi_aresetn) begin

            rd_state     <= RD_IDLE;

            rd_addr      <= {ADDR_WIDTH{1'b0}};
            rd_count     <= 8'd0;
            rd_size      <= 3'd0;
            rd_burst     <= 2'd0;

            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
            s_axi_rresp  <= 2'b00;
            s_axi_rvalid <= 1'b0;
            s_axi_rlast  <= 1'b0;

        end

        else begin

            case (rd_state)

                // чекаємо на адресу для читання

                RD_IDLE: begin

                    s_axi_rvalid <= 1'b0;
                    s_axi_rlast  <= 1'b0;

                    if (s_axi_arvalid &&
                        s_axi_arready) begin

                        rd_addr  <= s_axi_araddr;
                        rd_count <= s_axi_arlen;
                        rd_size  <= s_axi_arsize;
                        rd_burst <= s_axi_arburst;

                        rd_state <= RD_FETCH;
                    end
                end

                // чекаємо один клок для синхронного зчитування

                RD_FETCH:
                    rd_state <= RD_SEND;

                // надсилаємо дані
                RD_SEND: begin

                    if (!s_axi_rvalid) begin

                        s_axi_rdata  <= mem_rdata;
                        s_axi_rresp  <= 2'b00;
                        s_axi_rvalid <= 1'b1;

                        if (rd_count == 0)
                            s_axi_rlast <= 1'b1;
                        else
                            s_axi_rlast <= 1'b0;

                    end

                    else if (s_axi_rvalid &&
                             s_axi_rready) begin

                        s_axi_rvalid <= 1'b0;

                        if (rd_count == 0) begin

                            s_axi_rlast <= 1'b0;
                            rd_state    <= RD_IDLE;

                        end

                        else begin

                            rd_count <= rd_count - 1'b1;

                            if (rd_burst == 2'b01) begin
                                rd_addr <=
                                    rd_addr +
                                    ({{(ADDR_WIDTH-1){1'b0}},1'b1}
                                     << rd_size);
                            end

                            rd_state <= RD_FETCH;
                        end
                    end
                end

                default:
                    rd_state <= RD_IDLE;

            endcase
        end
    end

endmodule