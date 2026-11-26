# Cocotb 2.x; test through external pins (RTL and gate-level).
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, FallingEdge

async def init(dut, mode):
    dut.clk.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = mode << 6
    dut.rst_n.value = 0
    cocotb.start_soon(Clock(dut.clk, 100, unit="ns").start())
    await ClockCycles(dut.clk, 5)
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    await FallingEdge(dut.clk)

async def drive(dut, value, cycles):
    dut.ui_in.value = value
    await ClockCycles(dut.clk, cycles)
    await FallingEdge(dut.clk)

def check(dut, expected):
    got = int(dut.uo_out.value)
    assert got == expected, f"uo_out={got:08b}, expected={expected:08b}"
    assert int(dut.uio_oe.value) == 0
    assert int(dut.uio_out.value) == 0

def alu_ref(a, b, sel):
    c = 0
    if sel == 0:
        r = a + b; c = int(r > 15)
    elif sel == 1:
        r = a - b; c = int(a < b)
    elif sel == 2: r = a & b
    elif sel == 3: r = a | b
    elif sel == 4: r = a ^ b
    elif sel == 5: r = ~a
    elif sel == 6: r = int(a == b)
    elif sel == 7: r = int(a < b)
    elif sel == 8:
        r = a * b; c = int(r > 15)
    elif sel == 9:
        r = a // b if b else 0; c = int(b == 0)
    else: r = 0
    r &= 15
    return r | (c << 4) | (int(r == 0) << 5)

@cocotb.test()
async def test_alu_exhaustiva(dut):
    await init(dut, 0)
    for sel in range(16):
        for a in range(16):
            for b in range(16):
                dut.ui_in.value = (b << 4) | a
                dut.uio_in.value = sel
                await Timer(500, unit="ns")
                check(dut, alu_ref(a, b, sel))
    dut.uio_in.value = 0xC0
    await Timer(500, unit="ns")
    check(dut, 0)
    dut.uio_in.value = 0
    dut.ena.value = 0
    await Timer(500, unit="ns")
    check(dut, 0)

@cocotb.test()
async def test_supervisor_step(dut):
    await init(dut, 1)
    await drive(dut, 0, 30)
    check(dut, 0)
    # Both axes independently produce rising pulses and restart the shared timeout.
    for bit in (1, 2, 1, 2):
        await drive(dut, 4 | bit, 5)
        await drive(dut, 4, 5)
        check(dut, 0)
    await drive(dut, 4, 8)
    check(dut, 0)
    await drive(dut, 4, 20)
    check(dut, 1)
    await drive(dut, 0, 30)
    check(dut, 1)  # fault remains latched even when disabled
    dut.rst_n.value = 0
    await Timer(500, unit="ns")
    check(dut, 0)
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await drive(dut, 4, 19)
    check(dut, 0)
    await drive(dut, 4, 1)
    check(dut, 1)  # exact 20th enabled clock, no STEP pulses

@cocotb.test()
async def test_supervisor_v4_tiempo_real(dut):
    await init(dut, 2)
    check(dut, 8)
    # Both enabled. Y receives a STEP near 1 s; X does not.
    dut.ui_in.value = 0xC
    await Timer(1000, unit="ms")
    check(dut, 8)
    await FallingEdge(dut.clk)
    await drive(dut, 0xE, 5)
    await drive(dut, 0xC, 5)
    await Timer(998, unit="ms")
    check(dut, 8)
    await Timer(5, unit="ms")
    check(dut, 5)  # X=1, Y=0, general=1, indicator=0
    # Y still receives another STEP; X stays latched.
    await FallingEdge(dut.clk)
    await drive(dut, 0xF, 5)
    await drive(dut, 0xC, 5)
    await Timer(1990, unit="ms")
    check(dut, 5)
    await Timer(15, unit="ms")
    check(dut, 7)  # both faults latched
    await FallingEdge(dut.clk)
    await drive(dut, 0, 10)
    check(dut, 7)
    dut.rst_n.value = 0
    await Timer(500, unit="ns")
    check(dut, 8)
