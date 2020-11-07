$(document).ready(function() {

var  bids = $('.bids-test').attr('data-test-value');
    bids = JSON.parse(bids);

 //alert(availabilities[0].start);
//Group into a nested object extendProps so that event is rendered properly
 bids.forEach(function(bid){
     bid.extendedProps = {
    is_successful: bid.is_successful,
    is_paid: bid.is_paid,
    mode_of_transfer: bid.mode_of_transfer,
    total_price: bid.total_price,
    caretaker_username: bid.caretaker_username,
    pet_name: bid.pet_name,
    avail_start_timestamp: bid.avail_start_timestamp,
    avail_end_timestamp: bid.avail_end_timestamp,

    }

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
  events: bids,
  eventRender: function(event, element){
   var sg_start = new Date(event.start);
      sg_start.setHours(sg_start.getHours() - 8);
    if(event.extendedProps.is_successful == true)
        element.css('background-color', '#1E90FF');
    else
         element.css('background-color', '#F08080');
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
     var old_bid_start = new Date(event.start);
     old_bid_start.setHours(old_bid_start.getHours() - 8);

     var old_bid_end = new Date(event.end);
       old_bid_end.setHours(old_bid_end.getHours() - 8);

      var old_avail_start = new Date(event.extendedProps.avail_start_timestamp);
         old_avail_start.setHours(old_avail_start.getHours() - 8);

         var old_avail_end = new Date(event.extendedProps.avail_end_timestamp);
           old_avail_end.setHours(old_avail_end.getHours() - 8);

     $('.bid-info .bidStartTimestamp')[0].textContent = new Date(event.start).toLocaleString('en-US',{timeZone:'UTC'});
               $('.bid-info .bidEndTimestamp')[0].textContent = new Date(event.end).toLocaleString('en-US',{timeZone:'UTC'})
               $('.bid-info .caretakerUsername')[0].textContent = event.extendedProps.caretaker_username;
               $('.bid-info .petName')[0].textContent = event.extendedProps.pet_name;
               $('.bid-info .typeOfService')[0].textContent = event.extendedProps.type_of_service;
               $('.bid-info .isPaid')[0].textContent = event.extendedProps.is_paid;
               $('.bid-info .modeOfTransfer')[0].textContent = event.extendedProps.mode_of_transfer;
               $('.bid-info .totalPrice')[0].textContent = event.extendedProps.total_price;


    if(event.extendedProps.mode_of_transfer == null)
    $('.mode-of-transfer-section').hide();
    else
    $('.mode-of-transfer-section').show();


    if(event.extendedProps.is_paid == null)
    $('.is-paid-section').hide();
    else
    $('.is-paid-section').show();

     if(event.extendedProps.type_of_service == null)
        $('.service-section').hide();
        else
        $('.service-section').show();





   //If bid expired and still pending(not successful yet)
   if(old_bid_start >= new Date() && !event.extendedProps.is_successful){

          $('.delete-bid-form .oldBidStartTimestamp')[0].setAttribute('value', event.start);
          $('.delete-bid-form .oldAvailStartTimestamp')[0].setAttribute('value', event.extendedProps.avail_start_timestamp);
          $('.delete-bid-form .oldCaretakerUsername')[0].setAttribute('value', event.extendedProps.caretaker_username);
          $('.delete-bid-form .oldPetName')[0].setAttribute('value', event.extendedProps.pet_name);



         $(".delete-bid-form .delete-button").show();
     } else {
          $(".delete-bid-form .delete-button").hide();

     }

        $('#bidInfoModal').modal('show');
 }
});



  });


