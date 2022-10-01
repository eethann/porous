Porous_passthrough {

	// An adaption of dan derks and jaceknighter's Habitus passthrough app
	// supports independent stereo control of passthrough for stereo gating

	var <passthrough;

	*initClass {

		StartUp.add {
      // TODO should this be context instead
			var s = Server.default;

			s.waitForBoot {

				SynthDef(\porousPassthrough, {
					arg amp1 = 1,
					amp2 = 1;
					var sound;
					// TODO declick
					sound = SoundIn.ar([0,1]);
					// ReplaceOut.ar(0, [sound[0] * amp1, sound[1] * amp2]);
					Out.ar(0, sound.madd([amp1, amp2]));
				}).add;

			} // s.waitForBoot
		} // StartUp
	} // *initClass

	*new {
		^super.new.init;  // ...run the 'init' below.
	}

	init {
		var s = Server.default;

		// create 'passthrough' using the 'inOut' SynthDef:
		passthrough = Synth.new(\porousPassthrough, [
			\amp1, 1,
			\amp2, 1
		]);

		s.sync; // sync the changes above to the server
	}

	// create a command to control the synth's 'amp' value:
	setAmp1 { arg amp;
		passthrough.set(\amp1, amp);
	}

	setAmp2 { arg amp;
		passthrough.set(\amp2, amp);
	}

	// IMPORTANT!
	// free our synth after we're done with it:
	free {
		passthrough.free;
	}

}
