import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }

document.addEventListener("turbo:load", () => {

  const input = document.getElementById("image-upload")
  const previewContainer = document.getElementById("image-preview-container")

  if (!input) return

  input.addEventListener("change", () => {

    const file = input.files[0]

    if (!file) return

    const reader = new FileReader()

    reader.onload = function(e) {

        previewContainer.innerHTML = `
        <div class="d-inline-block position-relative me-2">
          <img src="${e.target.result}" class="img-thumbnail" style="height:60px;">
        </div>
      `
    }

    reader.readAsDataURL(file)

  })

})
