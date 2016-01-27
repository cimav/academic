$(document).ready(function() {
  var button_pressed=false;
  $(".dia")
    .hover( function() {
        var my_id = $(this).attr('id')
        $("#sblock_"+my_id).css("background-color","white");
        $("#sstaff_"+my_id).css("background-color","white");
      },
            function() {
        var my_id = $(this).attr('id')
        $("#sblock_"+my_id).removeAttr("style");
        $("#sstaff_"+my_id).removeAttr("style");
      }
    )
    .click(function(){
      my_id     = $(this).attr('id');
      my_status = $(this).attr('status');

      if(my_status==1){
        $d     = $("#new-enrollment-dialog");
        loadCourses(my_id,$d);
        $d.dialog("open");
        $(".ui-widget-overlay").css("position","absolute");
        $(".ui-widget-overlay").css("top","0");
      }
      else
      {
        return false;
      }
    });

  $("#nedCloseButton").click(function(){$d.dialog("close")});

  $('#nedSendButton').click(function () {
    $("#haction").val("1");
    button_pressed = $(this).attr("id");
    $("#assign-courses-form").submit();
  });

  $('#nedRefuseButton').click(function () {
    $d1     = $("#textarea-dialog");
    $d1.dialog("open");

    $("#nedCloseButton1").click(function(){
      $d1.dialog("close");
      $("#nedCloseButton").removeAttr("disabled");
      $("#nedSendButton").removeAttr("disabled");
      $("#nedRefuseButton").removeAttr("disabled");
    });

    $("#nedRefuseButton1").click(function(){
      $("#haction").val("2");
      $("#refuse_area").val($("#refuse_area_first").val());
      button_pressed = $(this).attr("id");
      $("#assign-courses-form").submit();
    });

    $(".ui-widget-overlay").css("position","absolute");
    $(".ui-widget-overlay").css("top","0");
    $("#nedCloseButton").attr("disabled","disabled");
    $("#nedSendButton").attr("disabled","disabled");
    $("#nedRefuseButton").attr("disabled","disabled");

   });

  $("#new-enrollment-dialog").dialog({
    autoOpen: false,
    width: 640,
    height: 450,
    modal:true,
    dialogClass: "no-close",
  });


  $('#assign-courses-form')
    .live("ajax:beforeSend",function(evt,xht,settings){
      if(button_pressed=='nedRefuseButton1')
      {
        var area  = $("#refuse_area").val();
        text = area.replace(/ /g,'')
        if(!text)
        {
          alert("Debe capturar una razón");
          $("#refuse_area").focus();
          return false;
        }
      }
    })
    .live("ajax:error", function(data, status) {
      console.log(data);
      console.log(status);
    })
    .live('ajax:success', function(evt, data, status, xhr) {
      var res  = $.parseJSON(xhr.responseText);
      var errs = res['errors']
      if(errs.length==0){
        // TODO OK :3
        $("#textarea-dialog").dialog("close");
        $("#new-enrollment-dialog").dialog("close");
        if(res.response==2)
        {
          $('#img_fail_'+res['s_id']).css("display","none");
          $('#text_'+res['s_id']).html("[Esperando Materias]");
          $('#'+res['s_id']).attr('status',0);
        }else{
          $('#img_fail_'+res['s_id']).css("display","none");
          $('#img_ok_'+res['s_id']).css("display","block");
          $('#text_'+res['s_id']).html("[Materias Elegidas]");
          $('#'+res['s_id']).attr('status',0);
        }
      }else{
        alert("Se presentaron los siguientes errores: "+res['message']+"("+errs+")")
      }

      /*var errs = $.map(res['errors'],function(value,index){
        return [value];
      });*/
    });

  function loadCourses(my_id,$d)
  {
    $.ajax({
      url: "/alumnos/inscripcion/materias/"+my_id,
      type: "POST",
    })
      .done(function( html ) {
        $("#courses").html(html);
      })
      .fail(function() {
        $("#courses").html("Error al traer los cursos");
      });
  }
});
