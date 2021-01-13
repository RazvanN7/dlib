/*
Copyright (c) 2016-2021 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

/**
 * Copyright: Timur Gafarov 2016-2021.
 * License: $(LINK2 boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Timur Gafarov
 */
module dlib.audio.synth;

import std.math;
import std.random;
import dlib.audio.sound;

/**
 * An interface for a synthesizer that maps sample position to -1..1 sample value
 */
interface Synth
{
    float eval(Sound sound, ulong position, float frequency);
}

/**
 * Sine wave synthesizer
 */
class SineWaveSynth: Synth
{
    float eval(Sound sound, ulong position, float frequency)
    {
        double samplePeriod = 1.0 / cast(double)sound.sampleRate;
        double time = position * samplePeriod;
        return sin(2.0 * PI * frequency * time);
    }
}

/**
 * Square wave synthesizer
 */
class SquareWaveSynth: Synth
{
    float eval(Sound sound, ulong position, float frequency)
    {
        double samplePeriod = 1.0 / cast(double)sound.sampleRate;
        double phase = position * samplePeriod * frequency;
        double s = 2.0 * floor(phase) - floor(2.0 * phase) + 1.0;
        return s * 2.0 - 1.0;
    }
}

/**
 * Sawtooth wave synthesizer
 */
class SawtoothWaveSynth: Synth
{
    float eval(Sound sound, ulong position, float frequency)
    {
        double samplePeriod = 1.0 / cast(double)sound.sampleRate;
        double phase = position * samplePeriod * frequency;
        double s = phase - floor(phase);
        return s * 2.0 - 1.0;
    }
}

/**
 * Triangle wave synthesizer
 */
class TriangleWaveSynth: Synth
{
    float eval(Sound sound, ulong position, float frequency)
    {
        double samplePeriod = 1.0 / cast(double)sound.sampleRate;
        double phase = position * samplePeriod * frequency;
        double s = abs(1.0 - fmod(phase, 2.0));
        return s * 2.0 - 1.0;
    }
}

/**
 * Frequency modulation synthesizer
 */
class FMSynth: Synth
{
    Synth carrier;
    Synth modulator;
    float frequencyRatio;

    this(Synth carrier, Synth modulator, float frequencyRatio)
    {
        this.carrier = carrier;
        this.modulator = modulator;
        this.frequencyRatio = frequencyRatio;
    }

    float eval(Sound sound, ulong position, float frequency)
    {
        float m = modulator.eval(sound, position, frequency * frequencyRatio);
        return carrier.eval(sound, position, frequency + m);
    }
}

// TODO: EnvelopeSynth

/**
 * Fill a given portion of a sound with a signal from specified synthesizer.
 * Params:
 *   sound = a sound object to write to
 *   channel = channel to fill (beginning from 0)
 *   synth = synthesizer object
 *   freq = synthesizer frequency
 *   startTime = start time of a signal in seconds
 *   duration = duration of a signal in seconds
 *   amplitude = volume coefficient of a signal
 */
void fillSynth(Sound sound, uint channel, Synth synth, float freq, double startTime, double duration, float amplitude)
{
    ulong startSample = cast(ulong)(startTime * sound.sampleRate);
    ulong endSample = startSample + cast(ulong)(duration * sound.sampleRate);
    if (endSample >= sound.size)
        endSample = sound.size - 1;

    foreach(i; startSample..endSample)
    {
        sound[channel, i] = synth.eval(sound, i - startSample, freq) * amplitude;
    }
}

/**
 * Additively mix a signal from specified synthesizer to a given portion of a sound.
 *   sound = a sound object to write to
 *   channel = channel to fill (beginning from 0)
 *   synth = synthesizer object
 *   freq = synthesizer frequency
 *   startTime = start time of a signal in seconds
 *   duration = duration of a signal in seconds
 *   amplitude = volume coefficient of a signal
 */
void mixSynth(Sound sound, uint channel, Synth synth, float freq, double startTime, double duration, float amplitude)
{
    ulong startSample = cast(ulong)(startTime * sound.sampleRate);
    ulong endSample = startSample + cast(ulong)(duration * sound.sampleRate);
    if (endSample >= sound.size)
        endSample = sound.size - 1;

    foreach(i; startSample..endSample)
    {
        float src = sound[channel, i];
        sound[channel, i] = src + synth.eval(sound, i - startSample, freq) * amplitude;
    }
}

/**
 * Generate random audio signal.
 *   snd = sound
 *   ch = channel to fill (beginning from 0)
 */
void whiteNoise(Sound snd, uint ch)
{
    foreach(i; 0..snd.size)
    {
        snd[ch, i] = uniform(-1.0f, 1.0f);
    }
}

/**
 * Fill the sound with simple sine wave tone.
 *   snd = sound
 *   ch = channel to fill (beginning from 0)
 *   freq = frequency in Hz. For example, a dial tone in Europe is usually 425 Hz
 */
void sineWave(Sound snd, uint ch, float freq)
{
    float samplePeriod = 1.0f / cast(float)snd.sampleRate;
    foreach(i; 0..snd.size)
    {
        snd[ch, i] = sin(samplePeriod * i * freq * 2.0f * PI);
    }
}
