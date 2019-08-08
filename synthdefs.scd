// My kinda bootup file

// Start SuperDirt with a reasonable memory size and an oscilloscope

(
s.options.memSize = 8192*8192*2;
SuperDirt.start;
s.scope;
)

// buffer for my waveshaper - handy to play with during performances

w = Buffer.alloc(s,1024,1);

(
w.cheby([0.5,1,3.75,0.2,0.2,1.45,1.0,0.8,2.5])
)

// record button - ALWAYS to keep in a place where you'll always see it

s.record('screcs/live-at-mastronauta-jul-2019.wav');

s.stopRecording

// "string" - an fm-sine wave with a comb filter on top -- wip

(
SynthDef(\stringtest, {
	arg out, sustain=1, pan = 0.5, note = 60, pitchval = 1, pitchenv = 0.01, detune = 1.00, gain = 0.25, tuning = 12, lobound = 0, upbound = 100000, envcurve = 3, fmfreq=1, fmamt=1, attpercent=0.01;
	var env, freq, sig, glide, octave, fm, precomb;
    env = EnvGen.ar(Env.linen(attpercent, 0.00, 0.99, gain, envcurve.neg), timeScale:sustain, doneAction:2);
	glide = XLine.kr(pitchval,1,pitchenv);
	note= note.wrap(lobound,upbound);
	octave = ((note/tuning)-5).trunc(1);
	freq = Select.kr (tuning < 1, [ 440 * (pow(2,octave)) * (pow(2,((mod(note,tuning))/tuning))) , note ]) ;
	freq= freq * detune * glide;
	fm = SinOsc.ar(freq*fmfreq, 0, fmamt);
    sig = SinOsc.ar(freq*fm, 0, env);
    Out.ar (0, Pan2.ar (sig, pan, 1));
}).add
);

// "plush" - a sine wave with a variable-curve envelope

(
SynthDef(\plush, {
	arg out, sustain=1, pan = 0.5, note = 60, pitchval = 1, pitchenv = 0.01, detune = 1.00, gain = 0.25, tuning = 12, lobound = 0, upbound = 100000, envcurve = 3, attpercent=0.01;
	var env, freq, sig, glide, octave;
    env = EnvGen.ar(Env.linen(attpercent, 0.00, 0.99, gain, envcurve.neg), timeScale:sustain, doneAction:2);
	glide = XLine.kr(pitchval,1,pitchenv);
	note= note.wrap(lobound,upbound);
	octave = ((note/tuning)-5).trunc(1);
	freq = Select.kr (tuning < 1, [ 440 * (pow(2,octave)) * (pow(2,((mod(note,tuning))/tuning))) , note ]) ;
	freq= freq * detune * glide;
    sig = SinOsc.ar(freq, 0, env);
    Out.ar (0, Pan2.ar (sig, pan, 1));
}).add
);

// "balloon" - a square wave with a complicated pitch envelope and three parallel bandpasses

(
SynthDef.new(\balloon, {
	arg notea = 48, noteb = 48, notec = 48, noted = 48, tuning = 12, envab = 0, envbc = 0, envcd = 0, gain = 0.3, pan = 0.5, bandpfa = 1, bandpfb = 1, bandpfc = 1, bandpqa = 1, bandpqb = 1, bandpqc = 1, bandpga = 1, bandpgb = 1, bandpgc = 1, upbound=1000000, lobound=1, sustain = 0.5, timescale = 1, ringmod = 0, ringenv = 10000, ringfreq = 1;
	var line, octavea, octaveb, octavec, octaved, freqa, freqb, freqc, freqd, path, env, filteda, filtedb, filtedc, sig, wave, ringline, ringed, unringed, prefilt;
	line = Line.kr (1,0,sustain * timescale,gain,0,2);
	notea = notea.wrap(lobound,upbound);
	octavea = ((notea/tuning)-5).trunc(1);
	freqa = Select.kr (tuning < 1, [ 440 * (pow(2,octavea)) * (pow(2,((mod(notea,tuning))/tuning))) , notea ]) ;
	noteb = noteb.wrap(lobound,upbound);
	octaveb = ((noteb/tuning)-5).trunc(1);
	freqb = Select.kr (tuning < 1, [ 440 * (pow(2,octaveb)) * (pow(2,((mod(noteb,tuning))/tuning))) , noteb ]) ;
	notec = notec.wrap(lobound,upbound);
	octavec = ((notec/tuning)-5).trunc(1);
	freqc = Select.kr (tuning < 1, [ 440 * (pow(2,octavec)) * (pow(2,((mod(notec,tuning))/tuning))) , notec ]) ;
	noted = noted.wrap(lobound,upbound);
	octaved = ((noted/tuning)-5).trunc(1);
	freqd = Select.kr (tuning < 1, [ 440 * (pow(2,octaved)) * (pow(2,((mod(noted,tuning))/tuning))) , noted ]) ;
	path = Env.new([freqa, freqb, freqc, freqd], [envab * timescale, envbc * timescale, envcd * timescale], \exp);
	env = EnvGen.ar (path);
	wave = LFPulse.ar (env);
	ringline = XLine.ar (env*ringfreq, env, ringenv*timescale);
	ringed = wave * (SinOsc.ar(ringline, 0, ringmod));
	unringed = wave * (1-ringmod);
	prefilt = ringed + unringed;
	filteda = (BBandPass.ar(prefilt, bandpfa * env, bandpqa) * bandpga);
	filtedb = (BBandPass.ar(prefilt, bandpfb * env, bandpqb) * bandpgb);
	filtedc = (BBandPass.ar(prefilt, bandpfc * env, bandpqc) * bandpgc);
	sig = ((filteda + filtedb + filtedc) / 3 * line);
	Out.ar (0, Pan2.ar (sig, pan, 1));
}).add
)

// "tunesharp" - a tuneable square wave with pitchenv and ringmod

(
SynthDef.new(\tunesharp, {
	arg note=48, sustain=0.03, pitchval=1.0, pitchenv=0.0, detune=1.00, gain=0.3, pan =0, ringenv=100000, ringfreq=0, ringmod=0, bandpq=1, bandpf=1, upbound=1000000, lobound=1, tuning=12, decay = 0.01;
	var gen, freq, ringed, unringed, ringline, prefilt, filted, octave, glide, filtenv;
        gen = Line.kr(1,0,sustain,gain,0,2);
	glide = XLine.kr(pitchval,1,pitchenv);
	note= note.wrap(lobound,upbound);
	octave = ((note/tuning)-5).trunc(1);
	freq = Select.kr (tuning < 1, [ 440 * (pow(2,octave)) * (pow(2,((mod(note,tuning))/tuning))) , note ]) ;
	freq= freq * detune * glide;
	filtenv = XLine.kr(freq*bandpf, freq, decay);
	ringline = XLine.ar (freq*ringfreq, freq, ringenv);
	ringed = (LFPulse.ar (freq) * gen) * (SinOsc.ar(ringline, 0, ringmod));
	unringed = (LFPulse.ar (freq) * gen) * (1-ringmod);
	prefilt = ringed + unringed;
	filted = BBandPass.ar(prefilt, filtenv, bandpq);
	Out.ar (0, Pan2.ar(filted,pan,1));
}).add
) 

// "tunesaw" - a tuneable sawtooth with ringmod and a waveshaper

(
SynthDef.new(\tunesaw, {
	arg note=48, sustain=0.03, detune=1.00, gain=0.3, pan =0, ringenv=100000, ringfreq=0, ringmod=0, lopq=1, lopf=20000, shaped=0, upbound=1000000, lobound=1, tuning=12;
	var sig, env, gen, freq, ringed, unringed, ringline, prefilt, filted, octave;
        gen = Line.kr(1,0,sustain,gain,0,2);
	note= note.wrap(lobound,upbound);
	octave = ((note/tuning)-5).trunc(1);
	freq = Select.kr (tuning < 1, [ 440 * (pow(2,octave)) * (pow(2,((mod(note,tuning))/tuning))) , note ]) ;
	freq= freq * detune;
	ringline = XLine.ar (freq*ringfreq, freq, ringenv);
	ringed = (LFSaw.ar (freq, 0, 1) * gen) * (SinOsc.ar(ringline, 0, ringmod));
	unringed = (LFSaw.ar (freq,0,1) * gen) * (1-ringmod);
	prefilt = ringed + unringed;
	filted = BLowPass.ar(prefilt, lopf, lopq);
	sig = (Shaper.ar(w, filted, shaped)) + (filted * (1 - shaped));
	Out.ar (0, Pan2.ar(sig,pan,1));
}).add
) 

// "supersaw" - a 12edo sawtooth with ringmod and a waveshaper

(
SynthDef.new(\supersaw, {
	arg note, sustain=0.03, detune=1.00, gain=0.3, pan =0, ringenv=100000, ringfreq=0, ringmod=0, lopq=1, lopf=20000, shaped=0, upbound=1000000, lobound=0;
	var sig, env, gen, freq, ringed, unringed, ringline, prefilt, filted;
        gen = Line.kr(1,0,sustain,gain,0,2);
	note= note.wrap(lobound,upbound);
	freq=(note.midicps) * detune;
	ringline = XLine.ar (freq*ringfreq, freq, ringenv);
	ringed = (LFSaw.ar (freq, 0, 1) * gen) * (SinOsc.ar(ringline, 0, ringmod));
	unringed = (LFSaw.ar (freq,0,1) * gen) * (1-ringmod);
	prefilt = ringed + unringed;
	filted = BLowPass.ar(prefilt, lopf, lopq);
	sig = (Shaper.ar(w, filted, shaped)) + (filted * (1 - shaped));
	Out.ar (0, Pan2.ar(sig,pan,1));
}).add
) 

// 4 channels

(
  s.options.numBuffers = 1024 * 256;
  s.options.memSize = 8192 * 16;
  s.options.maxNodes = 1024 * 32;
  s.options.numOutputBusChannels = 4; // total number of channels output
  s.options.numInputBusChannels = 2;

  s.waitForBoot {
      ~dirt = SuperDirt(4, s); // pan across four channels
      ~dirt.loadSoundFiles;
      ~dirt.start(57120, [0, 0, 0, 0, 0, 0]);
  };
  s.latency = 0.3;
  s.scope;
);
