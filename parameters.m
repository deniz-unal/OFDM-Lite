%   Copyright 2024 Deniz Unal

%% Parameters
% Packet parameters
NFFT = 8192;        % FFT Size
BW = 125e3;         % Bandwidth (Hz)
ZP = 10e-3;         % Zero padding duration (s)
BPS = 1;            % Bits per sample (1:DBPSK, 2:DQPSK, ...)
t_lfm = 10e-3;      % LFM duration (s)
F_CENTER = 125e3;   % Center frequency of system (for Doppler comp)
NDATA = NFFT - 1;

%% Generate LFM
% Preamble is upchirp and postamble is downchirp
s_pre = chirp((1 / BW):(1 / BW):t_lfm, -BW / 2, t_lfm, BW / 2, ...
              'linear', 0, 'complex').';
s_post = chirp((1 / BW):(1 / BW):t_lfm, BW / 2, t_lfm, -BW / 2, ...
               'linear', 0, 'complex').';

%% Generate PN
% Configured for maximum length sequence r = 9. For other configurations,
% see https://www.mathworks.com/help/comm/ref/comm.pnsequence-system-object.html
mseq_gen = comm.PNSequence('Polynomial', [9 5 0], 'SamplesPerFrame', ...
                           2^9 - 1, 'InitialConditions', [1 zeros(1, 9 - 1)]);
s_pn = 2 * mseq_gen() - 1;

% Timing
k_zp = round(ZP * BW);              % ZP duration (samples)
k_pre = round(t_lfm * BW);          % LFM duration (samples)
k_pkt_gap = 5e4;                    % Gap between packets (samples)
k_packet = length(s_pre) + ...      % Packet length (pre to post correlation)
    k_zp + length(s_pn) + k_zp + NFFT + k_zp;
k_window = k_packet + k_pkt_gap;    % File read window
% fprintf("Packet duration: %d samples, %.2f ms\n", k_packet, k_packet/BW*1e3);

%% Generate data
rng('default');
d_data = randi([0 2^BPS - 1], NDATA, 1);
