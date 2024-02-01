%   Copyright 2024 Deniz Unal

filename = "packet.dat";

%% Load parameters
parameters;

s_zp = zeros(k_zp, 1);

%% Generate OFDM
modulator = comm.DPSKModulator('ModulationOrder', 2^BPS, ...
                               'SymbolMapping', 'Gray', ...
                               'PhaseRotation', 0);
s_ofdm = ifft(modulator([0; d_data]), NFFT);
s_ofdm = s_ofdm ./ max(abs(s_ofdm));

%% Generate packet
s_bb = vertcat(s_pre, s_zp, s_pn, s_zp, s_ofdm, s_zp, s_post, ...
               zeros(k_pkt_gap, 1));

%% Write packet to file
fid = fopen(filename, 'wb');
s_bb_iq = [real(s_bb) imag(s_bb)].';
fwrite(fid, s_bb_iq(:), 'float');
fclose(fid);
