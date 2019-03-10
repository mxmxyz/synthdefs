// My kinda bootup file

// Start SuperDirt with a reasonable memory size and an oscilloscope

(
s.options.memSize = 8192*8192;
SuperDirt.start;
s.scope;
)

// buffer for my waveshaper - handy to play with during performances

w = Buffer.alloc(s,1024,1);

(
w.cheby([0.5,1,3.75,0.2,0.2,1.45,1.0,0.8,2.5])
)

// record button - ALWAYS to keep in a place where you'll always see it

s.record('screcs/file-name.wav');

s.stopRecording

// "balloon" - a square wave with a complicated pitch envelope and three parallel bandpasses

(
SynthDef.new(\balloon, {
	arg notea = 48, noteb = 48, notec = 48, noted = 48, tuning = 12, envab = 0, envbc = 0, envcd = 0, gain = 0.3, pan = 0.5, bandpfa = 1, bandpfb = 1, bandpfc = 1, bandpqa = 1, bandpqb = 1, bandpqc = 1, bandpga = 1, bandpgb = 1, bandpgc = 1, upbound=1000000, lobound=1, sustain = 0.5, timescale = 1, ringmod = 0, ringenv = 10000, ringfreq = 1;
	var line, octavea, octaveb, octavec, octaved, freqa, freqb, freqc, freqd, path, env, filteda, filtedb, filtedc, sig, wave, ringline, ringed, unringed, prefilt;
	line = Line.kr (1,0,sustain * timescale,gain,0,2);
	notea = notea.wrap(lobound,upbound);
	octavea = ((notea/tuning)-5).trunc(1);
	freqa = 440 * (pow(2,octavea)) * (pow(2,((mod(notea,tuning))/tuning)));
	noteb = noteb.wrap(lobound,upbound);
	octaveb = ((noteb/tuning)-5).trunc(1);
	freqb = 440 * (pow(2,octaveb)) * (pow(2,((mod(noteb,tuning))/tuning)));
	notec = notec.wrap(lobound,upbound);
	octavec = ((notec/tuning)-5).trunc(1);
	freqc = 440 * (pow(2,octavec)) * (pow(2,((mod(notec,tuning))/tuning)));
	noted = noted.wrap(lobound,upbound);
	octaved = ((noted/tuning)-5).trunc(1);
	freqd = 440 * (pow(2,octaved)) * (pow(2,((mod(noted,tuning))/tuning)));
	path = Env.new([freqa, freqb, freqc, freqd], [envab * timescale, envbc * timescale, envcd * timescale], \exp);
	env = EnvGen.ar (path);
	wave = LFPulse.ar (env);
	ringline = XLine.ar (env*ringfreq, env, ringenv);
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
	arg note=48, sustain=0.03, pitchval=1.0, pitchenv=0.0, detune=1.00, gain=0.3, pan =0, ringenv=100000, ringfreq=0, ringmod=0, bandpq=1, bandpf=1, upbound=1000000, lobound=1, tuning=12;
	var gen, freq, ringed, unringed, ringline, prefilt, filted, octave, glide;
        gen = Line.kr(1,0,sustain,gain,0,2);
	glide = XLine.kr(pitchval,1,pitchenv);
	note= note.wrap(lobound,upbound);
	octave = ((note/tuning)-5).trunc(1);
	freq = 440 * (pow(2,octave)) * (pow(2,((mod(note,tuning))/tuning)));
	freq= freq * detune * glide;
	ringline = XLine.ar (freq*ringfreq, freq, ringenv);
	ringed = (LFPulse.ar (freq) * gen) * (SinOsc.ar(ringline, 0, ringmod));
	unringed = (LFPulse.ar (freq) * gen) * (1-ringmod);
	prefilt = ringed + unringed;
	filted = BBandPass.ar(prefilt, bandpf * freq, bandpq);
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
	freq = 440 * (pow(2,octave)) * (pow(2,((mod(note,tuning))/tuning)));
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
