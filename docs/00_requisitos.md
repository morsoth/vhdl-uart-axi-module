# Requisitos (fase UART RX)

- Clock sistema: 50 MHz (constante en simulación).
- UART: 8N1 (8 data, sin paridad, 1 stop).
- Baud: 115200.
- Oversampling: no (v1). (v2: x16 opcional).
- UART RX entrega:
  - rx_valid (pulso 1 ciclo cuando hay byte)
  - rx_data[7:0]
  - rx_frame_err (stop bit incorrecto)
- Reset: síncrono activo alto.
