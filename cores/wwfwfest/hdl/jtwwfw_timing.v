/* SPDX-FileCopyrightText: 2026
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Provisional TA-0031 raster timing plus measured WrestleFest IRQ2 rate.
 *
 * The 448x272 totals and 320x240 visible window follow MAME. MAME explicitly
 * labels the totals as guessed; HS/VS positions below therefore remain a
 * hardware-validation item. Counters are isolated in this module so measured
 * values can be substituted without touching any graphics pipeline.
 */

module jtwwfw_timing(
    input            rst,
    input            clk,
    input            pxl_cen,
    output reg [8:0] hcnt,
    output reg [8:0] vcnt,
    output           LHBL,
    output           LVBL,
    output           HS,
    output           VS,
    output reg        irq2_tick
);

// JTFRAME expects HS/VS asserted high; LHBL/LVBL remain high during active video.
// IMPORTANT: the raster must keep running while the game is held in reset during
// MiSTer ROM download. Stopping hcnt/vcnt removes HS/VS and breaks the video lock.
localparam [8:0] H_TOTAL  = 9'd448;
localparam [8:0] H_ACTIVE = 9'd320;
localparam [8:0] H_SYNC_B = 9'd336;
localparam [8:0] H_SYNC_E = 9'd368;
localparam [8:0] V_TOTAL  = 9'd272;
localparam [8:0] V_ACT_B  = 9'd8;
localparam [8:0] V_ACT_E  = 9'd248;
localparam [8:0] V_SYNC_B = 9'd256;
localparam [8:0] V_SYNC_E = 9'd264;

// Coin-Op Collection measured WrestleFest's periodic input-polling IRQ at ~1.63 kHz
// on real TA-0031 hardware. Generate it independently of the video raster.
// 48,000,000 / 29,448 = 1,629.99185 Hz (0.0005% from 1.63 kHz).
localparam [14:0] IRQ2_DIV = 15'd29448;
reg [14:0] irq2_div;

// TA-0031 renderer needs one extra horizontal source pixel; expose
// a 320-pixel window at h=1..320 instead of the junk wrap pixel h=0.
assign LHBL = hcnt >= 9'd1 && hcnt < 9'd321;
assign LVBL = vcnt >= V_ACT_B && vcnt < V_ACT_E;
assign HS   =  (hcnt >= H_SYNC_B && hcnt < H_SYNC_E);
assign VS   =  (vcnt >= V_SYNC_B && vcnt < V_SYNC_E);

`ifdef SIMULATION
initial begin
    hcnt = 0;
    vcnt = 0;
    irq2_div = 0;
    irq2_tick = 0;
end
`endif

always @(posedge clk) begin
    // IRQ2 is an independent periodic source. jtwwfw_main latches this event
    // until the 68000 acknowledges it at 0x140002, so one master-clock pulse is enough.
    irq2_tick <= 0;
    if(irq2_div == 15'd29447) begin
        irq2_div  <= 0;
        irq2_tick <= 1;
    end else begin
        irq2_div <= irq2_div + 1'd1;
    end

    if(pxl_cen) begin
        if(hcnt == H_TOTAL-1) begin
            hcnt <= 0;
            if(vcnt == V_TOTAL-1)
                vcnt <= 0;
            else
                vcnt <= vcnt + 1'd1;
        end else hcnt <= hcnt + 1'd1;
    end

    // Game reset must not stop the video raster. Only the game-side periodic IRQ
    // source is reset here. Cyclone V registers power up low; for simulation the
    // raster counters are initialized explicitly below.
    if(rst) begin
        irq2_div  <= 0;
        irq2_tick <= 0;
    end
end

endmodule
