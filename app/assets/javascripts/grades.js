$(document).ready(function(){
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
    )//hover
    .click(function(){
      my_id     = $(this).attr('id');
      if(my_id)
      {
        window.location.href="/calificar/avance/"+my_id
      }
    });//click

  $("#advance-grades-form")
    .bind("ajax:beforeSend",function(evt,xhr,settings){
      var comment = $('#comments').val();
      if(comment==''){
        alert("Debe escribir un comentario");
        return false;
      }

      $(this).find('input[type="submit"]').attr("disabled","disabled");
      $(this).find('input[type="text"]').attr("disabled","disabled");
      $(this).find('select').attr("disabled","disabled");
    })
    .bind("ajax:success",function(evt,data,status,xhr){
      var r = $.parseJSON(xhr.responseText)
      alert(r.flash.notice);
    })
    .bind("ajax:error",function(evt,xhr,status,error){
      var r = $.parseJSON(xhr.responseText)
      alert("Error: " + r.flash.error);
      $(this).find('input[type="submit"]').removeAttr("disabled")
    });

}); // document ready
