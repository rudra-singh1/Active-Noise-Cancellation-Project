# Active Noise Cancellation Project for Leaf Blowers

This project aimed to develop an active noise cancellation (ANC) algorithm to reduce the noise from leaf blowers. The goal was to improve sleep quality by cancelling out the 102-112 dB noise from leaf blowers. Developed by Rudra Prakash Singh in collaboration with Dr. Ashwin Ashok of the MORSE Lab at Georgia State University.

## Background

- Leaf blowers generate 102-112 dB of noise, enough to disrupt sleep cycles.
- Active noise cancellation uses destructive interference to cancel unwanted noise.
- This project used an adaptive filter algorithm to suppress leaf blower noise.

## Data Collection

- Collected 40 million audio data points from leaf blower experiments.
- Recorded 16 2-minute audio samples using an iPhone:
  - 8 samples for a stationary leaf blower, 8 for a moving leaf blower.
- Tested leaf blower on all 4 sides of a house.
- Additional recordings taken at 4 unique outdoor locations.

## Data Analysis

- Analyzed audio signals using power spectrum graphs in MATLAB.
- Noise exhibited 80-100 dB power across 100-8000 Hz frequency range.
- Tested 5 predictive models and 3 ML classifiers for noise trends.

## Algorithm Development

- Implemented a Filtered-X LMS FIR adaptive filter in MATLAB.
- Preprocessed data into 200-sample means from recordings.
- Trained filter on chunks, played cancellation noise, and repeated.
- Achieved 92% noise suppression accuracy after parameter tuning.

## Results

- Algorithm cancelled leaf blower noise from recordings.
- Output cancellation noise reduced noise without disruption.
- Physical limitations prevent >50% suppression in real environments.

## Conclusion

- The filter algorithm achieved 92% accuracy in suppressing leaf blower noise in controlled tests.
- Further work on robustness is needed before real-world deployment.

## Installation

To use this leaf blower noise cancellation algorithm:

1. Install MATLAB on your machine.
2. Clone this repository.
3. Open `ANC.m` in MATLAB.
4. Update the `audio_file` variable with your leaf blower recording.
5. Run the script to preprocess data and train the filter.
6. Listen to cancellation noise output!
