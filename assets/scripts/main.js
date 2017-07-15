$(document).ready(function () {
    indexBtns();
});


function indexBtns () {
    $("#displayNetwork").on("click", function(e) {
        window.location.href = "display-network.html";
    });
    $("#displayRoute").on("click", function(e) {
        window.location.href = "display-route.html";
    });
};
