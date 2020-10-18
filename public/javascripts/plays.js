
  $(document).ready(function() {

$('#calendar').fullCalendar({
  header:{
           left:   'prev,next today',
           center: 'title',
           right: 'month,agendaWeek,agendaDay,listWeek'
         }
,
  defaultDate: new Date(),
  navLinks: true,
  editable: true,
  eventLimit: true,
  events: [{
      title: 'Simple static event',
      start: '2018-11-16',
      description: 'Super cool event'
    },

  ],
  dayClick: function (date, jsEvent, view) {
    var date = moment(date);

    if (date.isValid()) {
    //Save to db
      $('#calendar').fullCalendar('renderEvent', {
        title: 'Dynamic event from date click',
        start: date,
        allDay: true
      });
    } else {
      alert('Invalid');
    }
  },
});


$("#startTimestamp").flatpickr({
     enableTime: true,
     dateFormat: "Y-m-d H:i:00"
});

$("#endTimestamp").flatpickr({
     enableTime: true,
     dateFormat: "F, d Y H:i"
});
  });


