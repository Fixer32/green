obj/item/weapon/gun/energy/freezegun
	name = "Freezer gun"
	desc = "Special gun to freeze some badasses"
	icon = 'gun.dmi'
	icon_state = "freezegun"
	item_state = "freezegun"
	fire_sound = 'emitter.ogg'
	flags =  FPRINT | TABLEPASS | CONDUCT | USEDELAY
	charge_cost = 200
	projectile_type = "/obj/item/projectile/freezeball"
	origin_tech = null
	var/charge_tick = 0

	New()
		..()
		processing_objects.Add(src)


	Del()
		processing_objects.Remove(src)
		..()


	process()
		charge_tick++
		if(charge_tick < 4) return 0
		charge_tick = 0
		if(!power_supply) return 0
		power_supply.give(200)
		update_icon()
		return 1

/obj/item/projectile/freezeball
	name = "freeze beam"
	icon_state = "ice_2"
	damage = 0
	damage_type = BURN
	nodamage = 1
	flag = "energy"


	on_hit(var/atom/freezetg)

		freezemob(freezetg)

/obj/structure/freezedmob
	name = "Pile of ice"
	icon = 'device.dmi'
	icon_state = "singlebath.bottom"
	desc = "Big pile of ice. Some aborigens at waterless planets can kill for ot"
	density = 1
	anchored = 0
	unacidable = 1//shouldnt I think
	var/health = 100
	var/ice = 100
	var/mob/living/occupant
	var/charge_tick = 0

	New()
		..()
		processing_objects.Add(src)


	Del()
		processing_objects.Remove(src)
		..()

	process()
		var/turf/simulated/location = src.loc
		if (!istype(location))
			return 0
		var/datum/gas_mixture/environment = location.return_air()
		if (environment.temperature < 273)
			return 0
		else
			charge_tick++
			if(charge_tick < 4) return 0
			charge_tick = 0
			ice -= (environment.temperature-273)/2
			icecheck()
		return 1





/obj/structure/freezedmob/ex_act(severity)
	switch(severity)
		if (1)
			src.occupant.loc = src.loc
			src.occupant.death()
			src.occupant.gib()
			del(src)
		if (2)
			if (prob(50))
				src.health -= 15
				src.healthcheck()
		if (3)
			if (prob(50))
				src.health -= 5
				src.healthcheck()


/obj/structure/freezedmob/bullet_act(var/obj/item/projectile/Proj)
	health -= Proj.damage
	..()
	src.healthcheck()
	return


/obj/structure/freezedmob/blob_act()
	if (prob(75))
		src.occupant.loc = src.loc
		src.occupant.death()
		src.occupant.gib()
		del(src)


/obj/structure/freezedmob/meteorhit(obj/O as obj)
	src.occupant.loc = src.loc
	src.occupant.death()
	src.occupant.gib()
	del(src)


/obj/structure/freezedmob/proc/healthcheck()
	if (src.health <= 0)
		playsound(src, "shatter", 70, 1)
		src.occupant.loc = src.loc
		src.occupant.death()
		src.occupant.gib()
		del(src)
	else
		playsound(src.loc, 'Glasshit.ogg', 75, 1)
	return

/obj/structure/freezedmob/proc/icecheck()
	if (src.ice <= 0)
		playsound(src.loc, 'Welder2.ogg', 100, 1)
		src.occupant.loc = src.loc
		var/mob/living/M = src.occupant
		M.canmove = 1
		M.confused = 0
		for(var/obj/item/I in src)
			I.loc = src.loc
		src.occupant << "Thanks god, ice finally melted"
		del(src)
	return

/obj/structure/freezedmob/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/weldingtool) && W:welding)
		usr << text("\blue You melted some ice on [] with [].", src.name, W.name)
		for(var/mob/O in oviewers())
			if ((O.client && !( O.blinded )))
				O << text("\red [] melted some ice on [] with []", usr, src.name, W.name)
		src.ice -= 20
		return
	src.health -= W.force
	src.healthcheck()
	..()
	return

/obj/structure/freezedmob/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/structure/freezedmob/attack_hand(mob/user as mob)
	usr << text("\blue You kick the [].", src.name)
	for(var/mob/O in oviewers())
		if ((O.client && !( O.blinded )))
			O << text("\red [] kicks the []", usr, src.name)
	src.health -= 2
	healthcheck()
	return

proc/freezemob(mob/M as mob in world)
	M.canmove = 0
	M << "\red You fell how ice starts to cower your body"
	sleep(5)

	var /obj/structure/freezedmob/I = new /obj/structure/freezedmob( M.loc )
	I.name = "Ice statue"
	I.desc = text("You can hardly recognize [] under the layer of ice", M.name)
	I.dir = M.dir
	if (ishuman(M))
		var/mob/living/carbon/human/the_man = M
		var/icon/frozen_img = new/icon(M.icon, M.icon_state, I.dir)
		frozen_img.Blend("#6495ED",ICON_MULTIPLY)
		frozen_img.SetIntensity(1.4)
		for (var/image/block in the_man.get_overlays(M.lying))
			var/icon/temp = new/icon(block.icon, block.icon_state, I.dir)
			temp.Blend("#6495ED",ICON_MULTIPLY)
			temp.SetIntensity(1.4)
			frozen_img.Blend(temp, ICON_OVERLAY)
		I.icon = frozen_img
	else
		var/icon/overlay
		if(istype(src, /mob/living/carbon/metroid))
			overlay = new/icon(M.icon, M.icon_state)
		else
			overlay = new/icon(M.icon, M.icon_state, I.dir)
		overlay.Blend("#6495ED",ICON_MULTIPLY)
		overlay.SetIntensity(1.4)
		I.icon = overlay
	if(M.client)
		M.client.perspective = EYE_PERSPECTIVE
		M.client.eye = I
	M.loc = I
	I.occupant = M
	M.confused = 100000 // lol
	return 1

/mob/living/carbon/human/proc/get_overlays(var/lying)
	var/list/wholebody
	if(!lying)
		wholebody += body_overlays_standing
		wholebody += face_standing
		wholebody += damageicon_standing
	else
		wholebody += body_overlays_lying
		wholebody += face_lying
		wholebody += damageicon_lying
	wholebody += clothing_overlays
	return wholebody

