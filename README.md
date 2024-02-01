# OFDM-Lite

A minimal working example of a baseband Zero-Padded Orthogonal Frequency Division Multiplexing (ZP-OFDM) transceiver implemented in MATLAB.
This concise project offers limited yet easily configurable functionality.  It is intended for underwater acoustic communication links.

## Implementation

- The packet structure consists of a LFM, PN, OFDM, LFM with guard intervals in between.
- The LFM preamble-postamble pair is used for Doppler compensation.
- PN block is used for synchronization.
- OFDM subcarriers are loaded with differentially coherent PSK symbols.
- Payload is generated with PRNG.
- The code expects baseband samples at system bandwidth rate, if other sample rates are required on transmit or receive side, multirate dsp functions can be used (interpolation and decimation).
- Input/output files consist of complex I/Q data arranged in interleaved 32-bit floats. It is compatible with GNU Radio file blocks and Numpy complex64 type.

## Files

- parameters.m

    Common parameters

- ofdmtx.m

    Generates a baseband packet

- ofdmrx.m

    Receives a recording from file and outputs bit error rates for each packet
