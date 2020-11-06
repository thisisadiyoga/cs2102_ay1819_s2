$(document).ready(function() {

var availabilities = $('.availabilities-test').attr('data-test-value');
    availabilities = JSON.parse(availabilities);
var  bids = $('.bids-test').attr('data-test-value');
    bids = JSON.parse(bids);

    console.log("THERE IS A BIDS ARRAY" + bids);

 //alert(availabilities[0].start);





$(".leaveStartTimestamp").flatpickr({
     enableTime: true,
     dateFormat: "Y-m-d H:i:00",
     minDate: new Date()
});

$(".leaveEndTimestamp").flatpickr({
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
    var current_date = new Date();
    var future_date = new Date();
    future_date.setFullYear(future_date.getFullYear() + 2);
    $('.take-leave-form .leaveStartTimestamp').flatpickr({dateFormat: "Y-m-d  12:00:00", enableTime: true, defaultDate: day_start,  minDate: current_date, max_date: future_date });
    $('.take-leave-form .leaveEndTimestamp').flatpickr({dateFormat: "Y-m-d  12:00:00", enableTime: true, defaultDate: day_start,  minDate: current_date, max_date: future_date});


     $('#leavedateTimePickerModal').modal('show');

},
 eventClick: function (event) {
     $('.avail-info .availStartTimestamp')[0].textContent = new Date(event.start).toLocaleString('en-US',{timeZone:'UTC'});
      $('.avail-info .availEndTimestamp')[0].textContent = new Date(event.end).toLocaleString('en-US',{timeZone:'UTC'});
       $('#availInfoModal').modal('show');
}




 });
 });


