# Asynchronous-FIFO


A parameterized, dual-clock asynchronous FIFO built from scratch in Verilog, with a self-checking testbench and safe clock-domain-crossing (CDC) handling.

## Why an async FIFO?

In most real SoCs, two blocks running on independent, unrelated clocks need to exchange data safely — for example, a fast processing core writing to a slower peripheral, or two IP blocks with independent clock domains. Simply wiring a signal from one clock domain into another risks **metastability**, where a flip-flop samples a signal mid-transition and outputs an invalid or unpredictable value. An asynchronous FIFO solves this by using **Gray-coded pointers** and **two-flop synchronizers** to safely pass pointer information between domains without ever crossing a multi-bit binary value directly.

## Architecture

```
                 ┌────────────┐                      ┌────────────┐
   wr_data ─────►│            │                       │            │
   wr_en   ─────►│  wr_ptr    │──wr_gray───┐  ┌───────│  sync_w2r  │──wr_gray_sync──┐
   wr_clk  ─────►│            │            │  │       │  (rd_clk)  │                │
                 └─────┬──────┘            │  │       └────────────┘                ▼
                       │ wr_bin            ▼  │                              ┌──────────────┐
                       │              ┌────────────┐                        │  empty_logic │──► empty
                       ▼              │ sync_r2w   │◄──rd_gray───┐          └──────────────┘
                 ┌────────────┐       │  (wr_clk)  │             │
                 │  fifo_mem  │       └─────┬──────┘             │
                 │ (dual-port)│             │ rd_gray_sync       │
                 └─────┬──────┘             ▼                    │
                       │              ┌────────────┐             │
                       │              │ full_logic │──► full     │
   rd_data ◄───────────┘              └────────────┘        ┌────┴───────┐
                                                              │  rd_ptr    │◄── rd_en, rd_clk
                                                              └────────────┘
```

## Modules

| File | Description |
|---|---|
| `rtl/wr_ptr.v` | Binary + Gray-coded write pointer, gated by `full` |
| `rtl/rd_ptr.v` | Binary + Gray-coded read pointer, gated by `empty` |
| `rtl/sync_r2w.v` | 2-flop synchronizer bringing the read pointer into the write clock domain |
| `rtl/sync_w2r.v` | 2-flop synchronizer bringing the write pointer into the read clock domain |
| `rtl/full_logic.v` | Combinational full-flag detection using the Gray-code wrap comparison |
| `rtl/empty_logic.v` | Combinational empty-flag detection |
| `rtl/fifo_mem.v` | Dual-port synchronous RAM, the actual FIFO storage |
| `rtl/async_fifo.v` | Top-level integration of all sub-modules |
| `tb/async_fifo_tb.v` | Self-checking testbench: reset, single write/read, multi-word FIFO ordering, full-boundary, and empty-boundary tests |

## Key design points

- **Gray-code pointers**: guarantee only one bit changes per increment, so even a metastable synchronizer sample is still a valid adjacent value, never garbage.
- **Extra pointer bit**: pointers are `ADDR_WIDTH+1` bits wide. The MSB acts as a wrap/lap indicator, letting `full`/`empty` be distinguished even when the lower address bits are identical.
- **Early flag generation**: `full`/`empty` are computed from the *next* pointer value (before it's registered), so the write/read enable can be blocked in the same cycle that would otherwise overflow/underflow the FIFO — no wasted cycle.
- **Defense in depth**: the top level double-gates the memory's actual `wr_en`/`rd_en` with `!full`/`!empty`, even though the pointer modules already block internally.

## Testbench

The testbench drives independent, non-integer-ratio clock periods (`wr_clk` = 10ns period, `rd_clk` = 14ns period) specifically to exercise the CDC synchronizers under realistic, unaligned clock-edge conditions. It covers:

- Dual-domain reset
- Single write → propagation through the synchronizer → `empty` deassertion
- Single write + read round trip with data check
- Multi-word write/read ordering (FIFO behavior, not just data integrity)
- Full-boundary: filling the FIFO completely and confirming writes are blocked
- Empty-boundary: draining the FIFO completely and confirming reads are blocked

## A real bug I hit and fixed: zero-delay combinational loop

Early versions of `wr_ptr`/`rd_ptr` gated the pointer's next-state calculation directly with the live `full`/`empty` flag:

```verilog
// buggy version
assign wr_bin_next = (wr_en && !full) ? wr_bin + 1'b1 : wr_bin;
```

But `full` is itself derived combinationally from `wr_gray_next`, which depends on `wr_bin_next` — creating a **zero-delay combinational loop**: `wr_bin_next → wr_gray_next → full → wr_bin_next`. QuestaSim caught this immediately (`vsim-3601`, iteration limit reached) because for certain pointer values this loop genuinely oscillates rather than settling to a stable value in the same time step.

**The fix**, matching the canonical Cummings design: `full`/`empty` are **registered** flip-flops, not pure combinational outputs.

```verilog
// full_logic.v
wire full_val;
assign full_val = (wr_gray_next == {~rd_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1],
                                      rd_gray_sync[ADDR_WIDTH-2:0]});
always @(posedge wr_clk or negedge wr_rst_n)
    if (!wr_rst_n) full <= 1'b0;
    else           full <= full_val;
```

Because `full` now only updates once per clock edge from an already-stable value, `wr_bin_next` can safely reference it again (`wr_bin + (wr_en & ~full)`) without creating a live feedback path — the register itself is what breaks the cycle.

## Tools

Simulated and verified in QuestaSim 10.7c.

## Author

Suryateja P — [GitHub](https://github.com/SURYATEJAP007)
