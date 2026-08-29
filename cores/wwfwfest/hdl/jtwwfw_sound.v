/* SPDX-FileCopyrightText: 2026
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Technos TA-0031 sound subsystem
 */

module jtwwfw_sound(
    input                 rst,
    input                 clk,
    input                 cen_fm,
    input                 cen_fm2,
    input                 cen_oki,

    input                 snd_on,
    input          [ 7:0] snd_latch,

    output         [15:0] rom_addr,
    output reg            rom_cs,
    input          [ 7:0] rom_data,
    input                 rom_ok,

    output         [18:0] pcm_addr,
    output                pcm_cs,
    input          [ 7:0] pcm_data,
    input                 pcm_ok,

    output signed  [15:0] fm_l,
    output signed  [15:0] fm_r,
    output signed  [13:0] pcm
);

`ifndef NOSOUND
wire [15:0] A;
wire [ 7:0] cpu_dout, ram_dout, fm_dout, oki_dout;
wire [17:0] oki_addr;
reg  [ 7:0] cpu_din;
reg         ram_cs, fm_cs, oki_cs, latch_cs, bank_cs;
reg         oki_bank;
wire        mreq_n, iorq_n, rd_n, wr_n, rfsh_n, m1_n;
wire        int_n, nmi_n, oki_wrn;

assign rom_addr = A;
assign pcm_addr = {oki_bank,oki_addr};
assign pcm_cs   = 1'b1;
assign oki_wrn  = ~(oki_cs & ~wr_n);

always @* begin
    rom_cs   = 0;
    ram_cs   = 0;
    fm_cs    = 0;
    oki_cs   = 0;
    latch_cs = 0;
    bank_cs  = 0;

    if(!mreq_n && rfsh_n) begin
        if(A < 16'hc000)               rom_cs   = 1;
        else if(A >= 16'hc000 && A < 16'hc800) ram_cs = 1;
        else case(A)
            16'hc800,16'hc801: fm_cs    = 1;
            16'hd800:           oki_cs   = 1;
            16'he000:           latch_cs = 1;
            16'he800:           bank_cs  = 1;
            default:;
        endcase
    end
end

always @* begin
    cpu_din = rom_cs   ? rom_data  :
              ram_cs   ? ram_dout  :
              fm_cs    ? fm_dout   :
              oki_cs   ? oki_dout  :
              latch_cs ? snd_latch : 8'hff;
end

always @(posedge clk) begin
    if(bank_cs && !wr_n) oki_bank <= cpu_dout[0];
    if(rst) oki_bank <= 0;
end

// A main-CPU sound command asserts Z80 NMI until the latch is read.
jtframe_edge #(.QSET(0)) u_nmi(
    .rst    ( rst      ),
    .clk    ( clk      ),
    .edgeof ( snd_on   ),
    .clr    ( latch_cs & ~rd_n ),
    .q      ( nmi_n    )
);

jtframe_sysz80 #(.RAM_AW(11)) u_z80(
    .rst_n      ( ~rst      ),
    .clk        ( clk       ),
    .cen        ( cen_fm    ),
    .cpu_cen    (           ),
    .int_n      ( int_n     ),
    .nmi_n      ( nmi_n     ),
    .busrq_n    ( 1'b1      ),
    .m1_n       ( m1_n      ),
    .mreq_n     ( mreq_n    ),
    .iorq_n     ( iorq_n    ),
    .rd_n       ( rd_n      ),
    .wr_n       ( wr_n      ),
    .rfsh_n     ( rfsh_n    ),
    .halt_n     (           ),
    .busak_n    (           ),
    .A          ( A         ),
    .cpu_din    ( cpu_din   ),
    .cpu_dout   ( cpu_dout  ),
    .ram_dout   ( ram_dout  ),
    .ram_cs     ( ram_cs    ),
    .rom_cs     ( rom_cs    ),
    .rom_ok     ( rom_ok    )
);

jt51 u_fm(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen_fm    ),
    .cen_p1     ( cen_fm2   ),
    .cs_n       ( ~fm_cs    ),
    .wr_n       ( wr_n      ),
    .a0         ( A[0]      ),
    .din        ( cpu_dout  ),
    .dout       ( fm_dout   ),
    .ct1        (           ),
    .ct2        (           ),
    .irq_n      ( int_n     ),
    .sample     (           ),
    .left       (           ),
    .right      (           ),
    .xleft      ( fm_l      ),
    .xright     ( fm_r      )
);

jt6295 #(.INTERPOL(0)) u_oki(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen_oki   ),
    .ss         ( 1'b1      ),
    .wrn        ( oki_wrn   ),
    .din        ( cpu_dout  ),
    .dout       ( oki_dout  ),
    .rom_addr   ( oki_addr  ),
    .rom_data   ( pcm_data  ),
    .rom_ok     ( pcm_ok    ),
    .sound      ( pcm       ),
    .sample     (           )
);

`else
assign rom_addr = 0;
assign pcm_addr = 0;
assign pcm_cs   = 0;
assign fm_l     = 0;
assign fm_r     = 0;
assign pcm      = 0;
always @* rom_cs = 0;
`endif

endmodule
