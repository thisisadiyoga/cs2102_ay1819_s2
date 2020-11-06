$(document).ready(function() {

var availabilities = $('.availabilities-test').attr('data-test-value');
    availabilities = JSON.parse(availabilities);
var  bids = $('.bids-test').attr('data-test-value');
    bids = JSON.parse(bids);








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
  eventSources: [
    {
      events: availabilities,
      color: '#A8EEC1',
    },
    {
      events: bids,
      color: '#1E90FF',

    }],

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


