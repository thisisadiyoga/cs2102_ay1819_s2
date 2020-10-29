$(document).ready(function() {

var  bids = $('.bids-test').attr('data-test-value');
    bids = JSON.parse(bids);

 //alert(availabilities[0].start);





$('#calendar').fullCalendar({
  header:{
           left: 'prev,next today',
           center: 'title',
           right: 'month,agendaWeek,agendaDay,listWeek'
         },
  defaultDate: new Date(),
  timeZone: 'UTC',
  navLinks: true,
  disableDragging: true,
  eventLimit: true,
  events: bids,
  eventRender: function(event, element){
   var sg_start = new Date(event.start);
      sg_start.setHours(sg_start.getHours() - 8);
    if(event.extendedProps.is_successful == true)
        element.css('background-color', 'green');
    else if(sg_start >= new Date())
        element.css('background-color', 'orange');
    else
         element.css('background-color', 'red');
  },
  dayClick: function (date, jsEvent, view) {
    //Manipulate display side of display time to UTC time
    //Original time is still the same
    var day_start = date.toDate();
    $('.add-availability-form .startTimestamp').flatpickr({dateFormat: "Y-m-d  12:00:00", enableTime: true, defaultDate: day_start,  minDate: new Date()});
    $('.add-availability-form .endTimestamp').flatpickr({dateFormat: "Y-m-d  12:00:00", enableTime: true, defaultDate: day_start,  minDate: new Date()});


     $('#dateTimePickerModal').modal('show');

},

 eventClick: function (event) {

    //Manipulate display side of display time to UTC time
    //Original time is still the same
    var start = new Date(event.start);
    start.setHours(start.getHours() - 8);

     $('.bids-details-modal .startTimestamp')[0].setAttribute('value', event.start);

   var end = new Date(event.end);
   end.setHours(nd.getHours() - 8);
     $('.bids-details-modal .endTimestamp')[0].setAttribute('value', event.end);

   $('.bids-details-modal .caretaker')[0].setAttribute('value', event.title);

    $('.bids-details-modal .price')[0].setAttribute('value', event.extendedProps.total_price);

$('.bids-details-modal .isPaid')[0].setAttribute('value', event.extendedProps.is_paid);

$('.bids-details-modal .ratings')[0].setAttribute('value', event.extendedProps.rating);

$('.bids-details-modal .reviews')[0].setAttribute('value', event.extendedProps.review);
     $('#updateDateTimePickerModal').modal('show');
 }
});



  });


