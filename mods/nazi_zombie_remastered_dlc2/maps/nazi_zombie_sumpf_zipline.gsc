#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;


/////////////////////////////////////////////////////////
// Zipline - Easy Access Route to Hut
/////////////////////////////////////////////////////////
	
initZipline ()
{
	zipBuyTrigger = getentarray("zipline_buy_trigger", "targetname");
	nonstatictrig = undefined;
	statictrig = undefined;
	level.direction = undefined;
	level.znodes = [];
	level.zrnodes = [];
	level.zipinuse = false;
	
	for (i=0; i<zipBuyTrigger.size; i++)
	{
		zipBuyTrigger[i].zip = getent(zipBuyTrigger[i].target, "targetname");
		zipBuyTrigger[i].attachspot = getentarray((zipBuyTrigger[i].zip).target, "targetname");
		zipBuyTrigger[i].blocker = getent("zipline_blocker", "targetname");
		zipBuyTrigger[i].aiblocker = getent("zipline_ai_blocker", "targetname");
		zipBuyTrigger[i].tempclip = getentarray("zip_temp_clip", "targetname");
		zipBuyTrigger[i].handle = getent("zip_handle", "targetname");
		//zipBuyTrigger[i].handleorg = getent("zip_handle_origin", "targetname");		
		zipBuyTrigger[i].handlebox = getent("zip_handle_box", "targetname");	
		zipBuyTrigger[i].lever = getent("zip_lever", "targetname");
	
		for (p=0; p < (zipBuyTrigger[i].attachspot).size; p++)
		{
			if (IsDefined((zipBuyTrigger[i].attachspot[p]).script_noteworthy) && (zipBuyTrigger[i].attachspot[p]).script_noteworthy == "main_spot")
			{
				zipBuyTrigger[i].volume = getent((zipBuyTrigger[i].attachspot[p]).target, "targetname");
				zipBuyTrigger[i].zipDamageTrigger = getent((zipBuyTrigger[i].volume).target, "targetname");
				zipBuyTrigger[i].zipDamageVolume = getent((zipBuyTrigger[i].zipDamageTrigger).target, "targetname");
				zipBuyTrigger[i].spline = getent((zipBuyTrigger[i].zipDamageVolume).target, "targetname");
			}
		}
		
		//need to figure out which trigger is the one attached to the zipline
		if (IsDefined(zipBuyTrigger[i].script_noteworthy) && zipBuyTrigger[i].script_noteworthy == "nonstatic")
		{
			nonstatictrig = zipBuyTrigger[i];
		}
		else if (IsDefined(zipBuyTrigger[i].script_noteworthy) && zipBuyTrigger[i].script_noteworthy == "static")
		{
			statictrig = zipBuyTrigger[i];
		}
		
		level.znodes = getentarray("zipline_nodes", "script_noteworthy");
		level.zrnodes = [];
		
		//the trigger shouldn't display anything until the zipline comes down
		zipBuyTrigger[i] SetCursorHint("HINT_NOICON");
	}
	
	//mobile buy trigger is linked to the zipline
	nonstatictrig EnableLinkTo ();
	nonstatictrig LinkTo (nonstatictrig.zip);
	
	//the static buy trigger needs to be turned off to prevent overlapping triggers
	statictrig trigger_off();
	
	//volume is linked to the zipline
	zipBuyTrigger[0].volume EnableLinkTo();
	zipBuyTrigger[0].volume LinkTo (zipBuyTrigger[0].zip);
	
	//damage trigger is linked to the zipline
	zipBuyTrigger[0].zipDamageTrigger EnableLinkTo();
	zipBuyTrigger[0].zipDamageTrigger LinkTo (zipBuyTrigger[0].zip);
	
	//damage volume is linked to the zipline
	zipBuyTrigger[0].zipDamageVolume EnableLinkTo();
	zipBuyTrigger[0].zipDamageVolume LinkTo (zipBuyTrigger[0].zip);
	
	//attach spots are linked to the zipline
	for (i=0; i < (zipBuyTrigger[0].attachspot).size; i++)
	{
		zipBuyTrigger[0].attachspot[i] LinkTo (zipBuyTrigger[0].zip);
	}
	
	//temp clip for the model itself
	for (i=0; i < (zipBuyTrigger[0].tempclip).size; i++)
	{
		zipBuyTrigger[0].tempclip[i] LinkTo (zipBuyTrigger[0].zip);
	}
	
	//bind and offset the handle
	zipBuyTrigger[0].handlebox LinkTo (zipBuyTrigger[0].zip);
	(zipBuyTrigger[0].handle).angles = (0, -19.6, 0);
	
	//set up power up zip trigger
	zipPowerTrigger = getent("zip_lever_trigger", "targetname");
	zipPowerTrigger.lever = getent(zipPowerTrigger.target, "targetname");
	zipPowerTrigger sethintstring(&"REMASTERED_ZOMBIE_ZIPLINE_ACTIVATE");
	
	//wait until powered up
	zipPowerTrigger waittill("trigger", who);
	zipPowerTrigger sethintstring("");
	zipPowerTrigger SetCursorHint("HINT_NOICON");

	zipHintDeactivated = getent("zipline_deactivated_hint_trigger", "targetname");
	zipHintDeactivated delete();
	
	//wait for activation
	zipPowerTrigger thread recallZipSwitch(180);
	zipPowerTrigger.lever playsound("switch");		
	zipPowerTrigger waittill("recallLeverDone");
	
	who thread play_zipline_dialog();
	
	zipPowerTrigger delete ();
	
	//really don't want to make the trigger on the switch (on the pole) multi-purpose
	statictrig thread activateZip(undefined);
	statictrig waittill ("zipDone");
	statictrig playsound ("platform_bang");
	
	//swing the gate open
	zipBuyTrigger[0].blocker connectpaths();
	zipBuyTrigger[0].blocker notsolid(); 	
	play_sound_at_pos( "door_rotate_open", (zipBuyTrigger[0].blocker).origin );
	zipBuyTrigger[0].blocker rotateyaw(80, 1 ); 
	//zipBuyTrigger[0].blocker playsound("door_rotate_open");
	zipBuyTrigger[0].blocker waittill ("rotatedone");
	zipBuyTrigger[0].blocker thread objectSolid(); 	
	
	//waittime = 40;
	waittime = 15; // initial waittime is half of normal cooldown, first time use
					
	/#
		if ( GetDVarInt( "zombie_cheat" ) > 0 )
		{
			waittime = 5;
		}
	#/
	statictrig thread recallZipSwitch (-180);
	statictrig.lever playsound("switch_up");		
	statictrig waittill ("recallLeverDone");

	wait (waittime);	
	
	statictrig.lever playsound("amb_sparks");	// ready sound	

	//zipline can now be used
	array_thread (zipBuyTrigger,::zipThink);
}	

zip_rope_audio()
{
	zip_rope =  getentarray("zip_line_rope", "targetname");
	
	for(i=0;i<zip_rope.size;i++)
	{
		if(IsDefined(zip_rope[i].script_sound))
		{			
			zip_rope[i] thread rope_sounds();
		}
	}	
}
zip_line_audio()
{
	level thread zip_rope_audio();
	zip_audio = getentarray("zip_line_wheel", "targetname");
	
	for(i=0;i<zip_audio.size;i++)
	{

		if(IsDefined(zip_audio[i].script_label))
		{
			zip_audio[i] playsound(zip_audio[i].script_label);
			
		}		
		if(IsDefined(zip_audio[i].script_sound))
		{			
			zip_audio[i] playloopsound(zip_audio[i].script_sound, 1);
		}
		zip_audio[i] thread zip_line_stopsound();
		
	}	

}
rope_sounds()
{
	level endon ("machine_off");
	while(1)
	{
		wait(randomfloatrange(0.3, 0.8));
		self playsound(self.script_sound);	
		
	}
	
}

zip_line_stopsound()
{
	level waittill("machine_off");
	self stoploopsound(0.1);
	
	if(IsDefined(self.script_label))
	{
		self playsound ("motor_stop_left");	
	}	
}

play_zipline_dialog()
{
	waittime = 0.12;
	
	index = maps\_zombiemode_weapons::get_player_index(self);
	player_index = "plr_" + index + "_";
	
	
	if(!IsDefined (self.vox_zipline))
	{
		num_variants = maps\_zombiemode_spawner::get_number_variants(player_index + "vox_zipline");
		//iprintlnbold(num_variants);
		self.vox_zipline = [];
		for(i=0;i<num_variants;i++)
		{
			self.vox_zipline[self.vox_zipline.size] = "vox_zipline_" + i;
			//iprintlnbold("vox_kill_headdist_" + i);	
		}
		self.vox_zipline_available = self.vox_zipline;
	}
		sound_to_play = random(self.vox_zipline_available);
		//iprintlnbold("LINE:" + player_index + sound_to_play);
		
		self maps\_zombiemode_spawner::do_player_playdialog(player_index, sound_to_play, waittime);
		self.vox_zipline_available = array_remove(self.vox_zipline_available,sound_to_play);
	
		if (self.vox_zipline_available.size < 1 )
		{
			self.vox_zipline_available = self.vox_zipline;
		}	
	
}

recallZipSwitch(dir)
{
	self.lever rotatepitch( dir, .5 );
/*	org = getent("zip_line_switch","targetname");
	if(IsDefined(org))
	{
		playsoundatposition ("purchase", org.origin);
		org playsound("switch");		
	}*/
	
	self.lever waittill ("rotatedone");
	
	self notify ("recallLeverDone");
}

zipThink()
{	
	self sethintstring(&"ZOMBIE_ZIPLINE_USE");
	self SetCursorHint("HINT_NOICON");
	self.zombie_cost = 1500;
	//self.in_use = 0;
	zipBuyTrigger = getentarray("zipline_buy_trigger", "targetname");
	//self UseTriggerRequireLookAt();
	
	//ok, the fact that one trigger needs to be unbound and moved to accomodate the revive hint is going to make this awful
	if (IsDefined(self.script_noteworthy) && self.script_noteworthy == "nonstatic")
	{
		self.triggeron = true;
	
		//make sure the hintstring for the zipline doesn't override the revive hint
		self unlink();
		self thread monitorZipHint();
	}
	
	while(1)
	{
		self waittill( "trigger", who );
		
		if( who in_revive_trigger() )
		{
			continue;
		}
				
		if( is_player_valid( who ) )
		{
			if( who.score >= self.zombie_cost)
			{	
				if(!level.zipinuse)
				{
					//if your using the trigger in the zipline, you need to be in the volume		
					if (IsDefined(self.script_noteworthy) && self.script_noteworthy == "nonstatic" && who IsTouching(self.volume) || 
						IsDefined(self.script_noteworthy) && self.script_noteworthy == "static")
					{
						level.zipinuse = true;
						
						for (i=0; i<zipBuyTrigger.size; i++)
						{
							//since the nonstatic trigger can't be turned off, just zero out the hint
							if (IsDefined(zipBuyTrigger[i].script_noteworthy) && zipBuyTrigger[i].script_noteworthy == "nonstatic")
							{
								zipBuyTrigger[i] notify ("stopstringmonitor");
							
								//trigger can't be turned off since it needs to move with the zipline
								zipBuyTrigger[i] LinkTo(zipBuyTrigger[i].zip);
								zipBuyTrigger[i] sethintstring("");
							}
							//turn off the static trigger
							else if (IsDefined(zipBuyTrigger[i].script_noteworthy) && zipBuyTrigger[i].script_noteworthy == "static" && (!IsDefined(level.direction)))
							{
								zipBuyTrigger[i] trigger_off();
							}
						}	
									
						//self.in_use = 1;

						play_sound_at_pos( "purchase", who.origin );

						//set the score
						who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );
						
						//if we used the trigger on the electric switch, we need to move the handle
						if (IsDefined(self.script_noteworthy) && self.script_noteworthy == "static")
						{
							self thread recallZipSwitch (180);
							self.lever playsound("switch");		
							self waittill ("recallLeverDone");
						}
						
						//if we're using the trigger in the zipline, the purchaser needs to be passed to ensure that he's on it
						if (IsDefined(self.script_noteworthy) && self.script_noteworthy == "nonstatic")
							self thread activateZip(who);
						else if (IsDefined(self.script_noteworthy) && self.script_noteworthy == "static")
							self thread activateZip(undefined);
						
						self waittill ("zipDone");					
						
						//turn off the mobile trigger after we've reached the destination, we can unbind it at this point
						if (IsDefined(self.script_noteworthy) && self.script_noteworthy == "nonstatic")
						{
							//turn the trigger off
							self unlink();
							self triggerOff();
						}
						
						//waittime = 40;
						waittime = 30; //small buff, only 30 seconds now
					
						/#
							if ( GetDVarInt( "zombie_cheat" ) > 0 )
							{
								waittime = 5;
							}
						#/
						//if we used the electric switch, flip it back up after the cool down
						if (IsDefined(self.script_noteworthy) && self.script_noteworthy == "static")
						{
							self thread recallZipSwitch (-180);
							self.lever playsound("switch_up");		
						}

						wait (waittime);	
						
						self.lever playsound("amb_sparks");		

						
						for (i=0; i<zipBuyTrigger.size; i++)
						{
							//always reenable the trigger on the zipline
							if (IsDefined(zipBuyTrigger[i].script_noteworthy) && zipBuyTrigger[i].script_noteworthy == "nonstatic")
							{
								zipBuyTrigger[i] sethintstring(&"ZOMBIE_ZIPLINE_USE");
								zipBuyTrigger[i] triggerOn();
								zipBuyTrigger[i] thread monitorZipHint();
							}
							//only enable the trigger on the electric switch if the zipline is capable of moving to the down spot
							if (IsDefined(zipBuyTrigger[i].script_noteworthy) && zipBuyTrigger[i].script_noteworthy == "static" && (!IsDefined(level.direction)))
								zipBuyTrigger[i] trigger_on();
						}
						
						level.zipinuse = false;
					}
				}
			}
			else
			{
				who play_sound_on_ent( "no_purchase" );
				who thread maps\nazi_zombie_sumpf_blockers::play_no_money_purchase_dialog();
			}
		}
	}
}

//utility version of these functions preserves the initial origin, which I cannot do because the triggers are moving 
triggerOn()
{
	if (IsDefined(self.triggeron) && !self.triggeron)
	{
		self.origin = (self.origin[0], self.origin[1], (self.origin[2] + 10000));
		self.triggeron = true;
	}
}

triggerOff()
{
	if (IsDefined(self.triggeron) && self.triggeron)
	{
		self.origin = (self.origin[0], self.origin[1], (self.origin[2] - 10000));	
		self.triggeron = false;
	}
}

monitorZipHint ()
{
	self endon ("stopstringmonitor");
	
	while (1)
	{
		players = get_players();
		downedplayers = [];
		aliveplayers = [];
		stoptrigger = false;
	
		//separate the good from the bad
		for(i=0; i<players.size; i++)
		{
			if (players[i] maps\_laststand::player_is_in_laststand() && players[i] IsTouching(self.volume)) 
				downedplayers = array_add(downedplayers, players[i]);
			else if (IsDefined(players[i]) && IsAlive(players[i]))
				aliveplayers = array_add(aliveplayers, players[i]);
		}
			
		if (aliveplayers.size > 0 && downedplayers.size > 0)
		{
			for(i=0; i<aliveplayers.size; i++)
			{
				for (p=0;p<downedplayers.size; p++)
				{
					if (aliveplayers[i] IsTouching( downedplayers[p].revivetrigger ))
					{
						stoptrigger = true;
						break;
					}
				}
				if (stoptrigger)
					break;
			}
		}
			
		if (stoptrigger)
				self triggerOff();
		else
			self triggerOn();
				
		wait (1);
	}
}					

activateZip(rider)
{	
	zombs = getaispeciesarray("axis");
	self.riders = [];
	self.canshock = false;
		
	//kill any zombies in the zipline
	for (i=0; i < zombs.size; i++)
	{
		if (IsDefined (zombs[i]) && IsAlive(zombs[i]) && zombs[i] IsTouching(self.zipDamageVolume))
		{
			//dogs just need to explode so they're not floating where the zipline was
			if ( zombs[i] enemy_is_dog() )
			{
				zombs[i].a.nodeath = true;
			}
			else
			{
				zombs[i] maps\nazi_zombie_sumpf_trap_pendulum::ragdoll_cleanup();
				zombs[i] StartRagdoll();
			}
		
			zombs[i] dodamage(zombs[i].health + 600, zombs[i].origin);
		}	
	}	
	
	level thread zip_line_audio();
		
	//array of locations
	attachspot = getentarray((self.zip).target, "targetname");
	peeps = get_players();
		
	for (i=0; i < peeps.size; i++)
	{
		if ( is_player_valid(peeps[i]) && ((peeps[i] IsTouching(self.volume) || (IsDefined (rider) && peeps[i] == rider ))))
		{
			self.riders = array_add(self.riders, peeps[i]);

			peeps[i] thread magic_bullet_shield(100000, 0);

			//peeps[i].ignoreme = true;
			peeps[i].on_zipline = true;
			peeps[i] setstance("stand");
			peeps[i] allowcrouch (false);
			peeps[i] allowprone (false);
			
			prevdist = undefined;
			playerspot = undefined;
				
			playerOrg = peeps[i] GetOrigin();
				
			for(p=0; p < attachspot.size; p++)
			{
				attachOrg = attachspot[p] GetOrigin(); 
					
				dist = distance2d( playerOrg, attachOrg );
				if (!IsDefined(prevdist))
				{	
					prevdist = dist;
					playerspot = attachspot[p];
				}
				else
				{
					if (dist <= prevdist)
					{
						prevdist = dist;
						playerspot = attachspot[p];
					}
				}
			}
			peeps[i] playerlinkto (playerspot, undefined, 0.0, 180, 180, 180, 180, true);
				
			attachspot = array_remove(attachspot, playerspot);
		}
	}
				
	//kill any thread that wants to turn the collision back on from the previous run
	for(i=0; i < (self.tempclip).size; i++)
	{
		self.tempclip[i] notify ("stopmonitorsolid");
	}
	
	wait(0.1);
	
	//just have everything noncolliding
	for(i=0; i < (self.tempclip).size; i++)
	{
		self.tempclip[i] notsolid();
	}
	
	//kill any thread that wants to turn the handle solid
	self.handle notify ("stopmonitorsolid");
	
	self.handle notsolid();
	self.handle unlink();
	
	//move the lever for the zipline
	if ((!(IsDefined(level.direction))))
		self.handle rotateto((0, -19.6, -65), 0.5);
	else
		self.handle rotateto((0, -19.6, 65), 0.5);
			
	self.handle waittill ("rotatedone");
	self.handle thread objectSolid();
	
	self.handle LinkTo(self.zip);
		
	self.zipDamageTrigger thread zipDamage(self);
	self.zipActive = true;
	
	//start spinning the pulleys
	self thread spinZipPulleys();

	if ((!(IsDefined(level.direction))))
	{
		//ai should not be allowed in the zipline area anymore
		self.aiblocker solid();
		self.aiblocker disconnectpaths();
			
		//fake the player positions
		for( i = 0; i < (self.riders).size; i++ )
		{
			self.riders[i] thread maps\_zombiemode::store_crumb((11216, 2883, -648));
		}
			
		curnode = self.spline;
		level.zrnodes[(((level.znodes).size) - 1)] = curnode;
		
		my_time = .3;
		for(i=0;i<((level.znodes).size - 1);i++)
		{
			curnode = getent(curnode.target, "targetname");
			level.zrnodes[((((level.znodes).size) - (i+2)))] = curnode; 
			self.zip moveto (curnode.origin, my_time);
			//self.zip waittill ("movedone");
			
			if (i == 3)
			{
				self.canshock = true;
			}
			
			if (i == 23)
			{
				self.canshock = false;
			}
			
			if (i > ((level.znodes).size * .666))
			{
				my_time = my_time + .017;	
			}
			else if (i < ((level.znodes).size * .333))
			{
				my_time = my_time - .017;
			}
			wait(my_time - .022);
		}
		self.zip waittill ("movedone");	
		level notify("machine_done");
		level.direction = "back";
	}
	else
	{			
		//fake the player positions
		for( i = 0; i < (self.riders).size; i++ )
		{
			self.riders[i] thread maps\_zombiemode::store_crumb((10750, 1516, -501));			  
		}
		my_time = .3;
		for(i=1;i<((level.zrnodes).size);i++)
		{
			//curnode = getent(level.zrnodes[i], "targetname");
			curnode = level.zrnodes[i];
			self.zip moveto (curnode.origin, my_time);
			
			if (i == 4)
			{
				self.canshock = true;
			}
			
			if (i == 23)
			{
				self.canshock = false;
			}
			
			if (i > ((level.znodes).size * .666))
			{
				my_time = my_time + .017;
			}
			else if (i < ((level.znodes).size * .333))
			{
				my_time = my_time - .017;
			}
			wait(my_time - .022);
		}
		
		self.zip waittill ("movedone");
			
		//ai can now access the zipline area
		self.aiblocker connectpaths();
		self.aiblocker notsolid();
			
		level.direction = undefined;
	}
		
	//monitor when we can turn the collision back on
	for(i=0; i < (self.tempclip).size; i++)
	{
		// turn the collision on to the floor of the zipline without monitoring because a person up top can cause the player to fall through the zipline 
		if ((!(IsDefined(level.direction))) && IsDefined((self.tempclip[i]).script_noteworthy) && (self.tempclip[i]).script_noteworthy == "zip_base")
			self.tempclip[i] solid();
		else
			self.tempclip[i] thread objectSolid();
	}
	level notify("machine_off");	
	self playsound("platform_bang");
	
	//zipline causes no more damage
	self.zipActive = false;
		
	wait(0.1);
	
	for (i=0; i < (self.riders).size; i++)
	{
		self.riders[i] unlink();
		self.riders[i] stop_magic_bullet_shield();
		self.riders[i] thread maps\_zombiemode::store_crumb(self.origin);
		//self.riders[i].ignoreme = false;
		self.riders[i].on_zipline = false;
		self.riders[i] allowcrouch (true);
		self.riders[i] allowprone (true);

		if(self.riders[i] hasperk("specialty_armorvest") )
		{
			self.riders[i].health = 250;
			self.riders[i].maxhealth = 250;
		}
		else
		{
			self.riders[i].health = 100;
			self.riders[i].maxhealth = 100;
		}
			
	}
		
	//put handle back in neutral
	self.handle unlink();
	self.handle rotateto((0, -19.6, 0), 0.5);
	self.handle waittill ("rotatedone");
	self.handle thread objectSolid();
	self.handle LinkTo(self.zip);

	self player_collision_fix();
		
	self notify ("zipDone");
}
			
zipDamage(parent)
{
	level endon ("machine_off");

	while(1)
	{
		self waittill("trigger",ent);
			
		if (parent.zipActive == true && IsDefined (ent) && IsAlive(ent))
		{
			if(isplayer(ent) )
			{
				ent thread playerZipDamage(parent);
			}
			else
			{
				ent thread zombieZipDamage();
			}
		}
	}
}

playerZipDamage(parent)
{	
	self endon("death");
	self endon("disconnect");
		
	players = get_players();
	
	for(i=0; i < (parent.riders).size; i++)
	{
		if (self == parent.riders[i])
		{
			return;
		}
	}
	
	//zipline will no longer damage the player	 
	/*if (players.size == 1)
	{
		self thread maps\_zombiemode::player_damage_override( undefined, undefined, 100, undefined, "MOD_MELEE", undefined, self.origin, self.origin, undefined, undefined, undefined );
	}
	else
	{
		if(!self maps\_laststand::player_is_in_laststand() )
		{                
			radiusdamage(self.origin,10,self.health + 100,self.health + 100);
		}
	}*/

	if( !isDefined(self.zipshock) && !self maps\_laststand::player_is_in_laststand() && parent.canshock == true)
	{
		self stopShellshock();

		self.zipshock = 1;		

		self shellshock("death", 3);
		
		wait(2);
		
		self.zipshock = undefined;
	}		

}

zombieZipDamage()
{
	self endon("death");
	
	//dogs just need to explode so they're not floating where the zipline was
	if ( self enemy_is_dog() )
	{
		self.a.nodeath = true;
	}
	else
	{
		self maps\nazi_zombie_sumpf_trap_pendulum::ragdoll_cleanup();
		self StartRagdoll();
	}
		
	self dodamage(self.health + 600, self.origin); 	
}

objectSolid()
{
	self endon("stopmonitorsolid");
	
	while( 1 )
	{
		players = get_players(); 
		player_touching = false; 
		for( i = 0; i < players.size; i++ )
		{
			if( players[i] IsTouching( self ) )
			{
				player_touching = true; 
				break; 
			}
		}

		if( !player_touching )
		{
			self Solid(); 
			return; 
		}

		wait( 0.5 ); 
	}
}

spinZipPulleys()
{
	pulleys = getentarray("zip_pulley", "targetname");
		
	for(i=0; i < pulleys.size; i++)
	{
		pulleys[i] rotateyaw (1800, 4.8);
	}
}

player_collision_fix()
{
	assert( IsDefined( self ) );
	assert( IsDefined( self.tempclip ) );

	if ( IsDefined( level.direction ) )
	{
		return;
	}
	
	// get the base clip
	base = undefined;
	
	for( i = 0; i < self.tempclip.size; i++ )
	{
		clip = self.tempclip[i];
		
		if ( IsDefined( clip.script_noteworthy ) && clip.script_noteworthy == "zip_base" )
		{
			base = clip;
			break;
		}
	}

	assert( IsDefined( base ) );

	z = base.origin[2];

	// check if a player is below the base clip z
	players = get_players();

	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		
		if ( !is_player_valid( player ) )
		{
			continue;
		}

		if ( !player IsTouching( base ) )
		{
			continue;
		}

		if ( player.origin[2] < z )
		{
			//iprintlnbold( "player stuck" );
			
			offset = z + 6;
			origin = ( player.origin[0], player.origin[1], offset );

			player SetOrigin( origin );
		}
	}
}
