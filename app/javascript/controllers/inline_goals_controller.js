import { Controller } from "@hotwired/stimulus"

// Allows double-click-to-edit for daily goal fields in the dashboard summary.
export default class extends Controller {
  static values = {
    field: String,
    currentValue: String,
    unit: String
  }

  connect() {
    this.element.classList.add("inline-goal")
    this.boundEdit = this.edit.bind(this)
    this.element.addEventListener("dblclick", this.boundEdit)
  }

  disconnect() {
    this.element.removeEventListener("dblclick", this.boundEdit)
  }

  edit(event) {
    event.preventDefault()
    if (this.input) return

    const valueSpan = this.element.querySelector('.value')
  const current = this.currentValueValue || (valueSpan ? valueSpan.textContent.trim() : '')

  this.input = document.createElement('input')
  this.input.type = 'number'
  this.input.min = 0
  this.input.value = current
    this.input.className = 'inline-goal-input'
    this.input.addEventListener('blur', this.save.bind(this))
    this.input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') this.save()
      if (e.key === 'Escape') this.cancel()
    })

    // Replace contents with input
    this.element.innerHTML = ''
    this.element.appendChild(this.input)
    this.input.focus()
    this.input.select()
  }

  cancel() {
    this.clearInput()
    this.restoreDisplay()
  }

  save() {
    const val = this.input.value
    // send ajax PATCH to update goal
    const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    const payload = {}
    // if editing calories_left, send calories_left so server can compute new daily_calories_goal
    if (this.fieldValue === 'calories_left') {
      payload['calories_left'] = val
    } else {
      payload[this.fieldValue] = val
    }

    fetch('/profile/goals', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': token,
        'Accept': 'application/json'
      },
      body: JSON.stringify(payload)
    })
      .then((resp) => {
        if (!resp.ok) throw resp
        return resp.json()
      })
      .then((json) => {
        const displayed = (json.user && (json.user[this.fieldValue] ?? json.user.calories_left)) ?? val
        this.currentValueValue = displayed
        this.renderDisplay(displayed)
      })
      .catch(async (err) => {
        console.error('Failed to update goal', err)
        // restore original display on error
        this.restoreDisplay()
      })
      .finally(() => this.clearInput())
  }

  restoreDisplay() {
    const current = this.currentValueValue || ''
    this.renderDisplay(current)
  }

  clearInput() {
    if (this.input) {
      this.input = null
    }
  }

  renderDisplay(value) {
    const suffix = this.unitValue === 'calories' ? ' calories' : ' g'
    const className = this.valueClassFor(value)
    const classFragment = className ? ` ${className}` : ''
    const text = value == null ? '' : value
    this.element.innerHTML = `<span class="value${classFragment}">${text}</span>${suffix}`
  }

  valueClassFor(value) {
    if (this.fieldValue !== 'calories_left') return ''

    const numeric = Number(value)
    if (Number.isNaN(numeric)) return ''

    return numeric <= 0 ? 'value--negative' : 'value--positive'
  }
}
