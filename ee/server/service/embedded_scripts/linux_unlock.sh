#!/bin/sh

# Unlock password for all non-root users
awk -F':' '{ if ($3 >= 1000 && $3 < 60000) print $1 }' /etc/passwd | while read user
do
    echo "$user"
    if [ "$user" != "root" ]; then
        echo "Unlocking password for $user"
        STDERR=$(passwd -u "$user" 2>&1 >/dev/null)
        if [ $? -eq 3 ]; then
          # possibly due to the user not having a password
          # use this convoluted case approach to avoid bashisms (POSIX portable)
          case "$STDERR" in
            *"unlocking the password would result in a passwordless account"* )
              # unlock and delete password to set it back to empty
              passwd -ud "$user"
            ;;
          esac
        fi
    fi
done

# Remove the pam_nologin file
[ -f /etc/nologin ] && rm /etc/nologin

# Enable systemd-user-sessions, a service that deletes /etc/nologin
if [ -f /usr/lib/systemd/system/systemd-user-sessions.service ]; then
    systemctl unmask systemd-user-sessions
    systemctl daemon-reload
    /usr/lib/systemd/systemd-user-sessions start
fi

# TODO this should be re-checked and possibly removed in the future.
#
# When we lock a machine using /etc/nologin, GDM seems to get stuck in
# a state where the screen stays black. This didn't used to be the
# case on Ubuntu 22.04. This bug doesn't affect other login managers
# such as lightdm.
#
# Because of a bug, likely in GDM on Ubuntu after 22.04, we have to reboot the
# machine to get the login screen back. Note this bug does not occur
# in Fedora
reboot
