#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../../.." && pwd)
IV=${IVERILOG:-iverilog}
VV=${VVP:-vvp}
TMPDIR=${TMPDIR:-/tmp}

run() {
    top=$1
    shift
    "$IV" -g2005 -Wall -i -o "$TMPDIR/$top" -s "$top" "$@"
    "$VV" "$TMPDIR/$top"
}

cd "$ROOT"
run main_decode_tb cores/wwfwfest/ver/main_decode_tb.v \
    cores/wwfwfest/hdl/jtwwfw_main.v
run main_irq_tb cores/wwfwfest/ver/main_irq_tb.v \
    cores/wwfwfest/hdl/jtwwfw_main.v
run main_write_tb cores/wwfwfest/ver/main_write_tb.v \
    cores/wwfwfest/hdl/jtwwfw_main.v
run pixel_clock_tb cores/wwfwfest/ver/pixel_clock_tb.v \
    modules/jtframe/hdl/clocking/jtframe_frac_cen.v
run timing_tb cores/wwfwfest/ver/timing_tb.v \
    cores/wwfwfest/hdl/jtwwfw_timing.v \
    modules/jtframe/hdl/clocking/jtframe_frac_cen.v
run video_mixer_tb cores/wwfwfest/ver/video_mixer_tb.v \
    cores/wwfwfest/hdl/jtwwfw_video.v
run sound_decode_tb cores/wwfwfest/ver/sound_decode_tb.v \
    cores/wwfwfest/hdl/jtwwfw_sound.v modules/jtframe/hdl/jtframe_edge.v
run obj_buffer_tb cores/wwfwfest/ver/obj_buffer_tb.v \
    cores/wwfwfest/hdl/jtwwfw_obj.v
run obj_render_tb cores/wwfwfest/ver/obj_render_tb.v \
    cores/wwfwfest/hdl/jtwwfw_obj.v
run obj_flip_offset_tb cores/wwfwfest/ver/obj_flip_offset_tb.v \
    modules/jtframe/hdl/video/jtframe_objdraw.v \
    modules/jtframe/hdl/video/jtframe_objdraw_gate.v

ZIP=${1:?usage: run_all.sh ROM_ZIP [JTFRAME_ROM]}
ROM=${2:-rom/wwfwfest.rom}
python3 cores/wwfwfest/ver/rom_layout_test.py "$ZIP"
python3 cores/wwfwfest/ver/rom_image_test.py "$ZIP" "$ROM"
