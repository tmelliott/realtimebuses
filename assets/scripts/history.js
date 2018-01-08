function loadHistory () {
    // Load the URLs for the data
    var url = "https://dl.dropboxusercontent.com/s/ttdqbsp45kufiyo/history_paths.json?dl=1";

    window.data.trace = {};
    window.data.trace.svg = d3.select("#historytrace");
    window.data.trace.g = window.data.trace.svg.append("g");
    setupSVG();

    $.getJSON(url, function (data) {
        FILES = data;
        // order the data ...
        FILES.forEach(function(d) { 
            d.date = new Date(d.date); 
        });
        setInterval(loopHistory, 30000);
        loopHistory();
    });
}


function loopHistory () {
    var date = FILES[curr].date,
        url = FILES[curr].url;
    curr++;
    // download the feed, and set things ...
    protobuf.load("server/proto/gtfs-network.proto", function(err, root) {
        if (err)
              throw err;
        var f = root.lookupType("transit_network.Feed");
        var xhr = new XMLHttpRequest();
        var vp = url;
        xhr.open("GET", vp, true);
        xhr.responseType = "arraybuffer";
        xhr.onload = function(evt) {
            var m = f.decode (new Uint8Array(xhr.response));
            // window.FEED = m;
            setTrace(m);
            console.log(m);
            $("#delayDate").html(date.toDateString());
        }
        xhr.send(null);
    });
}