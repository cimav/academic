$(document).ready(function() {
  $('#protocol-form')
    .live("ajax:beforeSend",function(evt,xht,settings){
      console.log("Antes de ...");

      var rb_chk = $(".question[q_type='1'] input[type=radio]:checked");
      var q_type = $(".question[q_type='1']");
      
      if(rb_chk.length != q_type.length)
      {
        alert("Debe seleccionar todas las opciones para continuar, los comentarios no son obligatorios");
        return false;
      }

      var grade_chk = $(".question[q_type='grade'] input[type=radio]:checked");

      if(grade_chk.length!=1){
        alert("Debe calificar para continuar");
        return false;
      }

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
        $(".recommendation").show();
      }
      
    })
    .live('ajax:complete', function(evt, data, status, xhr) {
      $("#protocol-send").attr("disabled","disabled");
      $("#img_load").css("display","inline-block");
      $("#messages").html("");
    })
    .live("ajax:error", function(evt, xhr, status, error) {
      var res = $.parseJSON(xhr.responseText);
      $("#messages").html(res['flash']['error']);
    })
    .live('ajax:success', function(evt, xhr, status, xhr) {
      var res  = $.parseJSON(xhr.responseText);
      var sts  = res['params']['status'];
      var p_id = res['uniq']
      $("#messages").html(res['flash']['notice']);
      if(sts==3)//created
      {
        $("#protocol-form :input").attr("disabled","disabled");
      }
      else if(sts==4)//recommendation
      {
        $("#protocol-form :input").attr("disabled","disabled");
        $(".recommendation").show();
        $("input[name=recom]").removeAttr("disabled","disabled");
      }

      $("#protocol_id").val(p_id);
    })
    .live('ajax:complete', function(evt, data, status, xhr) {
      $("#protocol_id").removeAttr("disabled","disabled");
      $("#protocol-send").removeAttr("disabled","disabled");
      $("#img_load").css("display","none");
    })

});
