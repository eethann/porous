PorousGate {

	var <porous_gate;

	*initClass {

		StartUp.add {
      // TODO should this be context instead
			var s = Server.default;
			var fbin_states, cbin_states;

			s.waitForBoot {

        SynthDef(\porous_gate, {
          arg in, out, slew_time = 0.01, gate_level = 0.0,
          freq_bin1_on = 1,
          freq_bin2_on = 1,
          freq_bin3_on = 1,
          freq_bin4_on = 1,
          freq_bin5_on = 1,
          freq_bin6_on = 1,
          freq_bin7_on = 1,
          freq_bin8_on = 1,
          freq_bin1_low = 100,
          freq_bin1_high = 150,
          freq_bin2_low = 200,
          freq_bin2_high = 300,
          freq_bin3_low = 400,
          freq_bin3_high = 600,
          freq_bin4_low = 800,
          freq_bin4_high = 1200,
          freq_bin5_low = 1600,
          freq_bin5_high = 2400,
          freq_bin6_low = 3200,
          freq_bin6_high = 4800,
          freq_bin7_low = 6400,
          freq_bin7_high = 9600,
          freq_bin8_low = 12800,
          freq_bin8_high = 19200;

          var in_sig, pitch, confidence, test;
          var fbins, cbins;

          // Stolen from CroneDefs (want both pitch and confidence)
          var initFreq = 440.0, minFreq = 30.0, maxFreq = 10000.0,
            execFreq = 50.0, maxBinsPerOctave = 16, median = 1,
            ampThreshold = 0.01, peakThreshold = 0.5, downSample = 2, clar=0;

          // Read input signal
          in_sig = In.ar(in, 2);

          // Get current pitch and confidence (either from bus or do it ourselves)
          # pitch, confidence = Pitch.kr(in_sig,
              initFreq , minFreq , maxFreq ,
              execFreq , maxBinsPerOctave , median ,
              ampThreshold , peakThreshold , downSample, clar
            );

          // Check to see if pitch falls within any of our bins
          fbins = [
            (pitch[0] >= freq_bin1_low) * (pitch[0] <= freq_bin1_high) * freq_bin1_on,
            (pitch[0] >= freq_bin2_low) * (pitch[0] <= freq_bin2_high) * freq_bin2_on,
            (pitch[0] >= freq_bin3_low) * (pitch[0] <= freq_bin3_high) * freq_bin3_on,
            (pitch[0] >= freq_bin4_low) * (pitch[0] <= freq_bin4_high) * freq_bin4_on,
            (pitch[0] >= freq_bin5_low) * (pitch[0] <= freq_bin5_high) * freq_bin5_on,
            (pitch[0] >= freq_bin6_low) * (pitch[0] <= freq_bin6_high) * freq_bin6_on,
            (pitch[0] >= freq_bin7_low) * (pitch[0] <= freq_bin7_high) * freq_bin7_on,
            (pitch[0] >= freq_bin8_low) * (pitch[0] <= freq_bin8_high) * freq_bin8_on];

          Out.kr(fbin_states, fbins);

          // Check to see if confidence falls within any of our bins
          // TODO
          // test = fbins.sum min: 1;

          // If so pass it through, if not, cut it off
          // TODO: (slew on/off through LPG like function)
          Out.ar(out, in_sig*test)
        }).add;


			} // s.waitForBoot
		} // StartUp
	} // *initClass

	*new {
		^super.new.init;  // ...run the 'init' below.
	}

	init {
		var s = Server.default;

    // fbin_states = Bus.control(8);
    // cbin_states = Bus.control(8);

		// create 'passthrough' using the 'inOut' SynthDef:
    // TODO adapt for class approach
    // porous_gate = Synth.new(\porous_gate, target: context.xg, args: [\in, context.in_b, \out, context.out_b], addAction: \addToTail);

		s.sync; // sync the changes above to the server
	}

	// create a command to control the synth's 'amp' value:
	// setAmp { arg amp;
	// 	passthrough.set(\amp, amp);
	// }

	// IMPORTANT!
	// free our synth after we're done with it:
  free {
    porous_gate.free;
    // fbin_states.free;
    // cbin_states.free;
  }

}
