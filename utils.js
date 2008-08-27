// ------------------------------------------------------------------------------------------------
// utils.js
// 
// Copyright (C) 2008 James Aitken <http://www.loonypandora.com>
// 
// Scrolls letters on mega-zine.co.uk, and does the javascript for date changing
// ------------------------------------------------------------------------------------------------

var currentPage = "one";	// Set the default first page
var scrollerID = 0;


function autoScroll() {
	scrollerID = setInterval("ScrollArrow('right');", 15000);
}

function changeDate() {
	dateSelector = document.getElementById('date');
	window.location = "/" + dateSelector.value;
}

function ScrollPage(link) {

	lastPage = currentPage;
	currentPage = link;
	
	pageMark = "page-" + currentPage;
	document.getElementById(pageMark).className = "active";
	if (lastPage) {
		lastMark = "page-" + lastPage;
		document.getElementById(lastMark).className = "inactive";
	}
	
	theScrollbox = document.getElementById('scrollbox');
	position = getElementPos(document.getElementById(link));

	offsetPos = getElementPos(document.getElementById('one'));
	position[0] = position[0] - offsetPos[0];

	clearInterval(scrollerID);
	scrollerID = setInterval("ScrollArrow('right');", 15000);
	
	startScroll(theScrollbox, theScrollbox.scrollLeft, position[0]);
}


function ScrollArrow(direction) {
  
  var pageIDs = ['one', 'two', 'three', 'four', 'five'];
  
	for (var i = 0; i < pageIDs.length; i++) {
		if (pageIDs[i] == currentPage) {
			if (direction == "left") {
				if (i - 1 < 0) {
					gotoPage = pageIDs[pageIDs.length - 1];
				} else {
					gotoPage = pageIDs[i - 1];
				}
			} else {
				if ((i + 1) > (pageIDs.length - 1)) {
					gotoPage = pageIDs[0];
				} else {
					gotoPage = pageIDs[i + 1];
				}
			}
		}
	}
	
	ScrollPage(gotoPage);
}

var scrollanimation = {time:0, begin:0, diff:0.0, frames:0.0, element:null, timer:null};

function startScroll(elem, start, end, direction) {
	if (scrollanimation.timer != null) {
		clearInterval(scrollanimation.timer);
		scrollanimation.timer = null;
	}
	scrollanimation.time = 0;
	scrollanimation.begin = start;
	scrollanimation.diff = end - start;
	scrollanimation.frames = 25; // Animation Frames
	scrollanimation.element = elem;

	scrollanimation.timer = setInterval("scrollHorizontal();", 10);
}

function scrollHorizontal() {
	if (scrollanimation.time > scrollanimation.frames) {
		clearInterval(scrollanimation.timer);
		scrollanimation.timer = null;
	} else {
		scrollanimation.element.scrollLeft = sineInOut(scrollanimation.time, scrollanimation.begin, scrollanimation.diff, scrollanimation.frames);
		scrollanimation.time++;
	}
}

function getElementPos(elemFind) {
	var elemX = 0;
	var elemY = 0;
	do {
		elemX += elemFind.offsetLeft;
		elemY += elemFind.offsetTop;
	} while ( elemFind = elemFind.offsetParent )

	return Array(elemX, elemY);
}

// http://www.robertpenner.com/easing/
function sineInOut(t, b, d, f) {
	return -d/2 * (Math.cos(Math.PI*t/f) - 1) + b;
}
