; RUN: llc -mtriple=riscv64 -mattr=+v -verify-machineinstrs < %s | FileCheck %s
;
; llvm.riscv.sched.barrier keeps its operand in place and emits nothing. It
; carries no VL/VTYPE effect, so the two adds share one vsetvli, and it is a
; data dependence: the second add reads the barrier's result.

; CHECK-LABEL: two_adds:
; CHECK: vsetvli
; CHECK-NEXT: vadd.vv [[R:v[0-9]+]], v8, v9
; CHECK-NEXT: # sched barrier
; CHECK-NEXT: vadd.vv v8, [[R]], v9
; CHECK-NEXT: ret
define <vscale x 2 x i32> @two_adds(<vscale x 2 x i32> %a, <vscale x 2 x i32> %b) {
  %x = add <vscale x 2 x i32> %a, %b
  %y = call <vscale x 2 x i32> @llvm.riscv.sched.barrier.nxv2i32(<vscale x 2 x i32> %x)
  %z = add <vscale x 2 x i32> %y, %b
  ret <vscale x 2 x i32> %z
}

; A register group: the m2 value stays in its group.
; CHECK-LABEL: group:
; CHECK: vsetvli
; CHECK-NEXT: vadd.vv v8, v8, v10
; CHECK-NEXT: # sched barrier
; CHECK-NEXT: vadd.vv v8, v8, v10
; CHECK-NEXT: ret
define <vscale x 4 x i32> @group(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) {
  %x = add <vscale x 4 x i32> %a, %b
  %y = call <vscale x 4 x i32> @llvm.riscv.sched.barrier.mem.nxv4i32(<vscale x 4 x i32> %x)
  %z = add <vscale x 4 x i32> %y, %b
  ret <vscale x 4 x i32> %z
}

; The barrier is not hoisted out of a loop even though its operand is
; loop invariant.
; CHECK-LABEL: in_loop:
; CHECK: .LBB2_1:
; CHECK: # sched barrier
; CHECK: bnez
define void @in_loop(ptr %p, <vscale x 2 x i32> %v, i64 %n) {
entry:
  br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %i.next, %loop ]
  %y = call <vscale x 2 x i32> @llvm.riscv.sched.barrier.nxv2i32(<vscale x 2 x i32> %v)
  store <vscale x 2 x i32> %y, ptr %p
  %i.next = add i64 %i, 1
  %c = icmp ne i64 %i.next, %n
  br i1 %c, label %loop, label %exit
exit:
  ret void
}

; A scalar in a GPR.
; CHECK-LABEL: scalar:
; CHECK: # sched barrier
define i64 @scalar(i64 %a) {
  %y = call i64 @llvm.riscv.sched.barrier.i64(i64 %a)
  %z = add i64 %y, 1
  ret i64 %z
}

declare <vscale x 2 x i32> @llvm.riscv.sched.barrier.nxv2i32(<vscale x 2 x i32>)
declare <vscale x 4 x i32> @llvm.riscv.sched.barrier.mem.nxv4i32(<vscale x 4 x i32>)
declare i64 @llvm.riscv.sched.barrier.i64(i64)

; The barrier is a scheduling boundary: the zero splats written before it stay
; before it and the multiply-add written after it stays after it, although neither
; uses the barrier's value.
; CHECK-LABEL: boundary:
; CHECK: vmv.v.i
; CHECK: vmv.v.i
; CHECK-NOT: vmacc
; CHECK: # sched barrier
; CHECK-NOT: vmv.v.i
; CHECK: vmacc.vv
define void @boundary(ptr %p, ptr %q, <vscale x 2 x i32> %a, <vscale x 2 x i32> %b) {
  store <vscale x 2 x i32> zeroinitializer, ptr %p
  store <vscale x 2 x i32> splat (i32 1), ptr %q
  %y = call <vscale x 2 x i32> @llvm.riscv.sched.barrier.nxv2i32(<vscale x 2 x i32> %a)
  %m = mul <vscale x 2 x i32> %b, %b
  %z = add <vscale x 2 x i32> %y, %m
  store <vscale x 2 x i32> %z, ptr %p
  ret void
}
