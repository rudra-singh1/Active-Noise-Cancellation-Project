%Project: Active Noise Cancellation Algorithm for Leaf Blowers
%Using Filtered-X LMS FIR Adaptive Filter
%Developed by Rudra Prakash Singh

%Code built upon this documentation:https://www.mathworks.com/help/audio/ug
%/active-noise-control-using-a-filtered-x-lms-fir-adaptive-filter.html#:~
%:text=The%20most%20popular%20adaptive%20algorithm%20for%20active%20noise
%,error%20sensor%20destructively%20interferes%20with%20the%20undesired%
%20noise.

%Secondary Propagation Path - generate loudspeaker to error microphone
%impulse response with specified conditions
Fs     = 8e3;  % 8 kHz
N      = 800;  % 800 samples@8 kHz = 0.1 seconds
Flow   = 160;  % Lower band-edge: 160 Hz
Fhigh  = 2000; % Upper band-edge: 2000 Hz
delayS = 7;
Ast    = 100;   % 100 dB stopband attenuation
Nfilt  = 8;    % Filter order

% Design bandpass filter to generate bandlimited impulse response
filtSpecs = fdesign.bandpass('N,Fst1,Fst2,Ast',Nfilt,Flow,Fhigh,Ast,Fs);
bandpass = design(filtSpecs,'cheby2','FilterStructure','df2tsos', ...
    'SystemObject',true);

% Filter noise to generate impulse response
secondaryPathCoeffsActual = bandpass([zeros(delayS,1); ...
                       log(0.99*rand(N-delayS,1)+0.01).* ...
                       sign(randn(N-delayS,1)).*exp(-0.01*(1:N-delayS)')]);
secondaryPathCoeffsActual = ...
    secondaryPathCoeffsActual/norm(secondaryPathCoeffsActual);

t = (1:N)/Fs;
plot(t,secondaryPathCoeffsActual,'b');
xlabel('Time [sec]');
ylabel('Coefficient value');
title('True Secondary Path Impulse Response');


%Estimating the Secondary Propagation Path - generating random noise to
%account for unwanted noise in algorithm
ntrS = 30000;
randomSignal = randn(ntrS,1); % Synthetic random signal to be played
secondaryPathGenerator = dsp.FIRFilter('Numerator',secondaryPathCoeffsActual.');
secondaryPathMeasured = secondaryPathGenerator(randomSignal) + ... % random signal propagated through secondary path
    0.01*randn(ntrS,1); % measurement noise at the microphone


%Designing the Secondary Propagation Path Estimate-plot showing algorithm
%converges after about 1000 iterations or so
M = 250;
muS = 0.1;
secondaryPathEstimator = dsp.LMSFilter('Method','Normalized LMS','StepSize', muS, ...
    'Length', M);   
[yS,eS,SecondaryPathCoeffsEst] = secondaryPathEstimator(randomSignal,secondaryPathMeasured);

n = 1:ntrS;
figure, plot(n,secondaryPathMeasured,n,yS,n,eS);
xlabel('Number of iterations');
ylabel('Signal value');
title('Secondary Identification Using the NLMS Adaptive Filter');
legend('Desired Signal','Output Signal','Error Signal');


%Accuracy of Secondary Path Estimate - plot showing coefficients of true &
%estimated path
figure, plot(t,secondaryPathCoeffsActual, ...
    t(1:M),SecondaryPathCoeffsEst, ...
    t,[secondaryPathCoeffsActual(1:M)-SecondaryPathCoeffsEst(1:M); secondaryPathCoeffsActual(M+1:N)]);
xlabel('Time [sec]');
ylabel('Coefficient value');
title('Secondary Path Impulse Response Estimation');
legend('True','Estimated','Error');


%The Primary Propagation Path - generate impulse to error microphone
%response
delayW = 15;
Flow   = 200; % Lower band-edge: 200 Hz
Fhigh  = 800; % Upper band-edge: 800 Hz
Ast    = 20;  % 20 dB stopband attenuation
Nfilt  = 10;  % Filter order

% Design bandpass filter to generate bandlimited impulse response
filtSpecs2 = fdesign.bandpass('N,Fst1,Fst2,Ast',Nfilt,Flow,Fhigh,Ast,Fs);
bandpass2 = design(filtSpecs2,'cheby2','FilterStructure','df2tsos', ...
    'SystemObject',true);

% Filter noise to generate impulse response
primaryPathCoeffs = bandpass2([zeros(delayW,1); log(0.99*rand(N-delayW,1)+0.01).* ...
    sign(randn(N-delayW,1)).*exp(-0.01*(1:N-delayW)')]);
primaryPathCoeffs = primaryPathCoeffs/norm(primaryPathCoeffs);

figure, plot(t,primaryPathCoeffs,'b');
xlabel('Time [sec]');
ylabel('Coefficient value');
title('Primary Path Impulse Response');


%Initialization of Active Noise Control - setting up parameters for LMS
%algorithm
% FIR Filter to be used to model primary propagation path
primaryPathGenerator = dsp.FIRFilter('Numerator',primaryPathCoeffs.');

% Filtered-X LMS adaptive filter to control the noise
L = 350;
muW = 0.0001;
noiseController = dsp.FilteredXLMSFilter('Length',L,'StepSize',muW, ...
    'SecondaryPathCoefficients',SecondaryPathCoeffsEst);

% Sine wave generator to synthetically create the noise

%A-sampled audio data
%Fo-sample rate
%Make sure m4 file is loaded into MATLAB before running code or will give
%errors
[A, Fo] = audioread("Exp B moving front yard.m4a"); 
indx = find(A==0);
A(1:1:indx(end)) = [];% removing zeroes from sampled data to train filter
%more efficiently
newFo = round(length(A)/199);
finalAudioVal = zeros(1,199);
runTicker = 1;
startTick = 1;
endTick = startTick+newFo;
%This loop takes an increment of data in audio sample. Takes mean of that
%increment. Stores mean as first index of 1x199 vector. Repeats. Needed to do this 
%as audiooscillator won't allow more than 200 points to be trained at once.
%Taking mean at set increments allows for algorithm to train for complete
%audio signal duration rather than first 200 sampled audio signal values.
for m = runTicker:199
    if runTicker >= 2
        startTick = startTick + newFo;
        endTick = endTick + newFo;
    end
    r = A(startTick) + (A(endTick)-A(startTick)).*rand(round((newFo)),1);
    meanMinVal = mean(r);
    if meanMinVal < 0
        meanMinVal = -(meanMinVal);
    end
    finalAudioVal(runTicker) = meanMinVal;
    runTicker = runTicker + 1;
end
A1 = finalAudioVal;
La = length(A1);
k = 1:La;
F = Fo*k;
phase = rand(1,La); % Random initial phase
sine = audioOscillator("NumTones", 200, "Amplitude",abs(A1),"Frequency",F, "PhaseOffset",...
phase,"SamplesPerFrame",1500,"SampleRate",Fs);

% Audio player to play noise before and after cancellation
player = audioDeviceWriter('SampleRate',Fs);

% Spectrum analyzer to show original and attenuated noise
scope = dsp.SpectrumAnalyzer('SampleRate',Fs,'OverlapPercent',80, ...
    'SpectralAverages',20,'PlotAsTwoSidedSpectrum',false, ...
    'ShowLegend',true, ...
    'ChannelNames', {'Original noisy signal', 'Attenuated noise'});

%Simulation of Active Noise Control Using the Filtered-X LMS Algorithm
for m = 1:650
    if (m > 1 && m < 200)
        % Generate synthetic noise by adding sine waves with random phase
        x = sine();
        d = primaryPathGenerator(x) + ...  % Propagate noise through primary path
        0.1*randn(size(x)); % Add measurement noise
        xhat = x + 0.1*randn(size(x));
        [y,e] = noiseController(xhat,d);
        player(y);  
        scope([d,e]); % Show spectrum of original (Channel 1)
                      % and attenuated noise (Channel 2)
                      % & scope will play cancellation (ie. "bzz") noise
                      
                      
    end
end
release(player); %#ok<*UNRCH> % Release audio device
release(scope); % Release spectrum analyzer
