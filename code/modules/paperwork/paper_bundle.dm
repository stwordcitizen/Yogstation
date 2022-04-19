/obj/item/paper_bundle
	name = "paper bundle"
	gender = PLURAL
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	item_state = "paper"
	throwforce = 0
	w_class = 1.0
	throw_range = 2
	throw_speed = 1
	layer = 4
	pressure_resistance = 1
	attack_verb = list("bapped")
	var/amount = 0 //Amount of items clipped to the paper
	var/page = 1
	var/screen = 0


/obj/item/paper_bundle/attackby(obj/item/W as obj, mob/user as mob)
	..()
	var/obj/item/paper/P
	if(istype(W, /obj/item/paper))
		P = W
		if (istype(P, /obj/item/paper/carbon))
			var/obj/item/paper/carbon/C = P
			if (!C.iscopy && !C.copied)
				user << "<span class='notice'>Take off the carbon copy first.</span>"
				add_fingerprint(user)
				return
		amount++
		if(screen == 2)
			screen = 1
		user << "<span class='notice'>You add [(P.name == "paper") ? "the paper" : P.name] to [(src.name == "paper bundle") ? "the paper bundle" : src.name].</span>"
		user.dropItemToGround(P)
		P.loc = src
	else if(istype(W, /obj/item/photo))
		amount++
		if(screen == 2)
			screen = 1
		user << "<span class='notice'>You add [(W.name == "photo") ? "the photo" : W.name] to [(src.name == "paper bundle") ? "the paper bundle" : src.name].</span>"
		user.dropItemToGround(W)
		W.loc = src
	else if(W.is_hot())
		burnpaper(W, user)
	else if(istype(W, /obj/item/paper_bundle))
		user.dropItemToGround(W)
		for(var/obj/O in W)
			O.loc = src
			O.add_fingerprint(usr)
			src.amount++
			if(screen == 2)
				screen = 1
		user << "<span class='notice'>You add \the [W.name] to [(src.name == "paper bundle") ? "the paper bundle" : src.name].</span>"
		qdel(W)
	else
		if(istype(W, /obj/item/pen) || istype(W, /obj/item/toy/crayon))
			usr << browse("", "window=[name]") //Closes the dialog
		P = src[page]
		P.attackby(W, user)


	update_icon()
	attack_self(usr) //Update the browsed page.
	add_fingerprint(usr)
	return


/obj/item/paper_bundle/proc/burnpaper(obj/item/P, mob/user)
	var/class = "<span class='warning'>"

	if(P.is_hot() && !user.restrained())
		if(istype(P, /obj/item/lighter))
			class = "<span class='rose'>"

		user.visible_message("[class][user] holds \the [P] up to \the [src], it looks like \he's trying to burn it!</span>", \
		"[class]You hold \the [P] up to \the [src], burning it slowly.</span>")

		if(do_after(user, 2 SECONDS, TRUE, src))
			user.visible_message("[class][user] burns right through \the [src], turning it to ash. It flutters through the air before settling on the floor in a heap.</span>", \
			"[class]You burn right through \the [src], turning it to ash. It flutters through the air before settling on the floor in a heap.</span>")

			if(user.get_inactive_hand_index() == src)
				user.dropItemToGround(src)

			new /obj/effect/decal/cleanable/ash(src.loc)
			qdel(src)

		else
			to_chat(user, "<span class='warning'>You must hold \the [P] steady to burn \the [src].</span>")

/obj/item/paper_bundle/examine(mob/user)
	if(..(user, 1))
		src.show_content(user)
	else
		user << "<span class='notice'>It is too far away.</span>"
	return

/obj/item/paper_bundle/proc/show_content(mob/user as mob)
	var/dat
	var/obj/item/W = src[page]
	dat += "<DIV STYLE='float:left; text-align:left; width:33.33333%'><A href='?src=\ref[src];prev_page=1'>[screen != 0 ? "Previous Page" : ""]</DIV>"
	dat += "<DIV STYLE='float:left; text-align:center; width:33.33333%'><A href='?src=\ref[src];remove=1'>Remove [(istype(W, /obj/item/paper)) ? "paper" : "photo"]</A></DIV>"
	dat += "<DIV STYLE='float:left; text-align:right; width:33.33333%'><A href='?src=\ref[src];next_page=1'>[screen != 2 ? "Next Page" : ""]</A></DIV><BR><HR>"
	if(istype(src[page], /obj/item/paper))
		var/obj/item/paper/P = W
		var/dist = get_dist(src, user)
		if(dist < 2 || istype(usr, /mob/dead/observer) || istype(usr, /mob/living/silicon))
			dat += "[P.render_body(user)]<HR>[P.stamps]"
		else 
			dat += "[stars(P.render_body(user))]<HR>[P.stamps]"
			log_admin("EEEEEEEEEEEEEEEEEEEEEEEEEE")
		user << browse(dat, "window=[name]")
	else if(istype(src[page], /obj/item/photo))
		var/obj/item/photo/P = W
		var/datum/picture/picture2 = P.picture
		user << browse_rsc(picture2.picture_image, "tmp_photo.png")
		user << browse(dat + "<html><head><title>[P.name]</title></head>" \
		+ "<body style='overflow:hidden'>" \
		+ "<div> <img src='tmp_photo.png' width = '180'" \
		+ "[P.scribble ? "<div> Written on the back:<br><i>[P.scribble]</i>" : ""]"\
		+ "</body></html>", "window=[name]")

/obj/item/paper_bundle/attack_self(mob/user as mob)
	src.show_content(user)
	add_fingerprint(usr)
	update_icon()
	return

/obj/item/paper_bundle/proc/update_screen()
	if(page == amount)
		screen = 2
	else if(page == 1)
		screen = 1
	else if(page == amount+1)
		return

/obj/item/paper_bundle/Topic(href, href_list)
	..()
	if((src in usr.contents) || (istype(src.loc, /obj/item/folder) && (src.loc in usr.contents)) || IsAdminGhost(usr))
		usr.set_machine(src)
		if(href_list["next_page"])
			if(page+1 == amount)
				screen = 2
			else if(page == 1)
				screen = 1
			else if(page == amount)
				return
			page++
			playsound(src.loc, "pageturn", 50, 1)
		if(href_list["prev_page"])
			if(page == 1)
				return
			else if(page == 2)
				screen = 0
			else if(page == amount+1)
				screen = 1
			page--
			playsound(src.loc, "pageturn", 50, 1)
		if(href_list["remove"])
			var/obj/item/W = src[page]
			usr.put_in_hands(W)
			usr << "<span class='notice'>You remove the [W.name] from the bundle.</span>"
			if(amount == 1)
				var/obj/item/paper/P = src[1]
				usr.dropItemToGround(src)
				usr.put_in_hands(P)
				qdel(src)
			else if(page == amount)
				screen = 2
			else if(page == amount+1)
				page--

			amount--
			update_icon()
	else
		usr << "<span class='notice'>You need to hold it in hand!</span>"
	if (istype(src.loc, /mob) || istype(src.loc.loc, /mob))
		src.attack_self(src?.loc)
		updateUsrDialog()



/obj/item/paper_bundle/verb/rename()
	set name = "Rename bundle"
	set category = "Object"
	set src in usr

	var/n_name = sanitize(copytext(input(usr, "What would you like to label the bundle?", "Bundle Labelling", null)  as text, 1, MAX_NAME_LEN))
	if((loc == usr && usr.stat == 0))
		name = "[(n_name ? text("[n_name]") : "paper")]"
	add_fingerprint(usr)
	return


/obj/item/paper_bundle/verb/remove_all()
	set name = "Loose bundle"
	set category = "Object"
	set src in usr

	usr << "<span class='notice'>You loosen the bundle.</span>"
	for(var/obj/O in src)
		O.loc = usr.loc
		O.layer = initial(O.layer)
		O.add_fingerprint(usr)
	usr.dropItemToGround(src)
	qdel(src)
	return


/obj/item/paper_bundle/update_icon()
	cut_overlays()
	var/obj/item/paper/P = src[1]
	icon_state = P.icon_state
	overlays = P.overlays
	underlays = 0
	var/i = 0
	var/photo
	for(var/obj/O in src)
		var/image/img = image('icons/obj/bureaucracy.dmi')
		if(istype(O, /obj/item/paper))
			img.icon_state = O.icon_state
			img.pixel_x -= min(1*i, 2)
			img.pixel_y -= min(1*i, 2)
			pixel_x = min(0.5*i, 1)
			pixel_y = min(  1*i, 2)
			underlays += img
			i++
		else if(istype(O, /obj/item/photo))
			var/obj/item/photo/PR
			var/datum/picture/picture2 = PR.picture
			img = picture2.picture_icon
			photo = 1
			add_overlay(img)
	if(i>1)
		desc =  "[i] papers clipped to each other."
	else
		desc = "A single sheet of paper."
	if(photo)
		desc += "\nThere is a photo attached to it."
	add_overlay(image('icons/obj/bureaucracy.dmi', icon_state= "clip"))
	return
