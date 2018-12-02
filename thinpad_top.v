`default_nettype none
module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到"ON"时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //CPLD串口控制器信号
    output wire uart_rdn,         //读串口信号，低有效
    output wire uart_wrn,         //写串口信号，低有效
    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //USB 控制器信号，参考 SL811 芯片手册
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB数据线与网络控制器的dm9k_sd[7:0]共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //网络控制器信号，参考 DM9000A 芯片手册
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);

wire[7:0] dpys;
SEG7_LUT lut0(dpy0, dpys[3:0]);
SEG7_LUT lut1(dpy1, dpys[7:4]);

wire clk_10M, clk_20M, clk_locked, clk, rst;

pll_example pll
(
    // Clock out ports
    .clk_out1(clk_10M),     // output clk_out1
    .clk_out2(clk_20M),     // output clk_out2
    .locked(clk_locked),
    // Clock in ports
    .clk_in1(clk_50M)       // input clk_in1
);

assign clk = clk_locked & clk_10M;
assign rst = ~reset_btn;

// MMU 信号
wire mmu_read_wire, mmu_write_wire;
wire[31:0] mmu_addr_wire, mmu_out_data, mmu_in_data;
reg [31:0] mmu_addr; // MMU地址/数据

// 反向传递信号
wire ex_ifid_bubble, ex_idex_bubble, ex_if_ifpcjump;
wire ex_ex_i_delayslot;
wire[2:0] ex_ex_i_bubblecnt         , ex_ex_i_stopcnt         ;
reg [2:0] ex_ex_o_bubblecnt = 3'b000, ex_ex_o_stopcnt = 3'b011; // stop the inital commands
wire[31:0] ex_if_pcjumpto;

// 旁路信号
wire ex_id_f_ifregwrite;
wire id_ifregwrite;
wire[4:0] id_regwrite;
wire[31:0] id_regdata;

// IF/ID 信号
wire[31:0] if_id_i_ins, if_id_i_npc;
reg[31:0]  if_id_o_ins, if_id_o_npc;
// IM 信号
wire[31:0] if_imdata, if_imaddr;

IF if_instance(
    // input
    .clk(clk),
    .rst(rst),
    .jpc(ex_if_pcjumpto),
    .if_pc_jump(ex_if_ifpcjump),
    .if_bubble(ex_ifid_bubble),
    .im_data(if_imdata),
    
    // output
    .im_addr(if_imaddr),
    
    .npc(if_id_i_npc),
    .ins(if_id_i_ins)
);

// IF/ID registers
always@(posedge clk) begin
    if (!ex_ifid_bubble) begin
        if_id_o_npc <= if_id_i_npc;
        if_id_o_ins <= if_id_i_ins;
    end
end

// ID/EX 信号
wire id_ex_i_ifregwrite    , id_ex_i_ifmemread    , id_ex_i_ifmemwrite    ;
reg  id_ex_o_ifregwrite = 0, id_ex_o_ifmemread = 0, id_ex_o_ifmemwrite = 0;
wire[5:0] id_ex_i_op, id_ex_i_func;
reg [5:0] id_ex_o_op, id_ex_o_func;
wire[4:0] id_ex_i_regwrite;
reg [4:0] id_ex_o_regwrite;
wire[25:0] id_ex_i_jpc;
reg [25:0] id_ex_o_jpc;
wire[31:0] id_ex_i_data1, id_ex_i_data2, id_ex_i_data2imm, id_ex_i_npc;
reg [31:0] id_ex_o_data1, id_ex_o_data2, id_ex_o_data2imm, id_ex_o_npc;

ID id_instance(
    // input
    .clk(clk),
    .rst(rst),
    
    .ins(if_id_o_ins),
    .reg_write(id_ifregwrite),
    .write_reg(id_regwrite),
    .write_data(id_regdata),
    
    .npc_i(if_id_o_npc),
    
    // output
    .if_reg_write(id_ex_i_ifregwrite),
    .if_mem_read(id_ex_i_ifmemread),
    .if_mem_write(id_ex_i_ifmemwrite),
    .op(id_ex_i_op),
    .func(id_ex_i_func),
    .data_a(id_ex_i_data1),
    .data_b(id_ex_i_data2),
    .data_write_reg(id_ex_i_regwrite),
    .imm(id_ex_i_data2imm),
    .jpc(id_ex_i_jpc),
    .npc_o(id_ex_i_npc)
);

reg id_ex_exstop = 1'b1;
assign ex_idex_bubble = (ex_ex_i_bubblecnt != 0);
assign ex_ifid_bubble = (ex_ex_i_bubblecnt != 0);

// ID/EX registers
always@(posedge clk or negedge rst) begin
    if (!rst) begin
        id_ex_exstop <= 1'b1;
        id_ex_o_ifregwrite <= 0;
        id_ex_o_ifmemread <= 0;
        id_ex_o_ifmemwrite <= 0;
        ex_ex_o_bubblecnt <= 3'b000;
        ex_ex_o_stopcnt <= 3'b011;
    end
    else begin
        ex_ex_o_bubblecnt <= ex_ex_i_bubblecnt;
        ex_ex_o_stopcnt <= ex_ex_i_stopcnt;
    
        if (!ex_idex_bubble) begin
            id_ex_exstop <= (~ex_ex_i_delayslot) & (ex_ex_i_stopcnt != 0);
            id_ex_o_npc <= id_ex_i_npc;
            id_ex_o_ifregwrite <= id_ex_i_ifregwrite;
            id_ex_o_ifmemread <= id_ex_i_ifmemread;
            id_ex_o_ifmemwrite <= id_ex_i_ifmemwrite;
            id_ex_o_op <= id_ex_i_op;
            id_ex_o_func <= id_ex_i_func;
            id_ex_o_regwrite <= id_ex_i_regwrite;
            id_ex_o_data1 <= id_ex_i_data1;
            id_ex_o_data2 <= id_ex_i_data2;
            id_ex_o_data2imm <= id_ex_i_data2imm;
            id_ex_o_jpc <= id_ex_i_jpc;
        end
        else begin
            id_ex_exstop <= 1'b1;
        end
    end
end

// EX/MEM 信号
wire ex_mem_i_ifregwrite    , ex_mem_i_ifmemread    , ex_mem_i_ifmemwrite    , ex_mem_i_loadbyte;
reg  ex_mem_o_ifregwrite = 0, ex_mem_o_ifmemread = 0, ex_mem_o_ifmemwrite = 0, ex_mem_o_loadbyte;
wire[4:0] ex_mem_i_regwrite;
reg [4:0] ex_mem_o_regwrite;
wire[31:0] ex_mem_i_res, ex_mem_i_memwrite;
reg [31:0] ex_mem_o_res, ex_mem_o_memwrite;
/*
wire ex_if_s_ifpcjump;
wire[31:0] ex_if_s_pcjumpto;
*/

EX ex_instance(
    // input
    .op(id_ex_o_op),
    .func(id_ex_o_func),
    .ex_stop(id_ex_exstop),
    .data_a(id_ex_o_data1),
    .data_b(id_ex_o_data2),
    .imm(id_ex_o_data2imm),
    .jpc(id_ex_o_jpc),
    .npc(id_ex_o_npc),
    
    .if_reg_write_i(id_ex_o_ifregwrite),
    .if_mem_read_i(id_ex_o_ifmemread),
    .if_mem_write_i(id_ex_o_ifmemwrite),
    .data_write_reg_i(id_ex_o_regwrite),
    
    // foobar
    .bubble_cnt_last(ex_ex_o_bubblecnt),
    .ex_stopcnt_last(ex_ex_o_stopcnt),
    .bubble_cnt(ex_ex_i_bubblecnt),
    .ex_stopcnt(ex_ex_i_stopcnt),
    .delay_slot(ex_ex_i_delayslot),
        
    // output
    .result(ex_mem_i_res),
    .mem_data(ex_mem_i_memwrite),
    .if_pc_jump(ex_if_ifpcjump),
    .pc_jumpto(ex_if_pcjumpto),
    .load_byte(ex_mem_i_loadbyte),
    
    .if_reg_write_o(ex_mem_i_ifregwrite),
    .if_mem_read_o(ex_mem_i_ifmemread),
    .if_mem_write_o(ex_mem_i_ifmemwrite),
    
    .if_forward_reg_write(ex_id_f_ifregwrite),
    
    .data_write_reg_o(ex_mem_i_regwrite)
);

// EX/MEM registers
always@(posedge clk or negedge rst) begin
    if (!rst) begin
        ex_mem_o_ifregwrite <= 0;
        ex_mem_o_ifmemread <= 0;
        ex_mem_o_ifmemwrite <= 0;
    end
    else begin
        ex_mem_o_ifregwrite <= ex_mem_i_ifregwrite;
        ex_mem_o_ifmemread <= ex_mem_i_ifmemread;
        ex_mem_o_ifmemwrite <= ex_mem_i_ifmemwrite;
        ex_mem_o_regwrite <= ex_mem_i_regwrite;
        ex_mem_o_res <= ex_mem_i_res;
        ex_mem_o_loadbyte <= ex_mem_i_loadbyte;
        ex_mem_o_memwrite <= ex_mem_i_memwrite;
    end
end

// MEM/WB 信号
wire mem_wb_i_ifregwrite, mem_wb_i_ifmemread;
wire[4:0] mem_wb_i_regwrite;
wire[31:0] mem_wb_i_res, mem_wb_i_memread;

// forwarding unit
assign id_ifregwrite = mem_wb_i_ifregwrite | ex_id_f_ifregwrite;
assign id_regwrite = mem_wb_i_ifregwrite ? mem_wb_i_regwrite : ex_mem_i_regwrite;
assign id_regdata = mem_wb_i_ifregwrite ? (mem_wb_i_ifmemread ? mem_wb_i_memread : mem_wb_i_res) : ex_mem_i_res;

MEM mem_instance(
    //input
    .mem_read(ex_mem_o_ifmemread),
    .mem_write(ex_mem_o_ifmemwrite),
    
    .ex_res_i(ex_mem_o_res),
    .if_reg_write_i(ex_mem_o_ifregwrite),
    .data_write_reg_i(ex_mem_o_regwrite),
    
    // output
    .mem_read_o(mem_wb_i_ifmemread),
    
    .ex_res_o(mem_wb_i_res),
    .if_reg_write_o(mem_wb_i_ifregwrite),
    .data_write_reg_o(mem_wb_i_regwrite)
);

// MMU MUX
wire mmu_ifmem = ex_mem_o_ifmemread | ex_mem_o_ifmemwrite;
wire mmu_bytemode = mmu_ifmem ? ex_mem_o_loadbyte : 1'b0;
assign mmu_read_wire = mmu_ifmem ? ex_mem_o_ifmemread : 1'b1;
assign mmu_write_wire = mmu_ifmem ? ex_mem_o_ifmemwrite : 1'b0;
assign mmu_addr_wire = mmu_ifmem ? ex_mem_o_res : if_imaddr;
assign if_imdata = mmu_out_data;
assign mem_wb_i_memread = mmu_out_data;
assign mmu_in_data = ex_mem_o_memwrite;

// MMU
MMU mmu_instance(
    .clk(clk),
    .if_read(mmu_read_wire),
    .if_write(mmu_write_wire),
    .addr(mmu_addr_wire),
    .input_data(mmu_in_data),
    .bytemode(mmu_bytemode),
    
    .output_data(mmu_out_data),
    
    // base_ram
    .base_ram_data(base_ram_data),
    .base_ram_addr(base_ram_addr),
    .base_ram_be_n(base_ram_be_n),
    .base_ram_ce_n(base_ram_ce_n),
    .base_ram_oe_n(base_ram_oe_n),
    .base_ram_we_n(base_ram_we_n),
    // ext_ram
    .ext_ram_data(ext_ram_data),
    .ext_ram_addr(ext_ram_addr),
    .ext_ram_be_n(ext_ram_be_n),
    .ext_ram_ce_n(ext_ram_ce_n),
    .ext_ram_oe_n(ext_ram_oe_n),
    .ext_ram_we_n(ext_ram_we_n),
    // uart
    .uart_rdn(uart_rdn),
    .uart_wrn(uart_wrn),
    .uart_dataready(uart_dataready),
    .uart_tbre(uart_tbre),
    .uart_tsre(uart_tsre),
    // leds & dpy
    .debug_leds(leds),
    .debug_dpys(dpys)
);

endmodule
