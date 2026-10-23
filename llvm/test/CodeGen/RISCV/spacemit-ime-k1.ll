; RUN: llc -mtriple=riscv64 -mattr=+v,+xsmtvdot -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=riscv64 -mattr=+v,+xsmtvdot -filetype=obj < %s \
; RUN:   | llvm-objdump -d --mattr=+v,+xsmtvdot - | FileCheck %s --check-prefix=ENC

; K1 (XSMTVDot) at VLEN=256: the 4x8 int8 inputs occupy one vector register
; each and the 4x4 int32 accumulator an aligned register pair. The dot is
; issued under e8, m1, and the accumulator is tied to the result.
declare <vscale x 4 x i32> @llvm.riscv.ime.vmadot.nxv4i32.nxv8i8.nxv8i8(<vscale x 4 x i32>, <vscale x 8 x i8>, <vscale x 8 x i8>)
declare <vscale x 4 x i32> @llvm.riscv.ime.vmadotu.nxv4i32.nxv8i8.nxv8i8(<vscale x 4 x i32>, <vscale x 8 x i8>, <vscale x 8 x i8>)
declare <vscale x 4 x i32> @llvm.riscv.ime.vmadotsu.nxv4i32.nxv8i8.nxv8i8(<vscale x 4 x i32>, <vscale x 8 x i8>, <vscale x 8 x i8>)
declare <vscale x 4 x i32> @llvm.riscv.ime.vmadotus.nxv4i32.nxv8i8.nxv8i8(<vscale x 4 x i32>, <vscale x 8 x i8>, <vscale x 8 x i8>)

define <vscale x 4 x i32> @signed_dot(<vscale x 4 x i32> %c, <vscale x 8 x i8> %a, <vscale x 8 x i8> %b) {
; CHECK-LABEL: signed_dot:
; CHECK: vsetvli {{.*}}, zero, e8, m1,
; CHECK-NEXT: smt.vmadot v8, v10, v11
; ENC: e2b5342b {{.*}}smt.vmadot v8, v10, v11
  %r = call <vscale x 4 x i32> @llvm.riscv.ime.vmadot.nxv4i32.nxv8i8.nxv8i8(<vscale x 4 x i32> %c, <vscale x 8 x i8> %a, <vscale x 8 x i8> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @unsigned_dot(<vscale x 4 x i32> %c, <vscale x 8 x i8> %a, <vscale x 8 x i8> %b) {
; CHECK-LABEL: unsigned_dot:
; CHECK: smt.vmadotu v8, v10, v11
  %r = call <vscale x 4 x i32> @llvm.riscv.ime.vmadotu.nxv4i32.nxv8i8.nxv8i8(<vscale x 4 x i32> %c, <vscale x 8 x i8> %a, <vscale x 8 x i8> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @signed_unsigned_dot(<vscale x 4 x i32> %c, <vscale x 8 x i8> %a, <vscale x 8 x i8> %b) {
; CHECK-LABEL: signed_unsigned_dot:
; CHECK: smt.vmadotsu v8, v10, v11
  %r = call <vscale x 4 x i32> @llvm.riscv.ime.vmadotsu.nxv4i32.nxv8i8.nxv8i8(<vscale x 4 x i32> %c, <vscale x 8 x i8> %a, <vscale x 8 x i8> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @unsigned_signed_dot(<vscale x 4 x i32> %c, <vscale x 8 x i8> %a, <vscale x 8 x i8> %b) {
; CHECK-LABEL: unsigned_signed_dot:
; CHECK: smt.vmadotus v8, v10, v11
  %r = call <vscale x 4 x i32> @llvm.riscv.ime.vmadotus.nxv4i32.nxv8i8.nxv8i8(<vscale x 4 x i32> %c, <vscale x 8 x i8> %a, <vscale x 8 x i8> %b)
  ret <vscale x 4 x i32> %r
}

; Accumulation chain: the accumulator stays in its register pair.
define <vscale x 4 x i32> @chain(<vscale x 4 x i32> %c, <vscale x 8 x i8> %a, <vscale x 8 x i8> %b) {
; CHECK-LABEL: chain:
; CHECK: smt.vmadot v8, v10, v11
; CHECK-NEXT: smt.vmadot v8, v11, v10
; CHECK-NEXT: ret
  %r0 = call <vscale x 4 x i32> @llvm.riscv.ime.vmadot.nxv4i32.nxv8i8.nxv8i8(<vscale x 4 x i32> %c, <vscale x 8 x i8> %a, <vscale x 8 x i8> %b)
  %r1 = call <vscale x 4 x i32> @llvm.riscv.ime.vmadot.nxv4i32.nxv8i8.nxv8i8(<vscale x 4 x i32> %r0, <vscale x 8 x i8> %b, <vscale x 8 x i8> %a)
  ret <vscale x 4 x i32> %r1
}

; Sliding-window dots read A from an aligned register pair.
declare <vscale x 4 x i32> @llvm.riscv.ime.vmadot1.nxv4i32.nxv16i8.nxv8i8(<vscale x 4 x i32>, <vscale x 16 x i8>, <vscale x 8 x i8>)
declare <vscale x 4 x i32> @llvm.riscv.ime.vmadot2u.nxv4i32.nxv16i8.nxv8i8(<vscale x 4 x i32>, <vscale x 16 x i8>, <vscale x 8 x i8>)
declare <vscale x 4 x i32> @llvm.riscv.ime.vmadot3su.nxv4i32.nxv16i8.nxv8i8(<vscale x 4 x i32>, <vscale x 16 x i8>, <vscale x 8 x i8>)
declare <vscale x 4 x i32> @llvm.riscv.ime.vmadot3us.nxv4i32.nxv16i8.nxv8i8(<vscale x 4 x i32>, <vscale x 16 x i8>, <vscale x 8 x i8>)

define <vscale x 4 x i32> @slide1(<vscale x 4 x i32> %c, <vscale x 16 x i8> %a, <vscale x 8 x i8> %b) {
; CHECK-LABEL: slide1:
; CHECK: vsetvli {{.*}}, zero, e8, m1,
; CHECK-NEXT: smt.vmadot1 v8, v10, v12
  %r = call <vscale x 4 x i32> @llvm.riscv.ime.vmadot1.nxv4i32.nxv16i8.nxv8i8(<vscale x 4 x i32> %c, <vscale x 16 x i8> %a, <vscale x 8 x i8> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @slide2u(<vscale x 4 x i32> %c, <vscale x 16 x i8> %a, <vscale x 8 x i8> %b) {
; CHECK-LABEL: slide2u:
; CHECK: smt.vmadot2u v8, v10, v12
  %r = call <vscale x 4 x i32> @llvm.riscv.ime.vmadot2u.nxv4i32.nxv16i8.nxv8i8(<vscale x 4 x i32> %c, <vscale x 16 x i8> %a, <vscale x 8 x i8> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @slide3su(<vscale x 4 x i32> %c, <vscale x 16 x i8> %a, <vscale x 8 x i8> %b) {
; CHECK-LABEL: slide3su:
; CHECK: smt.vmadot3su v8, v10, v12
  %r = call <vscale x 4 x i32> @llvm.riscv.ime.vmadot3su.nxv4i32.nxv16i8.nxv8i8(<vscale x 4 x i32> %c, <vscale x 16 x i8> %a, <vscale x 8 x i8> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @slide3us(<vscale x 4 x i32> %c, <vscale x 16 x i8> %a, <vscale x 8 x i8> %b) {
; CHECK-LABEL: slide3us:
; CHECK: smt.vmadot3us v8, v10, v12
  %r = call <vscale x 4 x i32> @llvm.riscv.ime.vmadot3us.nxv4i32.nxv16i8.nxv8i8(<vscale x 4 x i32> %c, <vscale x 16 x i8> %a, <vscale x 8 x i8> %b)
  ret <vscale x 4 x i32> %r
}
