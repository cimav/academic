$(document).ready(function() {
  grade_1 = $("#grade_status_1").prop("checked");
  if(grade_1){
    $('.text_area_a').show();
  }else{
    $('.text_area_a').hide();
  }

  $(".grade_a").click(function(){
    value = $(this).val();
    if(value==1){
      $('.text_area_a').show();
    }
    else if(value==2){
      $('.text_area_a').hide();
    }
  });

  $("#recom-send").click(function(){
    send_recomms();
    return false;
  });

  $('#protocol-form')
    .live("ajax:beforeSend",function(evt,xht,settings){
      console.log("Before send ...");
      $("#messages").html("");

      /* validando radiobuttons */
      var rb_chk = $(".question[q_type='1'] input[type=radio]:checked");
      var q_type = $(".question[q_type='1']");

      if(rb_chk.length != q_type.length)
      {
        alert("Debe seleccionar todas las opciones para continuar");
        return false;
      }

      /* validando grades */
      grades   = $(".question[q_type='3'] option:selected")
      q_grade  = $(".question[q_type='3']")
      t_grades = grades.length

      $.each(grades,function(index,value){
        if($(value).val()!=""){
          t_grades = t_grades - 1
        } 
      });

      if(t_grades>0)
      {
        alert("Debe calificar todas las opciones para continuar");
        return false;
      }

      /* validando recomendaciones */
      var grade_chk = $(".question[q_type='grade'] input[type=radio]:checked");

      if(grade_chk.length!=1){
        alert("Debe elegir una opción de recomendaciones para continuar");
        return false;
      }

      /* validando texto */
      grade_1   = $("#grade_1:checked")
      textareas = $(".text_area_a")
      t_tareas  = 0

      $.each(textareas,function(index,value){
        if($(value).val()==""){
          t_tareas = t_tareas + 1
        } 
      });
      
      if(grade_1.length>0){
        if(t_tareas>0){
          alert("Si eligió con recomendaciones no puede dejar el campo vacío")
          return false;
        }
      }
      
      $("#protocol-save").attr("disabled","disabled");
      $("#protocol-send").attr("disabled","disabled");
      $("#img_load").css("display","inline-block");
      $("#messages").html("");
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
      //$("#protocol-send").attr("disabled","disabled");
      //$("#protocol-send").removeAttr("disabled","disabled");
      $("#img_load").css("display","inline-block");
    })
    .live("ajax:error", function(evt, xhr, status, error) {
      var res    = $.parseJSON(xhr.responseText);
      var ignore = 0

      for (e in res['errors']){
        if(e=='id')
        {
          ignore = ignore + 1
        }
      }

      if(ignore==0){
        $("#messages").html(res['flash']['error']);
      }
    })
    .live('ajax:success', function(evt, xhr, status, xhr) {
      var res   = $.parseJSON(xhr.responseText);
      var sts   = res['params']['status'];
      var grade = res['params']['grade'];
      var p_id  = res['uniq']
      $("#messages").html(res['flash']['notice']);
      $("#protocol-form :input").attr("disabled","disabled");
      if(sts==4)//recommendation
      {
        $("input[name='recom']").removeAttr("disabled","disabled");
        $("#recom-send").removeAttr("disabled","disabled");
        $(".recommendation").show();
      }

      $("#protocol_id").val(p_id);
    })
    .live('ajax:complete', function(evt, xhr, status) {
      var res   = $.parseJSON(xhr.responseText);
      var sts   = res['params']['status'];
      var grade = res['params']['grade'];
      $("#protocol_id").removeAttr("disabled","disabled");
      $('.scale').select2("disable");
      $("#img_load").css("display","none");
    })

});

function send_recomms(){
  recom       = $("input[name='recom']:checked").val();
  protocol_id = $("#protocol_id").val();
 
  if(!recom){
    alert("Debe seleccionar una opción");
    return false;
  }
  
  uri  = "/protocolo/recomm/"+protocol_id
  data = "recom="+recom

  $.ajax({
    type:  'POST',
    url:   uri,
    data:  data,
    beforeSend: function( xhr ) {
    },
    success:  function(data){
      $("input[name='recom']").attr("disabled","disabled");
      $("#recom-send").attr("disabled","disabled");
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
    complete: function(){
      
    },
  });
}
