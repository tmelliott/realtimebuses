function loadHistory () {
    // Load the URLs for the data
    var url = "https://dl.dropboxusercontent.com/s/ttdqbsp45kufiyo/history_paths.json?dl=1";

    window.data.trace = {};
    window.data.trace.svg = d3.select("#historytrace");
    window.data.trace.g = window.data.trace.svg.append("g");
    setupSVG2();

    // load the rain data!
    d3.csv('https://dl.dropboxusercontent.com/s/l90iik3ksyd88a2/rain_history.csv?dl=1', function(d) {
        var dt = d.datetime.split(/\/|\s|:/),
            day = +dt[0],
            month = +dt[1],
            year = +dt[2],
            hour = +dt[3];
        return {
            date: new Date(year, month - 1, day),
            hour: hour,
            amount: +d.amount
        };
    }, function(data) {
        window.data.rain = data;
        setupRainGraph();
    });

    $.getJSON(url, function (data) {
        FILES = data;
        // order the data ...
        FILES.forEach(function(d) { 
            d.date = new Date(d.date); 
        });
        // setInterval(loopHistory, 30000);
        loopHistory();
    });
}

function setupSVG2 () {
    var margin = {top: 100, right: 20, bottom: 20, left: 20},
        ht = $("#historytrace").outerHeight() - margin.top - margin.bottom,
        wd = $("#historytrace").outerWidth();
    var xscale = d3.scaleLinear()
        .domain([5, 24]) // from 5am - midnight
        .range([40, wd-40]);
    var yscale = d3.scaleLinear()
        .domain([0, 100])
        .range([ht-60, 10]);

    // axis here
    window.data.trace.g.append("g")
        .attr("class", "axis axis-left")
        .call(d3.axisLeft(yscale).ticks(6).tickSize(-(wd-60)));
    window.data.trace.g.append("g")
        .attr("style", "transform: translateY(" + (ht-60 + margin.bottom) + "px)")
        .attr("class", "axis axis-bottom")
        .call(d3.axisBottom(xscale)
            .tickValues([6,9,12,15,18,21])
            .tickSize(-ht + 50)
            .tickFormat(function(h) {
                if (h < 12) return h + "am";
                if (h == 12) return "12noon";
                return (h - 12) + "pm";
            }));

    
    window.data.trace.g
        .attr('transform', 'translate(' + margin.right + ',' + margin.top + ')')
    window.data.trace.g.append("g")
        .append("path")
            .attr("class", "traceline");
    window.data.trace.g.append("g")
        .append("path")
            .attr("class", "traceline traceearlier");
    window.data.trace.g.append("g")
        .append("path")
            .attr("class", "traceline tracelater");
    var today = new Date();
    var start = new Date(today.getFullYear() + "-" +
        (today.getMonth()+1) + "-" + today.getDate() + " 00:00:00").getTime()/1000;
    window.data.trace.lineGen = d3.line()
        .defined(function(d) {
            return !isNaN(d.ontime);
        })
        .x(function(d) { 
            var x = new Date(d.timestamp * 1000);
            return xscale(x.getHours() + x.getMinutes() / 60 + x.getSeconds() / 60 / 60); 
        })
        .y(function(d) { return yscale(d.ontime); })
        .curve(d3.curveBasisOpen);
    window.data.trace.lineGen3 = d3.line()
        .defined(function(d) {return !isNaN(d.early) && !isNaN(d.earlier); })
        .x(function(d) { 
            var x = new Date(d.timestamp * 1000);
            return xscale(x.getHours() + x.getMinutes() / 60 + x.getSeconds() / 60 / 60);
        })
        .y(function(d) { return yscale(d.early + d.earlier); })
        .curve(d3.curveBasisOpen);
    window.data.trace.lineGen5 = d3.line()
        .defined(function(d) {
            return !isNaN(d.later) && !isNaN(d.late) &&
                !isNaN(d.quitelate) && !isNaN(d.verylate);
        })
        .x(function(d) { 
            var x = new Date(d.timestamp * 1000);
            return xscale(x.getHours() + x.getMinutes() / 60 + x.getSeconds() / 60 / 60);
        })
        .y(function(d) {
            return yscale(d.late + d.later + d.quitelate + d.verylate);
        })
        .curve(d3.curveBasisOpen);
}


function loopHistory () {
    clearTimeout(timer);
    curr++;
    if (curr < 0) curr = FILES.length - 1;
    if (curr >= FILES.length) curr = 0;

    var date = FILES[curr].date,
        url = FILES[curr].url;

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
            if (window.data.rain !== undefined) {
                setRain(date);
            }
            $("#delayDate").html(date.toDateString());
        }
        xhr.send(null);
    });

    // timer = setTimeout(loopHistory, 20000);
}

function setupRainGraph() {
    window.data.trace.g.rain = 
        d3.select('#historytrace')
            .append('g').attr('id', 'raindata');

    var wd = $("#historytrace").outerWidth();
    var x = d3.scaleLinear()
        .domain([5, 24]) // from 5am - midnight
        .range([40, wd-40]);

    var raindata = [];
    for (var i=5;i<=24;i++) raindata.push({hour: i});
    // window.data.rain = raindata;
    var raing = d3.select('#raindata');
    var raindrops = raing.selectAll('.raindrop')
        .data(raindata)
            .enter()
                .append('circle')
                .attr('class', 'raindrop')
                .attr('cx', function(d) { return x(d.hour); })
                .attr('cy', 50)
                .attr('r', 0);
}

function setRain(date) {
    console.log("Setting data for " + date);
    // filter the rain data ...
    var raindata = window.data.rain.filter(function(d) {
        return d.date.getFullYear() == date.getFullYear() &&
               d.date.getMonth() == date.getMonth() &&
               d.date.getDate() == date.getDate() &&
               d.hour >= 5;
    });

    var raing = d3.select('#raindata');
    var raindrops = raing.selectAll('.raindrop')
        .data(raindata)
            .transition().duration(1000)
            .attr('r', function(d) { return 20 * (d.amount / 2 / Math.PI); });
}