/* SPDX-FileCopyrightText: 2026
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Technos TA-0031 main CPU and address decoder
 */

module jtwwfw_main(
    input               rst,
    input               clk,
    input               LVBL,
    input               irq2_tick,

    output       [18:1] main_addr,
    output       [ 1:0] main_dsn,
    output       [15:0] main_dout,
    output              rom_cs,
    input        [15:0] main_data,
    input               main_ok,

    output       [13:1] ram_addr,
    output              ram_cs,
    output              ram_we,
    input        [15:0] ram_data,
    input               ram_ok,

    output reg   [ 9:0] main_fg_addr,
    output reg   [11:1] main_bg_addr,
    output reg   [10:0] main_txt_addr,
    output reg   [15:0] main_txt_din,
    output reg   [12:1] main_objram_addr,
    output reg   [13:1] main_palram_addr,
    output reg   [ 1:0] fgattr_we,
    output reg   [ 1:0] fgcode_we,
    output reg   [ 1:0] bg_we,
    output reg   [ 1:0] txt_we,
    output reg   [ 1:0] objram_we,
    output reg   [ 1:0] palram_we,
    input        [15:0] main_fgattr_dout,
    input        [15:0] main_fgcode_dout,
    input        [15:0] main_bg_dout,
    input        [15:0] main_txt_dout,
    input        [15:0] main_objram_dout,
    input        [15:0] main_palram_dout,

    output reg   [15:0] fg_scrollx,
    output reg   [15:0] fg_scrolly,
    output reg   [15:0] bg_scrollx,
    output reg   [15:0] bg_scrolly,
    output reg          flip,
    output reg   [ 7:0] prio,
    output reg          objbuf_trig,

    output reg          snd_on,
    output reg   [ 7:0] snd_latch,

    input        [ 5:0] joystick1,
    input        [ 5:0] joystick2,
    input        [ 5:0] joystick3,
    input        [ 5:0] joystick4,
    input        [ 3:0] start_button,
    input        [ 3:0] coin,
    input               service,
    input               dip_pause,
    input        [ 7:0] dipsw_a,
    input        [ 7:0] dipsw_b
);

wire [23:1] A;
wire [15:0] cpu_dout;
reg  [15:0] cpu_din;
wire        UDSn, LDSn, RnW, ASn, VPAn, DTACKn, BUSn;
wire [ 2:0] FC;
wire        cpu_cen, cpu_cenb;
wire        ext_busy, ext_ok;
reg         irq2, irq3, lvbl_l;
reg         rom_sel, ram_sel, fg_sel, bg_sel, txt_sel, obj_sel;
reg         pal_sel, io_sel, scroll_sel;
reg  [15:0] io_dout;

assign main_addr = A[18:1];
assign main_dsn  = {UDSn,LDSn};
assign main_dout = cpu_dout;
assign ram_addr  = A[13:1];
assign BUSn      = UDSn & LDSn;
assign rom_cs    = rom_sel;
assign ram_cs    = ram_sel;
assign ram_we    = ram_sel & ~RnW;
assign ext_ok    = (rom_sel & main_ok) | (ram_sel & ram_ok);
assign ext_busy  = (rom_sel | ram_sel) & ~ext_ok;
assign VPAn      = !(!ASn && FC==3'b111);

/* MAME names the first two scrolling layers FG and BG. Their register order
 * is FG X/Y followed by BG X/Y at 0x100000. */
always @* begin
    rom_sel    = 0;
    ram_sel    = 0;
    fg_sel     = 0;
    bg_sel     = 0;
    txt_sel    = 0;
    obj_sel    = 0;
    pal_sel    = 0;
    io_sel     = 0;
    scroll_sel = 0;

    if(!ASn && !BUSn) begin
        if(A[23:19] == 5'b00000)                   rom_sel = 1; // 000000-07ffff
        else if(A[23:12] == 12'h080)               fg_sel = 1; // 080000-080fff
        else if(A[23:12] == 12'h082)               bg_sel = 1; // 082000-082fff
        else if(A[23:13] == 11'b00001100000)       txt_sel = 1; // 0c0000-0c1fff
        else if(A[23:13] == 11'b00001100001)       obj_sel = 1; // 0c2000-0c3fff
        else if(A[23:4]  == 20'h10000)          scroll_sel = 1; // 100000-10000f
        else if(A[23:5]  == (24'h140020 >> 5))     io_sel = 1; // 140020-14003f
        else if(A[23:16] == 8'h18)                 pal_sel = 1; // 180000-18ffff
        else if(A[23:14] == 10'h070)               ram_sel = 1; // 1c0000-1c3fff
    end
end

always @* begin
    main_fg_addr     = A[11:2];
    main_bg_addr     = A[11:1];
    main_txt_addr    = A[12:2];
    main_objram_addr = A[12:1];
    // Physical byte-address lines A5/A6 are absent. Equivalently, for the
    // 68000 word offset this is (offset&0xf)|((offset&0x7fc0)>>2).
    main_palram_addr = {A[15:7],A[4:1]};
    fgattr_we   = {2{fg_sel & ~RnW & ~A[1]}} & ~{UDSn,LDSn};
    fgcode_we   = {2{fg_sel & ~RnW &  A[1]}} & ~{UDSn,LDSn};
    bg_we       = {2{bg_sel  & ~RnW}} & ~{UDSn,LDSn};
    objram_we   = {2{obj_sel & ~RnW}} & ~{UDSn,LDSn};
    palram_we   = {2{pal_sel & ~RnW}} & ~{UDSn,LDSn};
    // The PCB smears either 68000 byte lane onto the same 8-bit RAM data bus.
    // Two consecutive byte-wide entries are packed into one framework word.
    main_txt_din = {2{!LDSn ? cpu_dout[7:0] : cpu_dout[15:8]}};
    txt_we      = {~A[1],A[1]} &
                  {2{txt_sel & ~RnW & (!LDSn | !UDSn)}};
end

always @* begin
    case(A[2:1])
        // Exact P1-P4 bit positions from the TA-0031 input map. JTFRAME
        // presents the active-low joystick and button signals in bits 5:0.
        2'd0: io_dout = {2'b11,dipsw_b[7:6],2'b11,service,coin[0],
                         start_button[0],1'b1,joystick1[5:0]};
        2'd1: io_dout = {2'b11,dipsw_b[5:0],start_button[1],1'b1,
                         joystick2[5:0]};
        2'd2: io_dout = {2'b11,dipsw_a[5:0],start_button[2],1'b1,
                         joystick3[5:0]};
        // The screen input is active low: high during the visible region and
        // low throughout vertical blanking.
        default: io_dout = {5'b11111,LVBL,dipsw_a[7:6],start_button[3],
                            1'b1,joystick4[5:0]};
    endcase
end

always @* begin
    cpu_din = rom_sel ? main_data   :
              ram_sel ? ram_data    :
               fg_sel ? (A[1] ? main_fgcode_dout : main_fgattr_dout) :
               bg_sel ? main_bg_dout     :
              txt_sel ? {8'h00,A[1] ? main_txt_dout[7:0] :
                                         main_txt_dout[15:8]} :
              obj_sel ? main_objram_dout :
              pal_sel ? main_palram_dout :
               io_sel ? io_dout     :
           scroll_sel ? (A[3:1] == 0 ? fg_scrollx :
                         A[3:1] == 1 ? fg_scrolly :
                         A[3:1] == 2 ? bg_scrollx :
                         A[3:1] == 3 ? bg_scrolly : 16'h0000) : 16'hffff;
end

always @(posedge clk) begin
    objbuf_trig <= 0;
    snd_on      <= 0;
    lvbl_l      <= LVBL;

    if(irq2_tick) irq2 <= 1;
    if(lvbl_l && !LVBL) irq3 <= 1;

    if(!ASn && !RnW) begin
        if(A[23:1] == (24'h140000>>1)) irq3 <= 0;
        if(A[23:1] == (24'h140002>>1)) irq2 <= 0;
        if(A[23:1] == (24'h140008>>1)) objbuf_trig <= 1;
        if(A[23:1] == (24'h14000c>>1)) begin
            snd_latch <= cpu_dout[7:0];
            snd_on    <= 1;
        end
        if(A[23:1] == (24'h10000a>>1)) flip <= cpu_dout[0];
        if(A[23:1] == (24'h140010>>1) && !LDSn) prio <= cpu_dout[7:0];
        if(scroll_sel) case(A[3:1])
            0: fg_scrollx <= cpu_dout;
            1: fg_scrolly <= cpu_dout;
            2: bg_scrollx <= cpu_dout;
            3: bg_scrolly <= cpu_dout;
            default:;
        endcase
    end

    if(rst) begin
        irq2        <= 0;
        irq3        <= 0;
        lvbl_l      <= 1;
        flip        <= 0;
        prio        <= 0;
        snd_on      <= 0;
        snd_latch   <= 0;
        objbuf_trig <= 0;
        fg_scrollx  <= 0;
        fg_scrolly  <= 0;
        bg_scrollx  <= 0;
        bg_scrolly  <= 0;
    end
end

jtframe_68kdtack_cen #(.W(8)) u_dtack(
    .rst(rst), .clk(clk), .cpu_cen(cpu_cen), .cpu_cenb(cpu_cenb),
    .bus_cs(rom_sel | ram_sel), .bus_busy(ext_busy), .bus_legit(1'b0),
    .bus_ack(1'b0), .ASn(ASn), .DSn({UDSn,LDSn}),
    .num(7'd6), .den(8'd24), .DTACKn(DTACKn),
    .wait2(1'b0), .wait3(1'b0), .fave(), .fworst()
);

jtframe_m68k u_cpu(
    .clk(clk), .rst(rst), .RESETn(), .cpu_cen(cpu_cen), .cpu_cenb(cpu_cenb),
    .eab(A), .iEdb(cpu_din), .oEdb(cpu_dout), .eRWn(RnW),
    .LDSn(LDSn), .UDSn(UDSn), .ASn(ASn), .VPAn(VPAn), .FC(FC),
    .BERRn(1'b1), .HALTn(dip_pause), .BRn(1'b1), .BGACKn(1'b1), .BGn(),
    .DTACKn(DTACKn), .IPLn(~(irq3 ? 3'd3 : irq2 ? 3'd2 : 3'd0))
);

endmodule
