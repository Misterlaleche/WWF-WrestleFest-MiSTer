/* SPDX-FileCopyrightText: 2026
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Provisional TA-0031 raster timing.
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

localparam [8:0] H_TOTAL  = 9'd448;
localparam [8:0] H_ACTIVE = 9'd320;
localparam [8:0] H_SYNC_B = 9'd336;
localparam [8:0] H_SYNC_E = 9'd368;
localparam [8:0] V_TOTAL  = 9'd272;
localparam [8:0] V_ACT_B  = 9'd8;
localparam [8:0] V_ACT_E  = 9'd248;
localparam [8:0] V_SYNC_B = 9'd256;
localparam [8:0] V_SYNC_E = 9'd264;

assign LHBL = hcnt < H_ACTIVE;
assign LVBL = vcnt >= V_ACT_B && vcnt < V_ACT_E;
assign HS   = !(hcnt >= H_SYNC_B && hcnt < H_SYNC_E);
assign VS   = !(vcnt >= V_SYNC_B && vcnt < V_SYNC_E);

always @(posedge clk) begin
    irq2_tick <= 0;
    if(pxl_cen) begin
        if(hcnt == H_TOTAL-1) begin
            hcnt <= 0;
            if(vcnt == V_TOTAL-1) begin
                vcnt      <= 0;
                irq2_tick <= 1; // scanline 0 is also a 16-line raster IRQ
            end else begin
                vcnt <= vcnt + 1'd1;
                // Raster IRQ occurs at the start of lines 16,32,...,256.
                if(vcnt[3:0] == 4'hf) irq2_tick <= 1;
            end
        end else hcnt <= hcnt + 1'd1;
    end
    if(rst) begin
        hcnt      <= 0;
        vcnt      <= 0;
        irq2_tick <= 0;
    end
end

endmodule
