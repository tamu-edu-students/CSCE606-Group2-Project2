import { Controller } from "@hotwired/stimulus"

// Converts ISO datetimes rendered server-side into the user's local timezone
// and replaces the element text with a localized representation. Uses
// Intl.DateTimeFormat so no extra deps are required.
export default class extends Controller {
  static values = { format: String }

  connect() {
    const iso = this.element.getAttribute('datetime') || this.element.textContent
    const date = new Date(iso)
    if (Number.isNaN(date.getTime())) return

    const format = this.formatValue || 'short'
    const options = format === 'long'
      ? { year: 'numeric', month: 'long', day: 'numeric', hour: 'numeric', minute: '2-digit' }
      : { year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }

    try {
      const formatted = new Intl.DateTimeFormat(navigator.language || 'en-US', options).format(date)
      this.element.textContent = formatted
    } catch (e) {
      // fallback: leave server-rendered value
      // console.debug('local-time formatting failed', e)
    }
  }
}
