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
      $(this).find('input[type="submit"]').attr("disabled","disabled");
      $(this).find('select').attr("disabled","disabled");
    })
    .bind("ajax:success",function(evt,data,status,xhr){
      var r = $.parseJSON(xhr.responseText)
      showMessage(r.flash.notice);
    })
    .bind("ajax:error",function(evt,xhr,status,error){
      var r = $.parseJSON(xhr.responseText)
      showMessage(r.flash.error,r.errors);
      $(this).find('input[type="submit"]').removeAttr("disabled")
    });

}); // document ready
