function rateStyle(num, divID) {
	var ratingRounded = Math.floor(num);
  var starArray = document.getElementById(divID).querySelectorAll(".star-over");
  for (var i = 0; i < ratingRounded; i++) {
  	starArray[i].classList.add("star-visible");
  }
  //alert(num);
  var finalStar = Math.round((num-ratingRounded)*100);
  if (finalStar != 0) {
  starArray[ratingRounded].classList.add("star-visible");
  starArray[ratingRounded].style.width=finalStar+"%";
    }
}