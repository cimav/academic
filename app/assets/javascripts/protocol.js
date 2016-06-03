$(document).ready(function() {
  $('#protocol-form')
    .live("ajax:beforeSend",function(evt,xht,settings){
      console.log("Antes de ...");

      var rb_chk = $("input[type=radio]:checked");
      
      /*if(rb_chk.length != 0)
      {
        alert("Debe seleccionar todas las opciones, los comentarios no son obligatorios")
        return false;
      }*/

      $("#protocol-save").attr("disabled","disabled");
      $("#protocol-send").attr("disabled","disabled");
      $("#img_load").css("display","inline-block");
      $("#messages").html("");
    })
    .live("ajax:error", function(evt, xhr, status, error) {
      var res = $.parseJSON(xhr.responseText);
      $("#messages").html(res['flash']['error']);
    })
    .live('ajax:success', function(evt, xhr, status, xhr) {
      var res = $.parseJSON(xhr.responseText);
      var sts = res['params']['status'];
      $("#messages").html(res['flash']['notice']);
      if(sts==1)
      {
        $("#protocol-form :input").attr("disabled","disabled");
      }

      console.log("Eso es todo amigos");
    })
    .live('ajax:complete', function(evt, data, status, xhr) {
      $("#protocol-save").removeAttr("disabled","disabled");
      $("#protocol-send").removeAttr("disabled","disabled");
      $("#img_load").css("display","none");
    })

});
