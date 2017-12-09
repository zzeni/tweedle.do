$ ->
  $('.image-preview').on 'click', (event) ->
    $(this).parent().find('.image-input').click()

  $('.image-input').on 'change', (event) ->
    image = event.target.files[0];
    reader = new FileReader();
    target = $(this).parent().find('.image-preview img')

    target.css {opacity: 0}

    reader.onload = (file) ->
      target[0].src = file.target.result

      if target.outerWidth() > target.outerHeight()
        target.css {'max-height': '100%', 'max-width': 'initial'}
      else
        target.css {'max-width': '100%', 'max-height': 'initial'}

      target.css {opacity: 1}

    reader.readAsDataURL image
