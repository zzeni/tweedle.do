$(document).on 'turbolinks:load', () ->
  initDataRemoteHandler = () ->
    # fix the kaminari ajax pagination by attaching
    # a handler for the ajax:success event on the kaminari link
    $(".page-link[data-remote]").on "ajax:success", (event) ->
      if (event.detail && event.detail.length)
        xhr = event.detail.pop()
        content = $(event.detail.shift()).find('body main')
        url = xhr.responseURL
        window.history.pushState({"html":xhr.response},"", url);
        if content && content.length
          $('body main').html content.html()
          # re-init the handler for the new content
          initDataRemoteHandler()
  # execute initDataRemoteHandler
  initDataRemoteHandler()
