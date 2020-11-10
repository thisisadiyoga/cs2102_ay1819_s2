$(document).ready(function() {

    $("#startdate").flatpickr({
         enableTime: true,
         dateFormat: "Y-m-d H:i:00",
         minDate: new Date()
    });
    
    $("#enddate").flatpickr({
         enableTime: true,
         dateFormat: "Y-m-d H:i:00",
         minDate: new Date()
    });
});
    