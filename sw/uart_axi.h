#ifndef UART_AXI_H
#define UART_AXI_H

#include <stdint.h>

#define MMIO_AXI_BASE_ADDR 0x00000000

#define UART_CTRL_REG    0x00
#define UART_STATUS_REG  0x04
#define UART_TXDATA_REG  0x08
#define UART_RXDATA_REG  0x0C

// CTRL bits

#define UART_RX_EN   (1 << 0)
#define UART_TX_EN   (1 << 1)

// STATUS bits

#define UART_RX_RDY  (1 << 0)
#define UART_TX_RDY  (1 << 1)

// Low level MMIO operations

static inline void mmio_wr(uint32_t offset, uint32_t data) {
    *(volatile uint32_t *)(MMIO_AXI_BASE_ADDR + offset) = data;
}

static inline uint32_t mmio_rd(uint32_t offset) {
    return *(volatile uint32_t *)(MMIO_AXI_BASE_ADDR + offset);
}

// API

static inline void uart_init() {
    mmio_wr(UART_CTRL_REG, UART_RX_EN | UART_TX_EN);
}

static inline int uart_tx_ready() {
    return (mmio_rd(UART_STATUS_REG) & UART_TX_RDY) != 0;
}

static inline int uart_rx_ready() {
    return (mmio_rd(UART_STATUS_REG) & UART_RX_RDY) != 0;
}

static inline void uart_putc(uint8_t byte) {
    while (!uart_tx_ready()) {}

    mmio_wr(UART_TXDATA_REG, (uint32_t)byte);
}

static inline uint8_t uart_getc() {
    while (!uart_rx_ready()) {}

    return (uint8_t)(mmio_rd(UART_RXDATA_REG) & 0xFFu);
}

#endif