delay = (function(){
  var timer = 0;
  return function(callback, ms){
    clearTimeout (timer);
    timer = setTimeout(callback, ms);
  };
})();

function calcFrameHeight(id) {
  iframe = document.getElementById(id);
  try
  {
    var innerDoc = (iframe.contentDocument) ? iframe.contentDocument : iframe.contentWindow.document;
    if (innerDoc.body.offsetHeight) { //ns6 syntax 
      iframe.height = innerDoc.body.offsetHeight + 32; //Extra height FireFox
    } else if (iframe.Document && iframe.Document.body.scrollHeight) { //ie5+ syntax
      iframe.height = iframe.Document.body.scrollHeight;
    }
  } catch(err) {
    alert(err.message);
  }
}

function changeResourceImage(id, small, medium) {
  if (small != $('#img-small-' + id).attr('src')) {
    $('#img-small-' + id).attr('src', small);
    $('#img-medium-' + id).attr('src', medium);
  }
}

function liveSearch() {
    $("#search-box").addClass("loading"); 
    var form = $("#live-search"); 
    var url = location.pathname + "/busqueda"; 
    var formData = form.serialize(); 
    $.get(url, formData, function(html) { 
        $("#search-box").removeClass("loading"); 
        $("#items-list").html(html); 
        $("#items-list li:first a").click();
    });
}

function showFormErrors(xhr, status, error) {
    var res,
        errorText,
        errorMs,
        errorMesg;

    try {
        res = $.parseJSON(xhr.responseText);
    } catch(err) {
        res['errors'] = { generic_error: "Error:" + err.description };
    }

    errorMesg="";
    $.each(res['errors_full'],function(key,value){
        numlist = key + 1
        errorMesg+=numlist+": "+value+"<br>";
      });
   
     
    for ( e in res['errors'] ) {
        
        errorMsg = $('<div>' + res['errors'][e] + '</div>').addClass('error-message');
        $('#field_' + model_name + '_' + e.replace('.', '_')).addClass('with-errors').append(errorMsg);
    }
    
    showFlash(res['flash']['error'], 'error', errorMesg);
}

function showFlash(msg,type,errors) {
    if (!errors){errors="";}
    $("#flash-notice").removeClass('success').removeClass('notice').removeClass('info');
    $("#flash-notice").addClass(type).html(msg +"<p>"+ errors);
    $("#flash-notice").slideDown();
    if (type != 'error') {
      $("#flash-notice").delay(1500).slideUp();
    }
}


$(document).ready(function() {

$("#flash-notice").live('click', function() {
    $(this).slideUp();
    $(this).removeClass('error').removeClass('success').removeClass('notice').removeClass('info');
});

$("#search-box")
  .live("keyup", function() {
    delay(function(){
      liveSearch();
    }, 300 );
  })
  .live("click", function() {
    if (this.value == '') {
      liveSearch();
    } 
  });


// ** Get Item **
$('.get-item')
  .live('ajax:success', function(data, status, xhr) {  
    $('.panel-list li').removeClass("selected");
    $('.panel-add').removeClass("selected");
    $(this).closest('li').addClass("selected"); 
    $('#content-panel').html(status);
    $(function() {  
      $('#resource-tabs').tabs(); 
    });

    /** Disable/enable submit button **/
    $('#content-panel form').find (':submit').attr('disabled', 'disabled').addClass('disabled');

    var form = $('#content-panel form');
    $(':input', form.get(0)).live ('change', function (e) {
        form.find (':submit').removeAttr('disabled').removeClass('disabled');
    })
  })

  .live('ajax:beforeSend', function(ev, xhr, settings) {
     $(this).closest('li').addClass("loading");
  })

  .live("ajax:error", function(data, status) {
    console.log(data);
    console.log(status);
   })

  .live('ajax:complete', function(evt, xhr, status) {
     $(this).closest('li').removeClass("loading"); 
  });

$('#add-new-item')
  .live('ajax:beforeSend', function(ev, xhr, settings) {
     $('.panel-add').addClass("selected");
     $('.panel-list li').removeClass("selected");
   })

  .live("ajax:error", function(data, status) {
    console.log(data);
    console.log(status);
   })

  .live('ajax:success', function(data, status, xhr) {  
    $('#content-panel').html(status);
    $(function() {  $('#resource-tabs').tabs(); });

    /** Disable/enable submit button **/
    $('#content-panel form').find (':submit').attr('disabled', 'disabled').addClass('disabled');

    var form = $('#content-panel form');
    $(':input', form.get(0)).live ('change', function (e) {
        form.find (':submit').removeAttr('disabled').removeClass('disabled');
    })
  }
)

$('#item-new-form')
    .live("ajax:beforeSend", function(evt, xhr, settings) {
        var $submitButton = $(this).find('input[type="submit"]');
        $submitButton.data( 'origText', $(this).text() );
        $submitButton.text( "Creando..." );
        $('.error-message').remove();
        $('.with-errors').removeClass('with-errors');
    })
    
    .live("ajax:success", function(evt, data, status, xhr) {
        // Load new
        var $form = $(this);
        var res = $.parseJSON(xhr.responseText);
        showFlash(res['flash']['notice'], 'success');
        $("#search-box").val(res['uniq']);
        initializeSearchForm();
        liveSearch();       
    })

    .live('ajax:complete', function(evt, xhr, status) {
        var $submitButton = $(this).find('input[type="submit"]');
        $submitButton.text( $(this).data('origText') );
        $submitButton.attr('disabled', 'disabled').addClass('disabled');
    })

    .live("ajax:error", function(evt, xhr, status, error) {
        showFormErrors(xhr, status, error);
    }
);
  

$('#item-edit-form')
    .live("ajax:beforeSend", function(evt, xhr, settings) {
        var $submitButton = $(this).find('input[type="submit"]');
        $submitButton.data( 'origText', $(this).text() );
        $submitButton.text( "Actualizando..." );
        $('.error-message').remove();
        $('.with-errors').removeClass('with-errors');
    })
    
    .live("ajax:success", function(evt, data, status, xhr) {
        var $form = $(this);
        var res = $.parseJSON(xhr.responseText);
        showFlash(res['flash']['notice'],'success');
    })

    .live('ajax:complete', function(evt, xhr, status) {
        var $submitButton = $(this).find('input[type="submit"]');
        $submitButton.text( $(this).data('origText') );
        $submitButton.attr('disabled', 'disabled').addClass('disabled');
    })

    .live("ajax:error", function(evt, xhr, status, error) {
        showFormErrors(xhr, status, error);
    }
);


$('#nav-select').bind('click', function(e) {
  if (!e) var e = window.event;
  // ie
  e.cancelBubble = true;
  e.returnValue = false;
  // ff / webkit
  if (e.stopPropagation) {
    e.stopPropagation();
    e.preventDefault();
  }
  $('#nav-menu').slideToggle('fast');
});

});  // READY

$('html').click(function() {
  $('#nav-menu').slideUp('fast');
});


function autoResizeIFRAME(id){
  var newheight;
  var newwidth;
  if(document.getElementById){
    newheight=document.getElementById(id).contentWindow.document.body.scrollHeight;
    newwidth=document.getElementById(id).contentWindow.document.body.scrollWidth;
  }
  document.getElementById(id).height = (newheight) + "px";
  document.getElementById(id).width = (newwidth) + "px";
}
