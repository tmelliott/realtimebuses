
function indexBtns () {
    $("#displayNetwork").on("click", function(e) {
        window.location.href = "display-network.html";
    });
    $("#displayRoute").on("click", function(e) {
        window.location.href = "display-route.html";
    });
};


function networkMap () {
    var zoom = 10;
    if ($(window).height() > 800) {
        zoom = 11;
    }
    map = new L.Map("map", {
        center: [-36.845794, 174.764378],
        zoom: zoom,
        zoomControl: false
    });
    L.tileLayer('http://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="http://cartodb.com/attributions">CartoDB</a>',
        subdomains: 'abcd',
        maxZoom: 19
    }).addTo(map);


    var pts;

    function loadData () {
      protobuf.load("assets/protobuf/gtfs-realtime.proto", function(err, root) {
          if (err)
              throw err;
          var f = root.lookupType("transit_realtime.FeedMessage");

          var xhr = new XMLHttpRequest();
          var vp = "https://dl.dropboxusercontent.com/s/z1nqu2xu9nhfjbk/vehicle_locations.pb?dl=1";
          xhr.open("GET", vp, true);
          xhr.responseType = "arraybuffer";
          xhr.onload = function(evt) {
              var m = f.decode (new Uint8Array(xhr.response));
              addPositions(m.entity);
          }
          xhr.send(null);
      });
    };
    function addPositions (feed) {
    //   console.log(feed);
      var data = {
          "type": "FeatureCollection",
          "features": []
      };
      for (var i=0; i<feed.length; i++) {
        if (feed[i].vehicle) {
          if (feed[i].vehicle.position) {
            data.features.push({
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [
                  feed[i].vehicle.position.longitude,
                  feed[i].vehicle.position.latitude
                ]
              },
              "properties": {
                "delay": 0,
                "delaytype": "arrival"
              }
            });
          }
        }
        // console.log(feed[i]);
      }
    //   console.log(data);
      if (pts != undefined) pts.clearLayers();
      pts = L.geoJSON(data, {
          pointToLayer: function(feature, latlng) {
              return L.circleMarker(latlng, {
                  radius: 2,
                  fillColor: "#990000",
                  weight: 0,
                  fillOpacity: 0.8
              });
          }
      }).addTo(map);
    };

    loadData();
    setInterval(loadData, 10000);
};

function networkStatus () {
    fetchNetworkData();
    setInterval(fetchNetworkData, 10000);
};

function networkRegions () {
    var regions = [
        {"name": "West", "status": 82},
        {"name": "North", "status": 78},
        {"name": "Central", "status": 55},
        // {"name": "Isthmus", "status": 61},
        {"name": "South", "status": 55},
        // {"name": "East", "status": 42},
        {"name": "Waiheke", "status": 34},
    ];
    initRegions(regions);
    setInterval(setRegions, 10000, regions);
};

function initRegions (regions) {
    for (var i=0;i<regions.length;i++) {
        $("#networkRegions").append("<div id=\"region" + regions[i].name +
        "\" class=\"region-status stateOK\"><h1 class=\"state\"><span id=\"regionCity\">?</span>%</h1><h4 class=\"name\">" +
        regions[i].name + "</h4></div>");
    }
    setRegions(regions);
};

function setRegions(regions) {
    console.log("set");
    for (var i=0;i<regions.length;i++) {
        setTimeout(function(ri) {
            var err = Math.floor(Math.random() * 5) - 2;
            $("#region" + ri.name + " .state").removeClass("isset");
            setTimeout(function() {
                $("#networkRegions #region" + ri.name + " .state span")
                    .html(ri.status + err);
                $("#region" + ri.name)
                    .removeClass("stateOK stateModerate stateHeavy stateBad");
                if (ri.status + err < 50) {
                    $("#region" + ri.name).addClass("stateBad");
                } else if (ri.status + err < 60) {
                    $("#region" + ri.name).addClass("stateHeavy");
                } else if (ri.status + err < 80) {
                    $("#region" + ri.name).addClass("stateModerate");
                } else {
                    $("#region" + ri.name).addClass("stateOK");
                }
                $("#region" + ri.name + " .state").addClass("isset");
            }, 1000);
        }, i*100, regions[i]);
    }
};

function fetchNetworkData () {
    protobuf.load("assets/protobuf/gtfs-realtime.proto", function(err, root) {
        if (err)
            throw err;
        var f = root.lookupType("transit_realtime.FeedMessage");

        var xhr = new XMLHttpRequest();

        var tu = "https://dl.dropboxusercontent.com/s/4dodhqmz8vsi9vx/trip_updates.pb?dl=1";
        xhr.open("GET", tu, true);
        xhr.responseType = "arraybuffer";
        xhr.onload = function(evt) {
            var m = f.decode (new Uint8Array(xhr.response));
            setStatus(m.entity);
        }
        xhr.send(null);
    });
};

function setStatus (data) {
    var ontime = 0, n = 0;
    var tab = [0, 0, 0, 0, 0, 0, 0]; // [<-5, -5--1, -1-5, 5-10, 10-20, 20-30, 30+]
    for (i=0; i<data.length; i++) {
        if (data[i].tripUpdate) {
            var stu = data[i].tripUpdate.stopTimeUpdate[0];
            var del;
            if (stu.arrival) {
                del = stu.arrival.delay;
            } else if (stu.departure) {
                del = stu.departure.delay;
            }
            n++;
            if (del > -60 && del < 60*5) ontime++;

            if (del < -5*60) tab[0]++
            else if (del < -60) tab[1]++;
            else if (del < 60*5) tab[2]++;
            else if (del < 60*10) tab[3]++;
            else if (del < 60*20) tab[4]++;
            else if (del < 60*30) tab[5]++;
            else tab[6]++;
        }
    }
    $("#nwPerc").html(Math.round(ontime/n*100));
    for (i=0;i<tab.length; i++) {
        $("#deltab" + i).html(tab[i]);
    }
};


function projectPoint(x, y) {
    var point = map.latLngToLayerPoint(new L.LatLng(y, x));
    this.stream.point(point.x, point.y);
};


function loadQR() {
    setQR();
    setInterval(setQR, 1000 * 60 * 10); // reload QR-code every 10 minutes
};

function setQR() {
    $("#qrcode").html("");
    var hash = generateHash(6);
    $("#qrcode").qrcode({
        render: 'canvas',
        size: 300,
        text: 'tomelliott.co.nz/realtimebuses/choose_a_route.html?h='+hash,
        radius: 0,
        quiet: 2
    });
};

function getHash() {
    $("#hash").html(GetURLParameter("h"));
};

function GetURLParameter(sParam) {
    var sPageURL = window.location.search.substring(1);
    var sURLVariables = sPageURL.split('&');
    for (var i=0; i<sURLVariables.length; i++) {
        var sParameterName = sURLVariables[i].split('=');
        if (sParameterName[0] == sParam) {
            return sParameterName[1];
        }
    }
    return '';
}

function generateHash(len) {
    var hash = "";
    var chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    for (var i=0; i<len; i++) {
        hash += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return hash;
}
