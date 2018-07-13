$(document).ready(function(){
  $('#'+screen).addClass("active");

  if(screen=='students')
  {
    $('.table').hide();
    $('#students_switch')[0].checked= true;

    $('#students_switch').change(function(){
      if($(this).is(':checked'))
      {
        $('.card').show();
        $('.table').hide();
      }else{
        $('.card').hide();
        $('.table').show();
      }
    });


  }

  $('#myModalClick').click(function() {
    $('#myModal').modal();
  })

  $('.click-modal').click(function() {
    var full_name = $(this).parent().parent().parent().find("span.full-name").html();
    $("#spanTitle").html(full_name);
    var my_type = "A";
    var uri = '/alumno/archivos/'+$(this).attr("ts_id")+'/'+my_type;
    $.ajax({
      method: 'GET',
      url: uri,
      data: {chido: '55'}
    })
     .done(function(msg){
       $("#spanContent").html(msg);
    });
    
    
    $('#myModal').modal();
  })
});//end document ready

