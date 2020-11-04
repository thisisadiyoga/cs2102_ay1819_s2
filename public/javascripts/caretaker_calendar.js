$(document).ready(function() {

var availabilities = $('.availabilities-test').attr('data-test-value');
    availabilities = JSON.parse(availabilities);
var  bids = $('.bids-test').attr('data-test-value');
    bids = JSON.parse(bids);

    console.log("THERE IS A BIDS ARRAY" + bids);

 //alert(availabilities[0].start);





$(".startTimestamp").flatpickr({
     enableTime: true,
     dateFormat: "Y-m-d H:i:00",
     minDate: new Date()
});

$(".endTimestamp").flatpickr({
     enableTime: true,
     dateFormat: "Y-m-d H:i:00",
     minDate: new Date()
});

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
  events: availabilities,
  events: bids,
  eventColor: '#A8EEC1',
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
    var old_start = new Date(event.start);
    old_start.setHours(old_start.getHours() - 8);
    $('.update-availability-form .startTimestamp').flatpickr({dateFormat: "Y-m-d  H:i:00", enableTime: true, defaultDate: old_start,  minDate: new Date()});
    $('.update-availability-form .oldStartTimestamp')[0].setAttribute('value', event.start);
    $('.delete-availability-form .oldStartTimestamp')[0].setAttribute('value', event.start);


   var old_end = new Date(event.end);
   old_end.setHours(old_end.getHours() - 8);
    $('.update-availability-form .endTimestamp').flatpickr({dateFormat: "Y-m-d  H:i:00", enableTime: true, defaultDate: old_end,  minDate: new Date()});
     $('.update-availability-form .oldEndTimestamp')[0].setAttribute('value', event.end);
    $('.delete-availability-form .oldEndTimestamp')[0].setAttribute('value', event.end);

     $('#updateDateTimePickerModal').modal('show');
 }
});



  });


