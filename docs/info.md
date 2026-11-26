<!-- Tiny Tapeout datasheet -->
## How it works

Three digital circuits share one interface. MODE = uio_in[7:6]: 00 ALU, 01 shared STEP supervisor, 10 independent X/Y supervisor V4, 11 reserved (all outputs zero). Keep MODE stable during operation. Reset before entering a supervisor mode. Inactive watchdog enables are masked; latched faults clear only on reset. ena=0 masks outputs. All bidirectional pins are inputs; uio[5:4] are unused.

ALU: A=ui[3:0], B=ui[7:4], SEL=uio[3:0]. Outputs R=uo[3:0], Carry=uo[4], Zero=uo[5]. Unsigned operands; result modulo 16. SEL 0 add, 1 subtract, 2 AND, 3 OR, 4 XOR, 5 NOT A, 6 equality, 7 A<B, 8 multiply, 9 integer divide. Others return R=0, Carry=0. Carry indicates addition overflow, subtraction borrow, multiplication overflow or division by zero (R=0). Zero refers to the truncated result.

STEP supervisor: ui[0]=step_x, ui[1]=step_y, ui[2]=watch. uo[0]=fault. At 10 MHz, 20 enabled cycles correspond to 2 us, excluding synchronization effects. Either synchronized rising edge restarts the timer. Fault is latched until reset. Watch should be stable relative to clk (original STEP module does not synchronize it).

V4: ui[0]=step_x, ui[1]=step_y, ui[2]=watch_x, ui[3]=watch_y. Outputs uo[0]=fault_x, uo[1]=fault_y, uo[2]=general_fault, uo[3]=no_fault_indicator. Prescaler=10000; 2000 ticks gives nominal 2 s at 10 MHz, with tick phase quantization and synchronization latency. Faults latch until reset. The indicator is not a safety-rated output; it is high after reset and when no fault has been detected, including when monitoring is disabled. No certified industrial safety use. STEP pulses must be long enough for reliable sampling. Use external independent safety protection.

## How to test

Run the clock at 10 MHz, set ena high, select the mode, hold rst_n low for several cycles and release with stable inputs. For ALU, select 8 and A=4 B=2, expect R=8. Select 9 and A=9 B=0, expect Carry=1, Zero=1 and R=0. For STEP, enable monitoring, provide no edges, and observe the latched fault after 20 enabled cycles. For V4, enable both axes and provide pulses to one axis; the other faults after about 2 s. Reset to clear. Test each mode independently. The supplied Cocotb tests include a long simulation at the real V4 timeout.

## External hardware

Digital input sources and output indicators compatible with the actual Tiny Tapeout board electrical levels. A 10 MHz clock for supervisor modes. Do not connect to industrial actuator power or use as the sole safety interlock.
