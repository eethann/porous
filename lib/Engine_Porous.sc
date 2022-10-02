Engine_Porous : CroneEngine {
	var kernel, debugPrinter;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		kernel = Porous_passthrough.new(Crone.server);

		this.addCommand(\amp1, "f", { arg msg;
			var amp1 = msg[1].asFloat;
			kernel.setAmp1(amp1);
		});

		this.addCommand(\amp2, "f", { arg msg;
			var amp2 = msg[1].asFloat;
			kernel.setAmp2(amp2);
		});

		this.addCommand(\slew_time_up, "f", { arg msg;
			var slew_time = msg[1].asFloat;
			kernel.setSlewTimeUp(slew_time);
		});

		this.addCommand(\slew_time_down, "f", { arg msg;
			var slew_time = msg[1].asFloat;
			kernel.setSlewTimeDown(slew_time);
		});

		// debugPrinter = { loop { [context.server.peakCPU, context.server.avgCPU].postln; 3.wait; } }.fork;
	}

	free {
		kernel.free;
		// debugPrinter.stop;
	}
}