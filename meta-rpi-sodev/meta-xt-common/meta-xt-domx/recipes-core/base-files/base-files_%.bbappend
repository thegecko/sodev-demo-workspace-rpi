# Append domain name
# XT_DOM_NAME is set per domain by the build definition (rpi5-sodev.yaml); the
# ?= default below only applies if a build does not set it.
XT_DOM_NAME ??= "domx"
hostname .= "-${XT_DOM_NAME}"

do_install:append () {
        echo "shopt -s checkwinsize" >> ${D}${sysconfdir}/profile
        # Guard on resize being present: busybox is built without CONFIG_RESIZE
        # and no image here installs xterm, so an unguarded call printed
        # "resize: command not found" on every interactive login. Also skip
        # serial consoles: resize probes cursor position with terminal escape
        # queries, which makes scripted USB-serial login unreliable and can leave
        # the first shell needing `exec /bin/sh -i` before normal commands run.
        echo 'case "$(tty 2>/dev/null)" in /dev/hvc*|/dev/ttyGS*|/dev/ttyAMA*) ;; *) command -v resize >/dev/null && eval "$(resize)" ;; esac' >> ${D}${sysconfdir}/profile
}
