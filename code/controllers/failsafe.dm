var/datum/controller/failsafe/Failsafe

/datum/controller/failsafe // This thing pretty much just keeps poking the master controller
	var/name = "Failsafe"
	var/processing_interval = 100	//poke the MC every 10 seconds - set to 0 to disable
	var/MC_iteration = 0
	var/MC_defcon = 0			//alert level. For every poke that fails this is raised by 1. When it reaches 5 the MC is replaced with a new one. (effectively killing any master_controller.process() and starting a new one)

	var/obj/effect/statclick/statclick // clickable stat button

/datum/controller/failsafe/New()
	//There can be only one failsafe. Out with the old in with the new (that way we can restart the Failsafe by spawning a new one)
	if(Failsafe != src)
		if(istype(Failsafe))
			qdel(Failsafe)
	Failsafe = src
	Failsafe.process()


/datum/controller/failsafe/process()
	spawn(0)
		while(1)	//more efficient than recursivly calling ourself over and over. background = 1 ensures we do not trigger an infinite loop
			if(!master_controller)
				new /datum/controller/game_controller()	//replace the missing master_controller! This should never happen.

			if(processing_interval > 0)
				if(master_controller.processing_interval > 0)	//only poke if these overrides aren't in effect
					if(MC_iteration == master_controller.iteration)	//master_controller hasn't finished processing in the defined interval
						switch(MC_defcon)
							if(0 to 3)
								++MC_defcon
							if(4)
								admins << "<font color='red' size='2'><b>Warning. The Master Controller has not fired in the last [MC_defcon*processing_interval] ticks. Automatic restart in [processing_interval] ticks.</b></font>"
								MC_defcon = 5
							if(5)
								admins << "<font color='red' size='2'><b>Warning. The Master Controller has still not fired within the last [MC_defcon*processing_interval] ticks. Killing and restarting...</b></font>"
								new /datum/controller/game_controller()	//replace the old master_controller (hence killing the old one's process)
								master_controller.process()				//Start it rolling again
								MC_defcon = 0
					else
						MC_defcon = 0
						MC_iteration = master_controller.iteration
				sleep(processing_interval)
			else
				MC_defcon = 0
				sleep(100)

/datum/controller/failsafe/proc/stat_entry()
	if(!statclick)
		statclick = new/obj/effect/statclick/debug("Initializing...", src)

	stat("Failsafe Controller:", statclick.update("Defcon: [Failsafe.MC_defcon] (Interval: [Failsafe.processing_interval] | Iteration: [Failsafe.MC_iteration])"))
