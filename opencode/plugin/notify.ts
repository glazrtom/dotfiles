import type { Plugin } from "@opencode-ai/plugin"

export default (async ({ $ }) => {
  const inGhostty = process.env["TERM_PROGRAM"] === "ghostty"

  // Ghostty: emit an OSC 777 desktop-notification escape sequence to the
  // tab's pty. Ghostty binds the notification to the surface that produced
  // it, so clicking the banner focuses THIS exact window+tab. Requires that
  // this process still has the Ghostty pty as its controlling terminal
  // (/dev/tty); if not, the write fails and we fall back to osascript.
  const notifyGhostty = (title: string, body: string) =>
    $`printf '\033]777;notify;%s;%s\007' ${title} ${body} > /dev/tty`
      .quiet()
      .nothrow()

  // Fallback (non-Ghostty terminals): a plain banner. Not clickable-to-tab —
  // the click brings Script Editor forward, not your session.
  const notifyOsascript = (body: string) =>
    $`osascript -e ${`display notification "${body}" with title "opencode"`}`
      .quiet()
      .nothrow()

  const notify = async (body: string) => {
    if (inGhostty) {
      const result = await notifyGhostty("opencode", body)
      if (result.exitCode === 0) return
    }
    await notifyOsascript(body)
  }

  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await notify("Waiting for your input")
      }
      if (event.type === "permission.updated") {
        await notify("Permission needed — approve or deny")
      }
    },
  }
}) satisfies Plugin
