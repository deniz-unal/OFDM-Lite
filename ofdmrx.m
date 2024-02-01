%   Copyright 2024 Deniz Unal

filename = "packet.dat";

% Receiver detection thresholds
LFM_THRESH = 100;
PN_THRESH = 100;

%% Load parameters
parameters;

%% Correlator objects
predet = comm.PreambleDetector(s_pre, "Threshold", LFM_THRESH);
postdet = comm.PreambleDetector(s_post, "Threshold", LFM_THRESH);
pndet = comm.PreambleDetector(s_pn, "Threshold", PN_THRESH);

%% Load from file
fid = fopen(filename, 'rb');
if fid < 0; error("Unable to open file"); end

while true
    %% Read file
    r_bb = fread(fid, [2, k_window], 'float');
    if isempty(r_bb) || (length(r_bb) < k_packet); break; end
    r_bb = (r_bb(1, :) + r_bb(2, :) * 1i).';

    %% Packet detection
    idx_pre_e = detectPeak(r_bb, predet);
    idx_post_e = detectPeak(r_bb, postdet);

    %% Check detection and window alignment
    if isempty(idx_pre_e)
        % No packet found
        % Rewind file in case preamble is cut at the end
        fseek(fid, -k_pre * 8, 0);
        continue;
    elseif isempty(idx_post_e)
        % Preamble detected but postamble not found
        % Reposition file
        fseek(fid, -(length(r_bb) - (idx_pre_e - k_pre)) * 8, 0);
        continue;
    end

    %% Doppler compensation
    % Calculate resampling factor
    a = k_packet / (idx_post_e - idx_pre_e);
    % Resample at passband
    r_bb = r_bb .* exp(1i * 2 * pi * F_CENTER * ...
                       (0:1 / BW:(length(r_bb) - 1) / BW).');
    r_bb = interp1(linspace(0, 1, length(r_bb))', r_bb, ...
                   linspace(0, 1, length(r_bb) * a)', 'makima');
    r_bb = r_bb .* exp(-1i * 2 * pi * F_CENTER * ...
                       (0:1 / BW:(length(r_bb) - 1) / BW).');

    %% Packet synchronization
    idx_pn_e = detectPeak(r_bb, pndet);

    %% Extract symbol samples
    idx_ofdm_b = idx_pn_e + k_zp + 1;
    r_ofdm = r_bb(idx_ofdm_b:(idx_ofdm_b + NFFT - 1));

    %% Receive OFDM
    r_ofdm = fft(r_ofdm, NFFT);
    demodulator = comm.DPSKDemodulator('ModulationOrder', 2^BPS, ...
                                       'SymbolMapping', 'Gray', ...
                                       'PhaseRotation', 0);
    d_recv = demodulator(r_ofdm);
    d_recv = d_recv(2:end);

    %% Calculate bit error rate
    [~, ber] = biterr(d_recv, d_data, BPS);
    fprintf('%.5f\n', ber);

end

fclose(fid);

%% Find max peak above threshold
function idx = detectPeak(r, fun)
    [peak_idx, det_metric] = fun(r);
    [~, max_idx] = max(det_metric(peak_idx));
    idx = peak_idx(max_idx);
end
