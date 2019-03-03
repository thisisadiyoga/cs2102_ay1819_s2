$(function() {
	$('#p1win').change(function() {
		if($(this).is(':checked')) {
			$('#winner').val($('#player1').val());
		}
	});
	$('#p2win').change(function() {
		if($(this).is(':checked')) {
			$('#winner').val($('#player2').val());
		}
	});
	$('#player2').bind('input propertychange', function() {
		if($('#p2win').is(':checked')) {
			$('#winner').val($('#player2').val());
		}
	});
});