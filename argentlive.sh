#!/usr/bin/env bash

export local liveuser="argent"

checkroot() {
	if [[ "$(whoami)" != root ]] ; then
		echo "No root, no play! Bye bye!"
		exit 1
	fi
}

argent_is_live() {
	if [[ ! -L "/dev/mapper/live-rw" ]] ; then
		echo "The system is not running in live mode, aborting!"
		exit 1
	fi
}

argent_add_live_user() {
	/usr/sbin/useradd -u 1000 -g 100 -o -m -s /bin/bash "$liveuser" > /dev/null 2>&1
}

argent_live_user_groups() {
	for group in tty disk lp wheel uucp console audio cdrom tape video cdrw usb plugdev pipewire messagebus portage vboxsf vboxguest ; do
		gpasswd -a "$liveuser" "$group" > /dev/null 2>&1
	done
}

argent_live_user_password() {
	passwd -d "$liveuser" > /dev/null || continue
}

argent_live_locale_switch() {
	export local keymap_toset="$(cat /proc/cmdline | cut -d " " -f5 | cut -d "=" -f2)"
	export local lang_toset="$(cat /proc/cmdline | cut -d " " -f6 | cut -d "=" -f2)"
	if [[ "$lang_toset" != "en_US.utf8" ]] || [[ "$keymap_toset" != "us" ]] ; then
		/usr/bin/localectl set-locale LANG="$lang_toset" > /dev/null 2>&1
		/usr/bin/localectl set-keymap "$keymap_toset" > /dev/null 2>&1
		/usr/sbin/env-update --no-ldconfig > /dev/null 2>&1
	else
		/usr/bin/eselect locale set "en_US.utf8" > /dev/null 2>&1
		/usr/sbin/env-update --no-ldconfig > /dev/null 2>&1
	fi
}

argent_set_dm_configuration(){
	if [[ -e "/usr/share/wayland-sessions/plasma.desktop" ]]; then
		session="plasma"
	fi

	if [[ -n "$session" ]]; then
		sed -i -e "s|^User=.*|User=argent|" -e "s|^Session=.*|Session=$session|" /etc/sddm.conf.d/00argent.conf > /dev/null 2>&1
	fi

}

argent_live_installer_desktop() {
	cp "/usr/share/applications/argent-installer.desktop" "/home/$liveuser/Desktop"
	chmod 755 "/home/$liveuser/Desktop/argent-installer.desktop"
}

argent_live_pipewire() {
	runuser -l "$liveuser" -c "systemctl --user stop plasma-powerdevil.service" > /dev/null 2>&1
	runuser -l "$liveuser" -c "systemctl --user enable pipewire-pulse.socket wireplumber.service pipewire.service" > /dev/null 2>&1
	runuser -l "$liveuser" -c "systemctl --user start pipewire-pulse.socket wireplumber.service pipewire.service" > /dev/null 2>&1
	runuser -l "$liveuser" -c "systemctl --user restart plasma-powerdevil.service" > /dev/null 2>&1
}

main() {
	if checkroot && argent_is_live ; then
		argent_add_live_user
		argent_live_user_groups
		argent_live_user_password
		argent_set_dm_configuration
		argent_live_installer_desktop
		argent_live_locale_switch
		argent_live_pipewire
	fi
}

main
exit 0
