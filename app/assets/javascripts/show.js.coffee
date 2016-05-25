$(document).on "page:change", ->
  value = $("select#user_role :selected").val()
  old_value = $("select#user_role :selected").val()
  $("#user_role").change ->
    value = $("select#user_role :selected").val()
    if value == old_value
      $("#btn-saves").prop "disabled", true
    else
      $("#btn-saves").prop "disabled", false
    return
  $("#btn-saves").click ->
    $.ajax
      url: "/admin/users/" + $("#user_id").val()
      type: "PATCH"
      dataType: "json"
      data:
        user_id: $("#user_id").val()
        new_role: value
        admin_action: "edit_role"
        authenticity_token: $("input[name=authenticity_token]").val()
      success: (data) ->
        old_value = value
        $("#btn-saves").prop "disabled", true
        alert data.message
        return
    false
  $("#btn-reset").click ->
    $.ajax
      url: "/admin/users/" + $("#user_id").val()
      type: "PATCH"
      dataType: "json"
      data:
        admin_action: "reset_password"
        authenticity_token: $("input[name=authenticity_token]").val()
      success: (data) ->
        alert data.message
        return
    false
  return