# UART Register Map (32-bit)

## Conventions
- All registers are **32-bit** wide.
- Offsets are **byte offsets** from `BASE_ADDR`.
- Reserved bits read as **0**. Writes to reserved bits are ignored.

## 0x00 — CTRL
Control register.

| Bit | Name  | R/W | Description |
|-----|-------|-----|-------------|
| 1   | TX_EN | RW  | TX enable. If `1`, writes to `TXDATA` will **push** the data to TX FIFO. |
| 0   | RX_EN | RW  | RX enable. If `1`, reads from `RXDATA` will **pop** the data from RX FIFO. |

**Reset value:** `RX_EN=1`, `TX_EN=1`

## 0x04 — STATUS
Live status register.

| Bit | Name         | R/W | Description |
|-----|--------------|-----|-------------|
| 1   | TX_NOT_FULL  | R   | `1` when TX FIFO can accept a byte. |
| 0   | RX_NOT_EMPTY | R   | `1` when a received byte is available. |

## 0x08 — TXDATA
Transmit data register (byte write).

| Bit | Name     | R/W | Description |
|-----|----------|-----|-------------|
| 7:0 | TX_BYTE  | W   | Byte to transmit. A push occurs **only if** `CTRL.TX_EN=1` and `STATUS.TX_NOT_FULL=1`. |

**Notes:**
- If TX is disabled or FIFO is full, the write is ignored.

## 0x0C — RXDATA
Receive data register (byte read).

| Bit | Name     | R/W | Description |
|-----|----------|-----|-------------|
| 7:0 | RX_BYTE  | R   | Received byte. A pop occurs **only if** `CTRL.RX_EN=1` and `STATUS.RX_NOT_EMPTY=1`. |

**Notes:**
- If RX is disabled or FIFO is empty, reads return 0 (and do not pop).

## Future work

* Implement sticky flags: `RX_UNDERFLOW` and `TX_OVERFLOW`.
* Implement counters: `RX_COUNT` and `TX_COUNT`.
* Implement IRQ: `RX_NOT_EMPTY`.
