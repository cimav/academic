function start_datepicker()
{
  $.datepicker.setDefaults($.datepicker.regional["es"]);
  var config = {
    changeMonth: true,
    changeYear: true,
    dateFormat: 'yy-mm-dd',
    showButtonPanel: true,
    minDate: '-80Y',
    maxDate: '+2Y',
        };

  $( "#start_date" ).datepicker(config);
  $( "#end_date" ).datepicker(config);
}

$(document).ready(function() {
  $("#grades-form")
    .bind("ajax:beforeSend", function(evt, xhr, settings){
      $(this).find('input[type="submit"]').attr("disabled","disabled")
      $("#img-load-grades").show();
    })
    .bind("ajax:success",function(evt, data, status, xhr){
      var r = $.parseJSON(xhr.responseText);
      showMessage(r.flash.notice);
      $(this).find('input[type="submit"]').removeAttr("disabled")
      $("#img-load-grades").hide();
    })
    .bind("ajax:error",function(evt, xhr, status, error){
      var r = $.parseJSON(xhr.responseText);
      showMessage(r.flash.error,r.errors);
      $(this).find('input[type="submit"]').removeAttr("disabled")
      $("#img-load-grades").hide();
    });
});

