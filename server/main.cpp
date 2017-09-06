#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>
#include <algorithm>
#include <string>
#include <cmath>
#include <time.h>
#include <sqlite3.h>

#include "gtfs-realtime.pb.h"
#include "gtfs-network.pb.h"

std::vector<std::vector<double> > flatten (std::vector<std::vector<double> >& pts, double center[2]);
bool inpoly (double pt[2], std::vector<std::vector<double> >& shape);
std::vector<double> smooth (std::vector<uint64_t> t, std::vector<int> x);

int main () {
    GOOGLE_PROTOBUF_VERIFY_VERSION;

    system("./before");

    transit_realtime::FeedMessage feed_tu;
    transit_realtime::FeedMessage feed_vp;

    {
        std::string feed_file ("../../data/trip_updates.pb");
        std::fstream feed_in (feed_file, std::ios::in | std::ios::binary);
    	if (!feed_in) {
    		std::cerr << "file not found!\n";
    		return false;
    	} else if (!feed_tu.ParseFromIstream (&feed_in)) {
    		std::cerr << "failed to parse GTFS realtime feed!\n";
    		return false;
    	}
    }

    {
        std::string feed_file ("../../data/vehicle_locations.pb");
        std::fstream feed_in (feed_file, std::ios::in | std::ios::binary);
    	if (!feed_in) {
    		std::cerr << "file not found!\n";
    		return false;
    	} else if (!feed_vp.ParseFromIstream (&feed_in)) {
    		std::cerr << "failed to parse GTFS realtime feed!\n";
    		return false;
    	}
    }
    // We're all good!

    time_t curtime = time (NULL);
    transit_network::Feed network;
    {
        transit_network::Feed network_old;
        std::string feed_file ("../../data/networkstate.pb");
        std::fstream feed_in (feed_file, std::ios::in | std::ios::binary);
        if (!feed_in) {
            // no file... we'll just create a new one!
            // std::cerr << "file not found!\n";
        } else if (!network_old.ParseFromIstream (&feed_in)) {
            // std::cerr << "failed to parse GTFS realtime feed!\n";
        } else {
            // only keep vehicles updated with 5 minutes
            for (auto vo: network_old.vehicles ()) {
		// if vehicle updated within 5mins, keep it:
                if (curtime - vo.timestamp () > -5*60) {
                    transit_network::Vehicle* v = network.add_vehicles ();
                    v->CopyFrom (vo);
                }
            }

            // get state history
            for (auto so: network_old.history ()) {
                transit_network::State* s = network.add_history ();
                s->CopyFrom (so);
            }
        }
    }

    // first add all the positions:
    for (auto& vp: feed_vp.entity ()) {
        if (vp.has_vehicle () &&
            vp.vehicle ().has_vehicle () &&
            vp.vehicle ().vehicle ().has_id () &&
            vp.vehicle ().has_position ()) {

            std::string vid (vp.vehicle ().vehicle ().id ());
            int vi;
            bool matched = false;
            for (int i=0; i<network.vehicles_size (); i++) {
                if (vid == network.vehicles (i).id ()) {
                    matched = true;
                    vi = i;
                    break;
                }
            }

            transit_network::Vehicle* v;
            if (matched) {
                v = network.mutable_vehicles (vi);
            } else {
                v = network.add_vehicles ();
                v->set_id (vid);
            }
            v->set_timestamp (vp.vehicle ().timestamp ());

            // transit_network::Vehicle* v = network.add_vehicles ();
            // v->set_id (vp.vehicle ().vehicle ().id ());
            transit_network::Position* p = v->mutable_pos ();
            p->set_lat (vp.vehicle ().position ().latitude ());
            p->set_lng (vp.vehicle ().position ().longitude ());

        }
    }

    // now go through delays and modify or append
    int regions[5] = {0};
    for (auto& tu: feed_tu.entity ()) {
        if (tu.has_trip_update () &&
            tu.trip_update ().has_vehicle () &&
            tu.trip_update ().vehicle ().has_id () &&
            tu.trip_update ().stop_time_update_size () > 0) {

            std::string vid (tu.trip_update ().vehicle ().id ());
            int vi;
            bool matched = false;
            for (int i=0; i<network.vehicles_size (); i++) {
                if (vid == network.vehicles (i).id ()) {
                    matched = true;
                    vi = i;
                    break;
                }
            }

            transit_network::Vehicle* v;
            if (matched) {
                v = network.mutable_vehicles (vi);
            } else {
                v = network.add_vehicles ();
                v->set_id (vid);
                v->set_timestamp (tu.trip_update ().timestamp ());
            }

            if (tu.trip_update ().stop_time_update (0).has_arrival () &&
                tu.trip_update ().stop_time_update (0).arrival ().has_delay ()) {
                v->set_delay (tu.trip_update ().stop_time_update (0).arrival ().delay ());
                v->set_type (transit_network::Vehicle::ARRIVAL);
            } else if (tu.trip_update ().stop_time_update (0).has_departure () &&
                       tu.trip_update ().stop_time_update (0).departure ().has_delay ()) {
                v->set_delay (tu.trip_update ().stop_time_update (0).departure ().delay ());
                v->set_type (transit_network::Vehicle::DEPARTURE);
            }

            // append to relevant region
        }
    }



    transit_network::Status* nw = network.mutable_status ();
    // std::cout << "Processing " << network.vehicles_size () << " buses:";

    int tbl[8] = {0};

    for (auto& v: network.vehicles ()) {
        if (v.has_delay ()) {
            if (v.delay () < -5*60) {
                tbl[0] += 1;
            } else if (v.delay () < -60) {
                tbl[1] += 1;
            } else if (v.delay () < 5*60) {
                tbl[2] += 1;
            } else if (v.delay () < 10*60) {
                tbl[3] += 1;
            } else if (v.delay () < 20*60) {
                tbl[4] += 1;
            } else if (v.delay () < 30*60) {
                tbl[5] += 1;
            } else {
                tbl[6] += 1;
            }
        } else {
            tbl[7] += 1;
        }
    }

    nw->set_earlier (tbl[0]);
    nw->set_early (tbl[1]);
    nw->set_ontime (tbl[2]);
    nw->set_late (tbl[3]);
    nw->set_later (tbl[4]);
    nw->set_quitelate (tbl[5]);
    nw->set_verylate (tbl[6]);
    nw->set_missing (tbl[7]);

    int N = network.vehicles_size () - tbl[7];
    transit_network::State* s = network.add_history ();
    s->set_timestamp (curtime);
    s->set_earlier (round (100 * tbl[0] / N));
    s->set_early (round (100 * tbl[1] / N));
    s->set_ontime (round (100 * tbl[2] / N));
    s->set_late (round (100 * tbl[3] / N));
    s->set_later (round (100 * tbl[4] / N));
    s->set_quitelate (round (100 * tbl[5] / N));
    s->set_verylate (round (100 * tbl[6] / N));

    // smoothed history
    std::vector<uint64_t> Zt;
    std::vector<int> Zx, Zx2, Zx3, Zx4, Zx5, Zx6, Zx7;
    for (int i=0; i<network.history_size (); i++) {
        Zt.emplace_back (network.history (i).timestamp ());
        Zx.emplace_back (network.history (i).ontime ());
        Zx2.emplace_back (network.history (i).earlier ());
        Zx3.emplace_back (network.history (i).early ());
        Zx4.emplace_back (network.history (i).late ());
        Zx5.emplace_back (network.history (i).later ());
        Zx6.emplace_back (network.history (i).quitelate ());
        Zx7.emplace_back (network.history (i).verylate ());
    }
    std::vector<double> smoothed = smooth (Zt, Zx);
    std::vector<double> smoothed2 = smooth (Zt, Zx2);
    std::vector<double> smoothed3 = smooth (Zt, Zx3);
    std::vector<double> smoothed4 = smooth (Zt, Zx4);
    std::vector<double> smoothed5 = smooth (Zt, Zx5);
    std::vector<double> smoothed6 = smooth (Zt, Zx6);
    std::vector<double> smoothed7 = smooth (Zt, Zx7);
    for (int i=0; i<network.history_size (); i++) {
        transit_network::State* s = network.add_trace ();
        s->set_timestamp (Zt[i]);
        s->set_earlier (smoothed2[i]);
        s->set_early (smoothed3[i]);
        s->set_ontime (smoothed[i]);
        s->set_late (smoothed4[i]);
        s->set_later (smoothed5[i]);
        s->set_quitelate (smoothed6[i]);
        s->set_verylate (smoothed7[i]);
    }


	std::fstream output ("../../data/networkstate.pb",
						 std::ios::out | std::ios::trunc | std::ios::binary);
	if (!network.SerializeToOstream (&output)) {
		std::cerr << "\n x Failed to write ETA feed.\n";
	}
	google::protobuf::ShutdownProtobufLibrary ();

    system("./after");

    std::cout << "done.\n";

    return 0;
}


std::vector<std::vector<double> > flatten (std::vector<std::vector<double> >& pts, double center[2]) {
    std::vector<std::vector<double> > flat;
    flat.reserve (pts.size ());
    double phi0 = center[1], lam0 = center[0];

    for (unsigned i=0; i<pts.size (); i++) {
        if (pts[i][0] == lam0 && pts[i][1] == phi0) {
            flat.emplace_back (0.0, 0.0);
        } else {
            flat.emplace_back(
                (pts[i][0] - lam0) * std::cos(phi0 * M_PI / 180),
                (pts[i][1] - phi0)
            );
        }
    }
    return flat;
}


/** taken from https://github.com/substack/point-in-polygon */
bool inpoly (double pt[2], std::vector<std::vector<double> >& shape) {
    // poly is CENTERED on the point, so point always (0,0)
    double x = 0.0, y = 0.0;

    auto vs = flatten(shape, pt);

    bool inside = false;
    for (unsigned i = 0, j = vs.size () - 1; i < vs.size (); j = i++) {
        double xi = vs[i][0], yi = vs[i][1];
        double xj = vs[j][0], yj = vs[j][1];

        bool intersect = ((yi > y) != (yj > y))
            && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
        if (intersect) inside = !inside;
    }

    return inside;
}



std::vector<double> smooth (std::vector<uint64_t> t, std::vector<int> x) {
    std::vector<double> z;
    z.reserve (x.size ());

    double f = 7.5*60;
    for (unsigned i=0; i<x.size (); i++) {
        std::vector<double> wt;
        wt.reserve (x.size ());
        double wtsum = 0.0;
        for (unsigned j=0; j<x.size (); j++) {
            wt.emplace_back (exp(-pow(t[j] - t[i], 2) / (2 * pow(f, 2))));
            wtsum += wt.back ();
        }
        double xbar = 0.0;
        for (unsigned j=0; j<x.size (); j++) xbar += x[j] * wt[j] / wtsum;
        z.emplace_back(xbar);
    }

    return z;
}
